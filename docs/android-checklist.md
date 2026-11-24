# Android verification
- Build: flutter pub get; flutter analyze; flutter test; flutter build apk --debug.
- Android 13+: grant notifications. Android 12+: optionally enable exact alarms in reminder settings. Denial selects inexact mode.
- Test reboot, app update, Doze, permission denial and revocation. Revoking exact alarm access can cancel existing exact alarms; reopen reminder settings and apply again.
- Verify notification icon in release builds. No custom adhan audio is bundled.
- Schedule horizon remains six days; reapply after changing city or madhab and before expiry.
- Release signing remains debug-only until a private signing configuration is provisioned. Never commit a keystore or passwords.
