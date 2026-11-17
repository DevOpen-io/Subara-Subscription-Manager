# Changelog

All notable changes to Subara will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

* **Feat:** "Paid" button on due-today and overdue reminders of manually paid subscriptions; it opens the app and marks that payment.
* **Feat:** Exact reminder time (Android): an optional setting that lets reminders fire at the chosen minute instead of up to an hour late.
* **Fix:** Turning off "Renews automatically" no longer shows earlier payments as unpaid; charges before that day count as paid.
* **Fix:** Editing a subscription on its detail screen could undo payments marked paid in the meantime.
* **Build:** Adds the Android `SCHEDULE_EXACT_ALARM` permission. Android 14+ asks the user (Settings tile); on Android 12–13 it is usually granted at install, so reminders there become exact without asking.
* **Feat:** Snooze a subscription's reminders for a week or a month.
* **Feat:** Cancelled subscriptions move to an Archive at the bottom of the home list (search still finds them); reordering skips them.
* **Feat:** Add your own categories (and remove them) in the category picker.
* **Fix:** Repeating reminders for a subscription starting more than a cycle later (or snoozed) fired early, because the OS starts a repeat at the next matching day; those now use one-off reminders.
* **Feat:** Restore from backup during onboarding (the link used to say "coming soon"). Backups now also carry the main currency and exchange rates.
* **Feat:** Search and filter the home list by name, category, note and status.
* **Feat:** Export subscriptions as CSV, or as a calendar file (.ics) with a recurring event per subscription.
* **Feat:** Shared subscriptions: set how many people split the cost; totals, budget and the widget use your share.
* **Feat:** Monthly budget with a progress bar and an over-budget warning on the home screen.
* **Feat:** App lock with fingerprint, face or the device screen lock.
* **Feat:** Payment method per subscription (with suggestions) and a spending breakdown by payment method in Analytics.
* **Feat:** Manually paid subscriptions: turn off "Renews automatically" to mark each payment as paid; unpaid ones show as overdue and get a reminder.
* **Build:** Android `MainActivity` is now a `FlutterFragmentActivity` and the app themes use AppCompat (required by `local_auth`); adds the `USE_BIOMETRIC` permission and iOS `NSFaceIDUsageDescription`.

## [1.1.0+75] - 2026-11-17

* **Feat:** Flexible billing cycles: every 2–12 days, weeks, months or years (e.g. every 2 weeks, every 3 months). The Android and iOS home widgets follow them too.
* **Feat:** Choose how early the "due soon" reminder fires (1, 3 or 7 days before) and the reminder time of day (Settings → Notifications).
* **Feat:** Cancelling a subscription records the date, shows how much you've saved since then (detail screen and Analytics), and stops its payment history at that date.
* **Feat:** Save a manage/cancel link per subscription and open it from the detail screen. Only http(s) links are accepted.
* **Feat:** "Next 7 days" card on the home screen with the upcoming payment count and total.
* **Feat:** Per-subscription currency, chosen when adding or on the detail screen, with exchange rates you enter yourself (Settings → Exchange rates; nothing is downloaded). Totals, charts and the home widget convert to the main currency; subscriptions without a rate are listed on the home and analytics screens instead of being silently counted. Changing the main currency asks for its rate so the others can be converted.
* **Feat:** Price history: changing a subscription's price keeps the old one, the detail screen lists price changes (tap one to remove a mistaken entry), and payment history shows the price charged on each date.
* **Fix:** Reminders scheduled at app start could use 12:00 instead of the chosen time if settings loaded after subscriptions.
* **Fix:** Two subscriptions with the same name could break the home list.
* **Fix:** Starting the app on Android on a day with a due subscription logged an unhandled Live Activity error.
* **Build:** Bump Android `targetSdk` from 35 to 36 (Android 16).
* **Fix:** Fix subscription import silently failing on iPhone due to disposed widget state after drawer close.
* **Fix:** Reminders fired at 12:00 UTC instead of local noon; the device timezone is now used.
* **Fix:** Billing dates were computed differently on each screen. Monthly subscriptions from the 29th–31st drifted to the 28th, the calendar hid them in short months, and the home list showed the start date as "Renews". All now use one shared calculation, including the Android home widget.
* **Fix:** Monthly reminders on the 29th–31st and "due tomorrow" reminders for the 1st never fired in some months; they are now scheduled for the next 12 charges.
* **Fix:** Paused and cancelled subscriptions showed on the calendar and in the Live Activity.
* **Fix:** The iOS home widget computed due dates on its own and drifted month-end dates (Jan 31 -> Feb 28 -> Mar 28); it now matches the app.
* **Fix:** More than 32 subscriptions exceeded the iOS limit of 64 pending notifications; the soonest 64 are kept.
* **Fix:** Reminder texts were English only; they now follow the app language.
* **Fix:** Notification permission is asked after onboarding instead of on first launch (and still at launch for users who already finished onboarding).
* **Fix:** The calendar showed amounts in $ regardless of the chosen currency, ignored the app language, and would stop opening after 2030.
* **Fix:** Paused and cancelled subscriptions showed a renewal / next charge date on the home list and detail screen.
* **Fix:** The detail screen's back button wrapped onto two lines in Turkish.
* **Fix:** The detail screen's cost card read "per /mo" ("/ay başına" in Turkish); it now shows the billing cycle.
* **Fix:** Importing a backup or clearing data did not refresh the home widget.
* **Fix:** Daily and weekly costs used different month lengths in totals.
* **Data:** Subscriptions get a stable id (added automatically to existing data and imported backups).
* **Data:** Stored data that can't be read is now kept and backed up instead of being silently replaced by an empty list.

