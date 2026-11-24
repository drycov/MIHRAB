package kz.mihrab.mihrab

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class PrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) render(context, manager, id)
    }
    companion object {
        private const val PREF = "mihrab_widget_v1"
        fun publish(context: Context, raw: String) {
            require(raw.length <= 65536)
            val data = JSONObject(raw)
            require(data.getInt("version") == 1 && data.getJSONArray("days").length() in 1..7)
            require(context.getSharedPreferences(PREF, Context.MODE_PRIVATE).edit().putString("snapshot",raw).commit())
            val manager = AppWidgetManager.getInstance(context)
            for (id in manager.getAppWidgetIds(ComponentName(context, PrayerWidget::class.java))) render(context,manager,id)
        }
        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val views = RemoteViews(context.packageName,R.layout.prayer_widget)
            val intent = Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(context,0,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root,pending)
            views.setTextViewText(R.id.widget_city,"MIHRAB")
            views.setTextViewText(R.id.widget_hijri,"")
            views.setTextViewText(R.id.widget_next,"Откройте приложение")
            views.setTextViewText(R.id.widget_schedule,"Обновите расписание")
            views.setTextViewText(R.id.widget_diary,"")
            try {
                val raw=context.getSharedPreferences(PREF,Context.MODE_PRIVATE).getString("snapshot",null)
                if(raw!=null){
                    val data=JSONObject(raw)
                    val zone=TimeZone.getTimeZone(data.getString("zone"))
                    val now=System.currentTimeMillis()
                    val dayFormat=SimpleDateFormat("yyyy-MM-dd",Locale.US).apply{timeZone=zone}
                    val clock=SimpleDateFormat("HH:mm",Locale.US).apply{timeZone=zone}
                    val today=dayFormat.format(Date(now))
                    val days=data.getJSONArray("days")
                    var next: String?=null
                    for(i in 0 until days.length()){
                        val day=days.getJSONObject(i)
                        val date=day.getString("date")
                        val prayers=day.getJSONArray("prayers")
                        val lines=mutableListOf<String>()
                        for(j in 0 until prayers.length()){
                            val prayer=prayers.getJSONObject(j)
                            val epoch=prayer.getLong("epoch")
                            val label=prayer.getString("name")+" "+clock.format(Date(epoch))
                            lines.add(label)
                            if(next==null && epoch>now)next=label+(if(date!=today)" · завтра" else "")
                        }
                        if(date==today){
                            views.setTextViewText(R.id.widget_city,data.getString("city")+" · "+day.getString("source"))
                            views.setTextViewText(R.id.widget_hijri,day.getString("hijri"))
                            views.setTextViewText(R.id.widget_schedule,lines.joinToString("  •  "))
                            if(day.has("completed"))views.setTextViewText(R.id.widget_diary,"Дневник: "+day.getInt("completed")+"/5")
                        }
                    }
                    views.setTextViewText(R.id.widget_next,next?.let{"Следующий: "+it}?:"Откройте приложение для обновления")
                }
            } catch (_: Exception) {
                views.setTextViewText(R.id.widget_next,"Откройте приложение для обновления")
            }
            manager.updateAppWidget(id,views)
        }
    }
}
