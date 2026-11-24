# MIHRAB

Flutter prayer companion focused on Kazakhstan. Initial MVP: offline MWL calculation, Hanafi/Shafi Asr, city time zones, next prayer countdown, date navigation and persisted preferences. Emerald/gold and light themes.

## Run

Install Flutter stable. Generate platform scaffolding (not committed yet):

```sh
flutter create --platforms=android,ios,web --org kz.mihrab --project-name mihrab .
flutter pub get
flutter analyze
flutter test
flutter run
```

The calculation is NOT an official DUMK timetable. Validate against local mosque timetables before release. Device geolocation, high-latitude policy, notifications, Qibla, translations and platform widgets are future work. No backend or registration required for this first stage.
