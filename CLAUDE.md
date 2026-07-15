# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@guidelines.md

## Communication Style

Must use caveman skill. Terse responses. Drop filler, articles, hedging. Fragments OK. Technical terms exact. Code unchanged.

**Prefer MCP over raw terminal** for tooling — especially **Dart/Flutter**: use the configured Dart MCP server (analysis, fixes, project queries) before defaulting to CLI-only workflows when the MCP tool covers the task.

**Prefer TDD when practical:** write or adjust failing tests first for new behavior or bug fixes, then implement until green; skip only where a test would not add signal (e.g. pure UI snapshot churn) — default bias is test-first.

- use superpowers 
- **Subagent-driven development** for implementation plans with independent tasks — use `superpowers:subagent-driven-development` skill.
- **MCP over CLI** for Dart/Flutter tooling (analysis, fixes, project queries) when the MCP tool covers the task.
- dont use git commands.
- **UI/UX Excellence:** Exhibit impeccable skill in frontend design. Deliver modern, polished, and pixel-perfect layouts with exceptional attention to spacing, typography, and visual hierarchy.
- NEVER use `shrinkWrap: true` — use `ConstrainedBox(maxHeight: N)` or `Expanded`/`Flexible`
- NEVER spread `.map()` results inline in a Column — use `ListView.builder` or `GridView.builder`
- NEVER use raw `Map` in the presentation layer — wrap in typed model classes
- Prefer widget classes (`StatelessWidget`/`StatefulWidget`/`ConsumerWidget`) over widget functions or inline builders

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---


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
