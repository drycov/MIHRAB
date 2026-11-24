# MIHRAB Android release signing

Use Flutter 3.50.1 and JDK 17 as the current build baseline. Debug builds retain default debug signing. Release builds require an upload key; debug-key fallback is removed.

## Local setup (PowerShell)

If this application already has a registered upload key, reuse it. Do not create a replacement without checking Play Console.

For a new application only, from the repository root:

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android/key.properties.example android/key.properties
```

Enter the passwords interactively in keytool, then edit the ignored key.properties file locally. Never commit the key or credentials. Keep an encrypted backup outside the checkout. Paths in key.properties are relative to android/ or absolute, using forward slashes on Windows.

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build appbundle --release
flutter build apk --release
```

AAB: build/app/outputs/bundle/release/app-release.aab.
APK: build/app/outputs/flutter-apk/app-release.apk.

Verify the AAB using jarsigner -verify -verbose -certs and the APK using the installed Android SDK apksigner verify --verbose --print-certs. Compare the certificate fingerprint with the intended upload certificate. Use Play App Signing and the existing application ID kz.mihrab.mihrab. Do not publish until tests, device checks, store declarations and content licensing review pass.

CI remains debug-only for Android until signing secrets and a trusted release workflow are configured. No credentials have been generated or uploaded. Release build and task guard require verification with the actual Android toolchain.
