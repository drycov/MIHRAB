package kz.mihrab.mihrab

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            try { AdhanAlarms.restore(context) } catch (e: Exception) { Log.w("MIHRAB", "Alarm restore failed", e) }
            return
        }
        if (intent.action != AdhanAlarms.ACTION) return
        val id = intent.getIntExtra("id", -1)
        val time = intent.getLongExtra("time", 0)
        val profile = intent.getStringExtra("profile") ?: return
        if (!AdhanAlarms.consume(context, id, time, profile)) return
        val service = Intent(context, AdhanPlaybackService::class.java)
            .setAction(AdhanPlaybackService.PLAY).putExtra("profile", profile)
        try {
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(service)
            else context.startService(service)
        } catch (e: Exception) {
            Log.w("MIHRAB", "Scheduled playback unavailable", e)
            AdhanAlarms.fallback(context, id)
        }
    }
}

object AdhanAlarms {
    const val ACTION = "kz.mihrab.mihrab.ADHAN_ALARM"
    private const val KEY = "alarms"
    private const val MAX_LATE = 5 * 60 * 1000L
    private fun prefs(c: Context) = c.getSharedPreferences("mihrab_native_adhan", Context.MODE_PRIVATE)
    private fun records(c: Context) = JSONArray(prefs(c).getString(KEY, "[]") ?: "[]")
    private fun manager(c: Context) = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private fun pending(c: Context, id: Int, time: Long, profile: String, flags: Int): PendingIntent? =
        PendingIntent.getBroadcast(c, id, Intent(c, AdhanAlarmReceiver::class.java).setAction(ACTION)
            .putExtra("id", id).putExtra("time", time).putExtra("profile", profile),
            flags or PendingIntent.FLAG_IMMUTABLE)

    private fun allowed(c: Context): Boolean =
        Build.VERSION.SDK_INT < 31 || manager(c).canScheduleExactAlarms()

    private fun validFile(c: Context, profile: String): Boolean {
        if (profile != "standard" && profile != "fajr") return false
        val f = File(c.filesDir, "adhan_$profile.audio")
        return f.isFile && f.length() in 1L..15728640L
    }

    @Synchronized fun replace(c: Context, rows: JSONArray): Set<Int> {
        val old = records(c)
        val accepted = JSONArray()
        val ids = mutableSetOf<Int>()
        if (allowed(c)) {
            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                val id = row.getInt("id")
                val time = row.getLong("time")
                val profile = row.getString("profile")
                if (id !in 100000000..199999999 || time <= System.currentTimeMillis() ||
                    !validFile(c, profile) || !ids.add(id)) continue
                val pi = pending(c, id, time, profile, PendingIntent.FLAG_UPDATE_CURRENT)!!
                try {
                    manager(c).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, pi)
                    accepted.put(row)
                } catch (e: SecurityException) { ids.remove(id); pi.cancel() }
            }
        }
        for (i in 0 until old.length()) {
            val row = old.getJSONObject(i)
            val id = row.getInt("id")
            if (id !in ids) pending(c, id, 0, "", PendingIntent.FLAG_NO_CREATE)?.let {
                manager(c).cancel(it); it.cancel()
            }
        }
        check(prefs(c).edit().putString(KEY, accepted.toString()).commit())
        return ids
    }

    @Synchronized fun restore(c: Context) { replace(c, records(c)) }

    @Synchronized fun consume(c: Context, id: Int, time: Long, profile: String): Boolean {
        val old = records(c)
        val remaining = JSONArray()
        var found = false
        for (i in 0 until old.length()) {
            val row = old.getJSONObject(i)
            if (row.getInt("id") == id && row.getLong("time") == time && row.getString("profile") == profile) found = true
            else remaining.put(row)
        }
        if (!found) return false
        if (!prefs(c).edit().putString(KEY, remaining.toString()).commit()) return false
        val late = System.currentTimeMillis() - time
        return late in 0..MAX_LATE && validFile(c, profile)
    }

    fun fallback(c: Context, id: Int) {
        val nm = c.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        if (!nm.areNotificationsEnabled()) return
        val channel = "mihrab_adhan_fallback_v1"
        if (Build.VERSION.SDK_INT >= 26) nm.createNotificationChannel(android.app.NotificationChannel(
            channel, "Напоминания азана", android.app.NotificationManager.IMPORTANCE_DEFAULT))
        val builder = if (Build.VERSION.SDK_INT >= 26) android.app.Notification.Builder(c, channel)
            else android.app.Notification.Builder(c)
        nm.notify(id, builder.setSmallIcon(R.drawable.ic_notification).setContentTitle("Время намаза")
            .setContentText("Воспроизведение азана недоступно").setAutoCancel(true).build())
    }
}
