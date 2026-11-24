# MIHRAB PWA

The web manifest is scope-relative for Vercel root and GitHub Pages /MIHRAB/. Browser install UI (Chrome/Edge) or Safari Share → Add to Home Screen is used; no forced prompt. HTTPS is required except localhost.

Release builds:
```sh
flutter pub get
flutter build web --release
python3 tool/build_pwa.py build/web
python3 -m http.server 8080 --directory build/web
```

Open localhost:8080, wait for service worker installation/activation in DevTools, then verify offline reload. The generated worker caches release files only, versioned by content hash. Updates wait until old windows close; reopen the app. External APIs/audio are not cached by this worker; downloaded Quran text uses existing app storage. Browser eviction and storage quotas can remove cached data. Flutter renderer resources hosted externally may still need the network; verify cold offline launch on target browsers. No web push or background adhan added. Native app IDs and code unchanged.

Test on Vercel and Pages: manifest scope, icon, install, offline reload, Quran cache, update after closing all windows, privacy.html and no cross-project cache deletion. Browser and production tests pending.
