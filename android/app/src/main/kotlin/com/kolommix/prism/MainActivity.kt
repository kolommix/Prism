package com.kolommix.prism

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
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
                if (call.method == "getInitial") result.success(shared(intent)) else result.notImplemented()
            }
        }
        // The engine outlives the activity (see above): when it is already running,
        // this start's share comes here, because Dart asks for "getInitial" only once.
        shared(intent)?.let { deepLink?.invokeMethod("open", it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        shared(intent)?.let { deepLink?.invokeMethod("open", it) }
    }

    // What this start brought: a link or text as a String, a file as {name, text}.
    private fun shared(intent: Intent?): Any? = when (intent?.action) {
        Intent.ACTION_VIEW -> {
            val data = intent.data
            when {
                data == null -> null
                data.scheme == "liner" -> data.toString()
                else -> readText(data)
            }
        }
        Intent.ACTION_SEND -> {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            val stream: Uri? = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            when {
                stream != null -> readText(stream)?.let { mapOf("name" to fileName(stream), "text" to it) }
                !text.isNullOrBlank() -> text
                else -> null
            }
        }
        else -> null
    }

    // The text of a shared file, limited in size.
    private fun readText(uri: Uri): String? = try {
        contentResolver.openInputStream(uri)?.use { stream ->
            val bytes = stream.readBytes()
            if (bytes.size > 8 * 1024 * 1024) null else String(bytes, Charsets.UTF_8)
        }
    } catch (e: Exception) {
        null
    }

    // The name matters: the extension says how to read the file.
    private fun fileName(uri: Uri): String {
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) c.getString(0)?.let { return it }
            }
        } catch (e: Exception) {
            // Fall through to the path.
        }
        return uri.lastPathSegment ?: "shared.txt"
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
