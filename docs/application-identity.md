# Application identity

Android applicationId and namespace: `kz.zeus.mihrab`. iOS Runner: `kz.zeus.mihrab`; extension: `kz.zeus.mihrab.PrayerWidget`; App Group: `group.kz.zeus.mihrab.widgets`. Android content provider: `content://kz.zeus.mihrab.adhan/`. The reusable scheduler plugin retains its independent namespace `kz.mihrab.scheduler`. Flutter Dart package `mihrab` remains unchanged.

Changing app identifiers creates a separate installation; existing local data, reminders, permissions and widgets are not automatically migrated. If an app is already registered in a store under the old ID, it cannot be updated under the new ID as the same listing. Register the new IDs and App Group in the appropriate developer consoles, verify signing and rebuild. No store registration or migration performed.
