package kz.mihrab.scheduler

import android.content.Context
import android.os.Build
import java.util.Locale

internal class AdhanStrings(context: Context) {
    // SharedPreferences legacy Flutter plugin stores string keys with flutter. prefix.
    private val saved = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        .getString("flutter.app_locale_v1", null)
    private val supported = setOf("ru","kk","ar","en")
    private val language = if (saved in supported) saved else {
        val config = context.resources.configuration
        if (Build.VERSION.SDK_INT >= 24) {
            (0 until config.locales.size()).map { config.locales[it].language }.firstOrNull { it in supported } ?: "ru"
        } else config.locale.language.takeIf { it in supported } ?: "ru"
    }
    private fun pick(ru:String,kk:String,ar:String,en:String)=when(language){
        "kk"->kk; "ar"->ar; "en"->en; else->ru
    }
    val playback=pick("Воспроизведение азана","Азанды ойнату","تشغيل الأذان","Adhan playback")
    val fajr=pick("Азан Фаджра","Таң азаны","أذان الفجر","Fajr adhan")
    val adhan=pick("Азан","Азан","الأذان","Adhan")
    val playing=pick("Воспроизведение","Ойнатылуда","قيد التشغيل","Playing")
    val stop=pick("Остановить","Тоқтату","إيقاف","Stop")
    val reminders=pick("Напоминания азана","Азан еске салғыштары","تذكيرات الأذان","Adhan reminders")
    val prayerTime=pick("Время намаза","Намаз уақыты","وقت الصلاة","Prayer time")
    val unavailable=pick("Воспроизведение азана недоступно","Азанды ойнату қолжетімсіз","تشغيل الأذان غير متاح","Adhan playback unavailable")
}
