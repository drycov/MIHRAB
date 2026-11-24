package kz.mihrab.scheduler

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class AdhanSchedulerPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mihrab/adhan_scheduler")
        channel!!.setMethodCallHandler { call, result ->
            if (call.method != "replace") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val rows = JSONArray(call.arguments as String)
                result.success(AdhanAlarms.replace(binding.applicationContext, rows).toList())
            } catch (e: Exception) { result.error("adhan_schedule", e.message, null) }
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
