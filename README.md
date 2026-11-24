# MIHRAB

Offline-first Flutter companion: prayer times, Qibla, Hijri calendar, Quran, Ramadan, tasbih and dua.

## Web app (public)

After the first successful deploy, the app is available at:

**https://drycov.github.io/MIHRAB/**

### Enable GitHub Pages (one-time)

1. Open **Settings → Pages** in this repository.
2. Under **Build and deployment → Source**, choose **GitHub Actions**.
3. Push to `main` (or run workflow **Deploy Web (GitHub Pages)** manually).

CI builds `flutter build web --release --base-href /MIHRAB/` and publishes the `build/web` artifact.

### Local web build

```sh
flutter pub get
flutter build web --release --base-href /MIHRAB/
# or root hosting:
# flutter build web --release --base-href /
```

Serve locally:

```sh
flutter run -d chrome
# or
python -m http.server 8080 --directory build/web
```

### Platform notes (web)

| Feature | Web |
|---------|-----|
| Prayer times, Hijri, calendar | Full |
| Qibla (GPS city / static azimuth) | Full; compass sensor limited |
| Quran / offline text | Full (browser storage) |
| Local notifications / WorkManager | Not available — use mobile builds |
| Adhan file import | Limited by browser file APIs |

Calculated MWL times are not official DUMK timetables; verify with a local mosque.

## Mobile

```sh
flutter pub get
flutter run
```

Use Flutter stable matching `pubspec.yaml` (`flutter: '>=3.38.0'`).

## Design

UI rules for contributors and codegen: [docs/UI_GUIDE.md](docs/UI_GUIDE.md).
