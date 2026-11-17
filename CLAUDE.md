# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@guidelines.md

`AGENTS.md` just imports this file — edit here, not there.

## Communication Style

Must use caveman skill. Terse responses. Drop filler, articles, hedging. Fragments OK. Technical terms exact. Code unchanged.

**Prefer MCP over raw terminal** for tooling — especially **Dart/Flutter**: use the configured Dart MCP server (analysis, fixes, project queries) before defaulting to CLI-only workflows when the MCP tool covers the task.

**Prefer TDD when practical:** write or adjust failing tests first for new behavior or bug fixes, then implement until green; skip only where a test would not add signal (e.g. pure UI snapshot churn) — default bias is test-first.

- use superpowers
- **Subagent-driven development** for implementation plans with independent tasks — use `superpowers:subagent-driven-development` skill.
- dont use git commands.
- **UI/UX Excellence:** Exhibit impeccable skill in frontend design. Deliver modern, polished, and pixel-perfect layouts with exceptional attention to spacing, typography, and visual hierarchy. Design context (brand tone, color strategy, anti-references) lives in `PRODUCT.md`; the `impeccable` skill is installed in `.claude/skills/`.
- NEVER use `shrinkWrap: true` — use `ConstrainedBox(maxHeight: N)` or `Expanded`/`Flexible`
- NEVER spread `.map()` results inline in a Column — use `ListView.builder` or `GridView.builder`
- NEVER use raw `Map` in the presentation layer — wrap in typed model classes
- Prefer widget classes (`StatelessWidget`/`StatefulWidget`/`ConsumerWidget`) over widget functions or inline builders

## Commands

Flutter version pinned in `.flutter-version` (CI reads it). Package name is `subs_tracker` (imports: `package:subs_tracker/...`).

```bash
flutter pub get
dart run build_runner build -d          # codegen (also: make runnerBuild)
flutter analyze --fatal-infos --fatal-warnings   # same strictness as CI
flutter test                             # all tests
flutter test test/providers/subs_controller_test.dart          # single file
flutter test test/models/sub_slice_test.dart --plain-name "x"  # single test by name
flutter run                              # make run / make cleanRun
flutter build apk --release              # make releaseApk / debugApk / profileApk
```

CI (`.github/workflows/lint.yaml`, on push/PR to `main` and `Dev`) runs build_runner + `flutter analyze --fatal-infos --fatal-warnings`; tests are not run in CI, so run them locally. Infos fail the build.

Lint: `analysis_options.yaml` includes `analysis_options_without_plugins.yaml` and enables the `riverpod_lint` analyzer plugin — keep the plugin block (comment says lints break without it).

Release: pushing a tag `vX.Y.Z+N` triggers `flutter_build_and_release.yml` → Play Store via fastlane, using the `## [X.Y.Z+N]` section of `CHANGELOG.md` as release notes. Bump `pubspec.yaml` version and add a CHANGELOG entry in that format.

## Code Generation

This project uses `freezed`, `riverpod_generator`, and `json_serializable`. After modifying any file with `@freezed`, `@riverpod`, or `@JsonSerializable` annotations, run:

```bash
dart run build_runner build -d
```

Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis and should not be edited manually. Every provider file needs a `part 'filename.g.dart';` declaration.

## Architecture

**State management:** `hooks_riverpod` + `riverpod_generator`. Providers use `@riverpod` / `@Riverpod(keepAlive: true)` annotations. Screens use `ConsumerWidget` or `ConsumerStatefulWidget`; widgets that need hooks use `HookConsumerWidget`.

**Persistence:** `riverpod_sqflite` with `@JsonPersist()`. Each domain has its own SQLite database file:
- `subs.db` — subscription list (`SubsController`, `lib/providers/subs_controller.dart`)
- `settings.db` — user preferences (`SettingsController`)
- `brands.db` — brand catalog (`Brands`)

Each storage provider opens a `JsonSqFliteStorage` and stays alive for the app lifetime. **Never bump `destroyKey` on `subs.db`** — it deletes every user's subscriptions. Evolve `SubSlice` with defaulted/nullable fields (enums use `unknownEnumValue`) and migrate in `SubsController.build()` (e.g. it fills missing `id`s). If stored subs fail to decode, `build()` copies the raw data to `subsBackupKey` and throws instead of letting `persist()` overwrite it with an empty list; `test/providers/subs_migration_test.dart` covers this with `Storage.inMemory()`.

