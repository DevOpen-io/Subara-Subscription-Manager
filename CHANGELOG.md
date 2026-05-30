# Changelog

All notable changes to SubZilla will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

* **Feat:** Initial release of SubZilla.
* **Feat:** Subscription tracking with local SQLite database.
* **Feat:** Visual analytics with interactive spending charts.
* **Feat:** Dark mode and custom theme support.
* **Feat:** Multi-language support (English and Turkish).
* **Feat:** Add/edit/delete subscription management.
* **Feat:** Persistent storage with Riverpod and SQLite.
