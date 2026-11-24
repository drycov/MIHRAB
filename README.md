# MIHRAB

Offline-first Flutter companion: prayer times, Qibla, Hijri calendar, Quran, Ramadan, tasbih and dua.

## Web app — Vercel (recommended)

Public URL after connect (example):

**https://mihrab.vercel.app**  
(or the project URL shown in the Vercel dashboard)

### Deploy in 2 minutes

1. Open [vercel.com](https://vercel.com) → **Add New Project** → import **drycov/MIHRAB**.
2. Framework preset: **Other** (settings are in `vercel.json`).
3. Leave **Build Command** / **Output** as in repo (`bash tool/vercel_build.sh` → `build/web`).
4. Deploy. First build installs Flutter (~3–6 min); later builds are faster if cache hits.

Root `vercel.json` already sets:

- `buildCommand`: `bash tool/vercel_build.sh`
- `outputDirectory`: `build/web`
- SPA rewrite to `index.html`
- `base-href` `/` (root domain)

Optional env in Vercel project:

| Name | Default | Meaning |
|------|---------|---------|
| `FLUTTER_VERSION` | `3.50.1` | Flutter channel/branch to clone |

### CLI (optional)

```sh
npm i -g vercel
vercel login
vercel          # preview
vercel --prod   # production
```

### Local web

```sh
flutter pub get
flutter build web --release --base-href /
flutter run -d chrome
```

## GitHub Pages (alternative)

Workflow: `.github/workflows/deploy-web.yml`  
URL: **https://drycov.github.io/MIHRAB/**  
(uses `--base-href /MIHRAB/`). Enable **Settings → Pages → Source: GitHub Actions**.

## Platform notes (web)

| Feature | Web |
|---------|-----|
| Prayer times, Hijri, calendar | Full |
| Qibla (city / GPS) | Full; compass limited |
| Quran / offline text | Full |
| Local notifications / WorkManager | Mobile only |
| Adhan file import | Limited in browser |

Calculated MWL times are not official DUMK timetables; verify with a local mosque.

## Mobile

```sh
flutter pub get
flutter run
```

## Build toolchain

CI and Vercel default to Flutter 3.50.1 (Dart 3.14.0); use the same SDK locally. This version resolved dependencies in the reported Vercel build, but successful release compilation remains a release gate. Android uses JDK 17.

## Design

UI rules: [docs/UI_GUIDE.md](docs/UI_GUIDE.md).

## Privacy and store preparation

[Privacy policy](docs/privacy-policy.md) · [Store listing draft and release gates](docs/store-metadata.md). Web deployments include `privacy.html`; verify the live HTTPS URL before submission.

Publication assets (separate from Flutter runtime): [store-assets/](store-assets/README.md).
