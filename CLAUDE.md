# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Style

Use caveman skill. Terse responses. Drop filler, articles, hedging. Fragments OK. Technical terms exact. Code unchanged.

**Prefer MCP over raw terminal** for tooling — especially **Dart/Flutter**: use the configured Dart MCP server (analysis, fixes, project queries) before defaulting to CLI-only workflows when the MCP tool covers the task.

**Prefer TDD when practical:** write or adjust failing tests first for new behavior or bug fixes, then implement until green; skip only where a test would not add signal (e.g. pure UI snapshot churn) — default bias is test-first.

- use superpowers
- **Subagent-driven development** for implementation plans with independent tasks — use `superpowers:subagent-driven-development` skill.
- **MCP over CLI** for Dart/Flutter tooling (analysis, fixes, project queries) when the MCP tool covers the task.
- dont use git commands.
- **UI/UX Excellence:** Exhibit impeccable skill in frontend design. Deliver modern, polished, and pixel-perfect layouts with exceptional attention to spacing, typography, and visual hierarchy.
- dont use git commands.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (required after modifying models/providers)
dart run build_runner build -d

# Run the app
flutter run

# Analyze for lint/type errors
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build APKs
make debugApk       # flutter build apk --debug
make releaseApk     # flutter build apk --release

# Regenerate launcher icons
make changeIcon
```

## Code Generation

This project uses `freezed`, `riverpod_generator`, and `json_serializable`. After modifying any file with `@freezed`, `@riverpod`, or `@JsonSerializable` annotations, run:

```bash
dart run build_runner build -d
```

Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis and should not be edited manually. Every provider file needs a `part 'filename.g.dart';` declaration.

## Architecture

**State management:** `hooks_riverpod` + `riverpod_generator`. Providers use `@riverpod` / `@Riverpod(keepAlive: true)` annotations. Screens use `ConsumerWidget` or `ConsumerStatefulWidget`; widgets that need hooks use `HookConsumerWidget`.

**Persistence:** `riverpod_sqflite` with `@JsonPersist()`. Each domain has its own SQLite database file:
- `subs.db` — subscription list (`SubsController`)
- `settings.db` — user preferences (`SettingsController`)
- `brands.db` — brand catalog (`Brands`)

Each storage provider opens a `JsonSqFliteStorage` and stays alive for the app lifetime. The `destroyKey` field in `StorageOptions` is used for data migrations — increment it to wipe and re-seed that store.

**Routing:** `go_router` via a Riverpod provider (`goRouterProvider`). All routes are defined in `lib/config/router_config.dart` using the `Routes` enum. The app uses a `ShellRoute` wrapping `RootLayout` (bottom nav + drawer) for all screens except `/intro`.

**Models:** Defined with `@freezed` + `@JsonSerializable` in `lib/models/`. Key models:
- `SubSlice` — a subscription entry (name, amount, color, startDate, frequency, optional brand)
- `Brand` — a service/app brand (loaded from `assets/brands.json` as defaults)
- `SettingsViewModel` — user preferences (theme, currency, profile)

**Screens:** `lib/screens/` — HomeScreen, CalendarScreen, AnalyticsScreen, SettingsScreen, OnboardingScreen. `AppStartup` is a wrapper that gates rendering until `settingsControllerProvider` resolves.

**Theming:** `flex_color_scheme`-based themes defined in `lib/utils/app_theme.dart`. Theme mode is stored in `SettingsController` and read by `MyApp`.

**Localization:** `easy_localization` with translation files in `assets/translations/`. Supported locales: `en`, `tr`. Translation keys are accessed via `.tr()` extension.

**Notifications:** `flutter_local_notifications` + `timezone`. `LocalNotificationService` is a singleton initialized in `main()`. Notifications are scheduled by `SubsController.scheduleNotification()` — all notifications are cancelled and rescheduled on any subscription change. iOS caps at 64 pending notifications; the scheduler distributes slots evenly across subscriptions.
