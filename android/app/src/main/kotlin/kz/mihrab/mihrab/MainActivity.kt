package kz.mihrab.mihrab

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AdhanSchedulerPlugin())
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mihrab/adhan_media")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "play" -> {
                            val profile = call.argument<String>("profile")
                            if (profile != "standard" && profile != "fajr") {
                                result.error("invalid_profile", "Unknown recording", null)
                            } else {
                                val intent = Intent(this, AdhanPlaybackService::class.java)
                                    .setAction(AdhanPlaybackService.PLAY).putExtra("profile", profile)
                                if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
                                result.success(null)
                            }
                        }
                        "stop" -> {
                            stopService(Intent(this, AdhanPlaybackService::class.java))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) { result.error("media_start_failed", e.message, null) }
            }
    }
}