## [1.0.0+73] - 2026-03-11

* **Build:** Bump Flutter to 3.41.4.
* **Build:** Bump `build_runner` from 2.10.4 to 2.12.2.
* **Build:** Bump `file_picker` from 10.3.8 to 10.3.10.

## [1.0.0+68] - 2026-02-24

* **Feat:** Switch to icon-based brand logos for subscription services.
* **Feat:** Add icon field to Brand model and update brand data.
* **Build:** Update Flutter SDK to 3.41.0.
* **Build:** Update Android manifest permissions.
* **Chore:** Drop `MinimumOSVersion` from iOS `AppFrameworkInfo.plist`.

## [1.0.0+62] - 2026-01-20

* **Refactor:** Convert `build.gradle` from Groovy to Kotlin DSL.
* **Refactor:** Improve signing configuration for CI/CD and local builds.
* **Fix:** Add `isShrinkResources = false` for release build compatibility.

## [1.0.0+59] - 2026-01-13

* **Build:** Set up JDK 17 in CI/CD workflow.
* **Build:** Improve APK signing configuration in GitHub Actions.
* **Build:** Simplify APK build command in workflow.

## [1.0.0+57] - 2026-01-06

* **Fix:** Update short description in Turkish localization.

## [1.0.0+55] - 2025-12-30

* **Feat:** Add `.flutter-version` file for consistent Flutter SDK management.
* **Build:** Bump Riverpod ecosystem packages (`riverpod_sqflite`, `riverpod_generator`, `riverpod_annotation`, `flutter_riverpod`, `hooks_riverpod`).
* **Build:** Update Flutter to 3.38.5.

## [1.0.0+3] - 2025-10-15

* **Feat:** Add exact alarm permission handling.
* **Feat:** Integrate `go_router` for navigation and add `RootLayout`.
* **Refactor:** Refactor app bar actions and clean up unused providers.

## [1.0.0+2] - 2025-10-01

* **Feat:** Implement local notification system with scheduling support.
* **Feat:** Improve pie chart rendering and badge styling.
* **Build:** Configure build settings for Android and iOS.
* **Chore:** Update dependencies for notification support.

## [1.0.0+1] - 2025-09-15

* **Feat:** Initial release of Subara.
* **Feat:** Subscription tracking with local SQLite database.
* **Feat:** Visual analytics with interactive spending charts.
* **Feat:** Dark mode and custom theme support.
* **Feat:** Multi-language support (English and Turkish).
* **Feat:** Add/edit/delete subscription management.
* **Feat:** Persistent storage with Riverpod and SQLite.
