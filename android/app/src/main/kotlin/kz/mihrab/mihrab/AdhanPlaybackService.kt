package kz.mihrab.mihrab

import android.app.*
import android.content.Intent
import android.content.Context
import android.media.*
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import java.io.File

class AdhanPlaybackService : Service() {
    companion object {
        const val STOP = "kz.mihrab.mihrab.STOP_ADHAN"
        const val PLAY = "kz.mihrab.mihrab.PLAY_ADHAN"
        private const val CHANNEL = "mihrab_adhan_media_v1"
        private const val ID = 901
    }
    private var player: MediaPlayer? = null
    private var session: MediaSession? = null
    private var focus: AudioFocusRequest? = null
    private var legacyFocus = false
    private val audio by lazy { getSystemService(Context.AUDIO_SERVICE) as AudioManager }
    private val manager by lazy { getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager }
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change < 0) stopSelf()
    }
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action != PLAY) { stopSelf(); return START_NOT_STICKY }
        val profile = intent.getStringExtra("profile")
        if (profile != "standard" && profile != "fajr") { stopSelf(); return START_NOT_STICKY }
        releasePlayback()
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(CHANNEL, "Воспроизведение азана", NotificationManager.IMPORTANCE_LOW).apply {
                    setSound(null, null)
                })
            }
            session = MediaSession(this, "MIHRAB Adhan").apply {
                setCallback(object : MediaSession.Callback() {
                    override fun onStop() { stopSelf() }
                    override fun onPause() { stopSelf() }
                })
                setPlaybackState(PlaybackState.Builder()
                    .setActions(PlaybackState.ACTION_STOP or PlaybackState.ACTION_PAUSE)
                    .setState(PlaybackState.STATE_PLAYING, 0, 1f).build())
                isActive = true
            }
            val stop = PendingIntent.getService(this, ID, Intent(this, AdhanPlaybackService::class.java).setAction(STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
            val notification = builder.setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(if (profile == "fajr") "Азан Фаджра" else "Азан")
                .setContentText("MIHRAB · Воспроизведение")
                .setOngoing(true).setOnlyAlertOnce(true)
                .addAction(Notification.Action.Builder(android.R.drawable.ic_media_pause, "Остановить", stop).build())
                .setStyle(Notification.MediaStyle().setMediaSession(session!!.sessionToken).setShowActionsInCompactView(0))
                .build()
            startForeground(ID, notification)
            // Do not bypass DND, silent mode or muted notification volume.
            if ((Build.VERSION.SDK_INT >= 23 && manager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL) ||
                audio.ringerMode != AudioManager.RINGER_MODE_NORMAL ||
                audio.getStreamVolume(AudioManager.STREAM_NOTIFICATION) == 0 || !manager.areNotificationsEnabled()) {
                stopSelf(); return START_NOT_STICKY
            }
            val granted = if (Build.VERSION.SDK_INT >= 26) {
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(attributes).setOnAudioFocusChangeListener(focusListener).build()
                focus = request
                audio.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                legacyFocus = audio.requestAudioFocus(focusListener, AudioManager.STREAM_NOTIFICATION,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
                legacyFocus
            }
            if (!granted) { stopSelf(); return START_NOT_STICKY }
            val file = File(filesDir, "adhan_$profile.audio")
            require(file.isFile && file.canonicalFile.parentFile == filesDir.canonicalFile && file.length() in 1L..15728640L)
            val media = MediaPlayer()
            player = media
            media.setAudioAttributes(attributes)
            media.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
            media.setDataSource(file.absolutePath)
            media.setOnPreparedListener { if (player === it) it.start() }
            media.setOnCompletionListener { stopSelf() }
            media.setOnErrorListener { _, _, _ -> stopSelf(); true }
            media.prepareAsync()
        } catch (e: Exception) {
            android.util.Log.w("MIHRAB", "Adhan playback unavailable", e)
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun releasePlayback() {
        player?.release()
        player = null
        session?.release()
        session = null
        if (Build.VERSION.SDK_INT >= 26) focus?.let { audio.abandonAudioFocusRequest(it) }
        else if (legacyFocus) audio.abandonAudioFocus(focusListener)
        focus = null
        legacyFocus = false
    }

    override fun onDestroy() {
        releasePlayback()
        stopForeground(true)
        super.onDestroy()
    }
}