**Subscriptions are addressed by `id`, never list index** (`updateSlice`, `removeSlice(id)`, detail route `extra` is the id). Every mutation goes through `SubsController._set()`, which reschedules notifications and updates the home widget. `updateSlice` stamps `cancelledAt` when a sub becomes cancelled and clears it when reactivated (legacy cancelled subs keep null = unknown, no savings shown). `manageUrl` is user-entered; open it only via `safeManageUri` (`lib/utils/manage_url.dart`, http(s) only). `updateSlice` also owns `priceHistory`: it appends the old price only when `amount` changes (one entry per day; reverting the same day drops it), and ignores the caller's copy of `cancelledAt`/`priceHistory` (screens can hold stale drafts).

**Sharing, budget, manual payments:** `SubSlice.sharedWith` (read `people`) splits the cost; `inMain` already returns your share, so totals/budget/widget use it. `SettingsViewModel.monthlyBudget` is compared with the monthly total on the home card. `autoRenew: false` makes each latest charge "unpaid" until `SubsController.markPaid` adds it to `paidCharges` (`unpaidCharge`/`isOverdue` in billing.dart; `planReminders` adds an `overdue` reminder). `updateSlice` owns `paidCharges` (ignores the caller's copy) and, when `autoRenew` is switched off, marks every charge before today paid. Due-today (one-shots for manual subs) and overdue reminders carry `markPaidCharge`; the notification gets a "Paid" action (`lib/utils/mark_paid_payload.dart`) that opens the app (`showsUserInterface`, never a background isolate that would race subs.db writes), and `SubsController.build` listens to `NotificationService.markPaidRequests` (includes the tap that launched the app).

**App lock:** `lib/providers/app_lock.dart` (`appLockProvider`, `DeviceAuth` wrapping `local_auth`; override `deviceAuthProvider` in tests) and `AppLockGate` in `MaterialApp.builder`. It locks at start and after `appLockGracePeriod` in the background, never on a device without a screen lock, and only re-prompts when it actually relocked (the closing auth prompt also "resumes" the app). Requires `FlutterFragmentActivity` and AppCompat themes on Android.

**Backups:** `exportToJson` includes `mainCurrency` and `exchangeRates`; `importFromJson(restoreSettings: true)` (onboarding restore) applies them, a normal import only adds missing rates for the same main currency. CSV/.ics export lives in `lib/services/export_formats.dart`.

**Home list:** cancelled subs are shown in the Archive sheet, not the reorderable list; reorder with `SubsController.reorderWithin(visibleIds, …)` so hidden items keep their place. Categories = `builtInCategories` (`lib/models/categories.dart`) + `SettingsViewModel.customCategories`.

**Money:** `SubSlice.currency` null = follow the main currency (`SettingsViewModel.currency`). Rates in `SettingsViewModel.exchangeRates` are user-entered, never fetched (offline-first), relative to the main currency, and rebased by `SettingsController.updateCurrency` (dropped if the new main has no rate). For any total, sort, chart or widget use `settings.inMain(subs)` (`lib/models/money.dart`): converted copies plus the currencies with no rate, which are left out and surfaced on the home card. Show a single sub's amount with `settings.currencyOf(sub).symbol`. Nested JSON in persisted models (`exchangeRates`, `priceHistory`) uses tolerant converters that skip bad entries, because one decode error resets settings or blocks the subs list. Settings currency changes also push to the home widget.

**Billing dates:** `lib/models/billing.dart` (`occurrence`, `nextChargeDate`, `isDueOn`, `pastCharges`, `paymentDates`, `chargeCountBetween`, `savedSinceCancel`) is the single source of truth — charge k is start + k × `interval` periods, clamped to the month's last day so the 31st never drifts, and a charge due today is "next". Read `SubSlice.period` / `daysBefore`, never raw `interval` / `remindDaysBefore` (they guard against stored 0/negative values, which would hang the date loops; `SubsController` also repairs them on load/import). Screens, notifications and Live Activity must use it; labels come from `lib/utils/billing_labels.dart`. The Android and iOS widgets mirror it in `NextDueDateHelper.kt` (JUnit: `cd android && ./gradlew :app:testDebugUnitTest`) and `ios/SubsWidget/NextDueDateHelper.swift` (no automated test), and get `interval` in the widget JSON; keep all three in sync. The iOS Live Activity gets its due-today list from Dart.

**Routing:** `go_router` via a Riverpod provider (`goRouterProvider`). All routes are defined in `lib/config/router_config.dart` using the `Routes` enum. A `ShellRoute` wraps `RootLayout` (bottom nav + drawer) around home/calendar/analytics/settings; `/intro` sits inside the shell but its builder skips `RootLayout`. `/home` redirects to `/intro` while `settings.isFirstTime` is true. `/subscription` (detail screen) is outside the shell and takes the subscription `id` as `extra`.

**Models:** Defined with `@freezed` + `@JsonSerializable` in `lib/models/`. Key models:
- `SubSlice` — a subscription entry (name, amount, color, startDate, `Frequency`, `SubStatus`, optional brand). Use `.activeOnly` on lists when totals/widgets should ignore inactive subs; `monthlyAmount` normalizes by frequency.
- `Brand` — a service/app brand (loaded from `assets/brands.json` as defaults)
- `SettingsViewModel` — user preferences (theme, currency, profile)

**Screens:** `lib/screens/` — HomeScreen, CalendarScreen, AnalyticsScreen, SettingsScreen, OnboardingScreen, SubDetailScreen. `AppStartup` wraps HomeScreen: it waits for `settingsControllerProvider`, runs the in-app update check, and starts the iOS Live Activity if subs are due today.

**Theming:** `flex_color_scheme`-based themes defined in `lib/utils/app_theme.dart`, exposed via `lightThemeProvider`/`darkThemeProvider`. Theme mode is stored in `SettingsController` and read by `MyApp`.

**Localization:** `easy_localization` with translation files in `assets/translations/`. Supported locales: `en`, `tr`. Translation keys are accessed via `.tr()` extension. Add every new key to both `en.json` and `tr.json`.

**Notifications:** `flutter_local_notifications` + `timezone` + `flutter_timezone` (sets `tz.local` in `init()`; without it reminders fire at 12:00 UTC). `LocalNotificationService` is exposed via `notificationServiceProvider` (override with `test/helpers/fake_notification_service.dart`). `planReminders()` in `lib/utils/notification_plan.dart` is a pure function: it uses an OS repeat only when it verifies the repeat matches every reminder (checked against 48 months / 8 years of charges; never for `interval` > 1), otherwise one-shots for the next `oneShotHorizon` = 12 charges, and keeps the 64 soonest reminders (iOS limit). The plugin starts an OS repeat at the next match *from now*, ignoring the scheduled date, so a repeat is only used when the first reminder is that next match (`_osNextMatch`); a future start or `remindersSnoozedUntil` falls back to one-shots. Android reminders are exact only when `exactRemindersAllowed()` (SCHEDULE_EXACT_ALARM, granted by the user via the Settings tile, which opens the system screen through the `io.devopen.subzilla/exact_alarms` channel in `MainActivity`); otherwise inexact, because scheduling exact without it throws. Revoking it kills the app; the next start reschedules. The "due soon" reminder fires `daysBefore` days ahead at `SettingsViewModel.reminderMinutes` (default 12:00); changing that setting reschedules. `SubsController.scheduleNotifications()` cancels all and registers the plan, serialized, with localized `notifications.*` texts; it runs on every change, app start and language change. Permission is requested when onboarding finishes, and at launch only once onboarding is done (`SettingsController`).

**Native integrations (iOS):**
- Home screen widget — `home_widget` with app group `group.io.devopen.subzilla`; Dart side is `lib/services/widget_update_service.dart` (writes JSON under key `subs_data`), Swift side in `ios/SubsWidget/`.
- Live Activity — method channel `io.devopen.subzilla/live_activity` (`lib/services/live_activity_service.dart` ↔ `ios/LiveActivityChannel.swift`, `ios/LiveActivity/`). Changing the JSON shape on either service requires matching Swift changes.

**Brand icons:** `simple_icons` is overridden to a vendored copy at `packages/simple_icons` (excluded from analysis). `lib/utils/brand_utils.dart` maps brands to icons.

## Testing

Tests live in `test/` mirroring `lib/`. Controllers that persist are tested by overriding the provider with a subclass whose `build()` skips storage (see `TestSubsController` in `test/providers/subs_controller_test.dart`), and by mocking the `dexterous.com/flutter/local_notifications` method channel. Use the same pattern for new provider tests.
