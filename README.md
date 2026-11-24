# MIHRAB

Offline-first Flutter prayer companion for Kazakhstan.

## v0.2.0

Riverpod state management, separated application/domain/presentation modules,
semantic theme tokens, cached daily schedules, isolated countdown updates,
persisted settings and CI for analysis, tests and web build.

## Run

Use Flutter stable (3.29 or later).

```sh
flutter create --platforms=android,ios,web --org kz.mihrab --project-name mihrab .
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Platform scaffolding is not committed yet. CI generates web scaffolding.
Calculated MWL times are not official DUMK timetables; verify locally.
Next: Qibla, geolocation, notifications, official schedule integration and localization.
