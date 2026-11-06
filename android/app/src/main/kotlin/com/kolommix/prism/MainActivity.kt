package com.kolommix.prism

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity keeps the Flutter engine shared with the background
// audio service, so playback survives the activity being closed.
class MainActivity : AudioServiceActivity() {
    private var audioFx: AudioFxPlugin? = null
    private var ringtone: RingtonePlugin? = null
    private var visualizer: VisualizerPlugin? = null
    private var deepLink: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioFx = AudioFxPlugin(flutterEngine.dartExecutor.binaryMessenger)
        ringtone = RingtonePlugin(this, flutterEngine.dartExecutor.binaryMessenger)
        visualizer = VisualizerPlugin(flutterEngine.dartExecutor.binaryMessenger)
        deepLink = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prism/deeplink").also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "getInitial") result.success(sharedText(intent)) else result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        sharedText(intent)?.let { deepLink?.invokeMethod("open", it) }
    }

    // The link itself, or the text of a .liner file (limited in size).
    private fun sharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val data: Uri = intent.data ?: return null
        if (data.scheme == "liner") return data.toString()
        return try {
            contentResolver.openInputStream(data)?.use { stream ->
                val bytes = stream.readBytes()
                if (bytes.size > 8 * 1024 * 1024) null else String(bytes, Charsets.UTF_8)
            }
        } catch (e: Exception) {
            null
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        audioFx?.dispose()
        audioFx = null
        ringtone?.dispose()
        ringtone = null
        visualizer?.dispose()
        visualizer = null
        deepLink?.setMethodCallHandler(null)
        deepLink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
