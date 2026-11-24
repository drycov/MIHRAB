# Notification setup

Android: add POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED permissions and ScheduledNotificationReceiver / ScheduledNotificationBootReceiver manifest entries per flutter_local_notifications 19 documentation. Enable core library desugaring and required compile SDK in Android Gradle config. Scheduling uses inexact alarms; exact alarm permission is not requested.

iOS: configure notification plugin delegate according to plugin documentation. Maximum 60 scheduled reminders (6 days x 5 prayers x 2), below the typical 64 pending notification limit. Uses system sound only.

Open notification settings and Apply to schedule. Reapply after changing city or madhab and before the six-day horizon expires; automatic refresh is not implemented yet. Test on real devices before release.
