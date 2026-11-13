package com.kolommix.prism

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import java.io.File
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity keeps the Flutter engine shared with the background
// audio service, so playback survives the activity being closed.
class MainActivity : AudioServiceActivity() {
    private var audioFx: AudioFxPlugin? = null
    private var ringtone: RingtonePlugin? = null
    private var visualizer: VisualizerPlugin? = null
    private var ocr: OcrPlugin? = null
    private var deepLink: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioFx = AudioFxPlugin(flutterEngine.dartExecutor.binaryMessenger)
        ringtone = RingtonePlugin(this, flutterEngine.dartExecutor.binaryMessenger)
        visualizer = VisualizerPlugin(flutterEngine.dartExecutor.binaryMessenger)
        ocr = OcrPlugin(this, flutterEngine.dartExecutor.binaryMessenger)
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

    // What this start brought: a link or text as a String, a file as {name, text},
    // pictures (screenshots of a playlist) as {images: [paths]}.
    // Read once per intent: it is asked for twice (start + "getInitial"), and
    // pictures would otherwise be copied twice.
    private var sharedIntent: Intent? = null
    private var sharedValue: Any? = null

    private fun shared(intent: Intent?): Any? {
        if (intent != null && intent === sharedIntent) return sharedValue
        sharedValue = readShared(intent)
        sharedIntent = intent
        return sharedValue
    }

    private fun readShared(intent: Intent?): Any? = when (intent?.action) {
        Intent.ACTION_SEND_MULTIPLE -> {
            val streams: List<Uri>? = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
            }
            streams?.let { images(it) }
        }
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
                stream != null && isImage(intent, stream) -> images(listOf(stream))
                stream != null -> readText(stream)?.let { mapOf("name" to fileName(stream), "text" to it) }
                !text.isNullOrBlank() -> text
                else -> null
            }
        }
        else -> null
    }

    private fun isImage(intent: Intent, uri: Uri): Boolean {
        val type = intent.type ?: contentResolver.getType(uri) ?: ""
        if (type.startsWith("image/")) return true
        val name = fileName(uri).lowercase()
        return IMAGE_EXTENSIONS.any { name.endsWith(".$it") }
    }

    // Shared pictures are copied into the app's cache (the share's permission
    // ends with this start), at most 20, up to 30 MB each. Day-old copies go.
    private fun images(uris: List<Uri>): Map<String, Any>? {
        val dir = File(cacheDir, "shared-images").apply { mkdirs() }
        dir.listFiles()?.forEach { if (System.currentTimeMillis() - it.lastModified() > 86_400_000L) it.delete() }
        val paths = ArrayList<String>()
        for ((i, uri) in uris.take(20).withIndex()) {
            val ext = fileName(uri).substringAfterLast('.', "png").lowercase().take(5)
            val out = File(dir, "shared-${System.currentTimeMillis()}-$i.$ext")
            try {
                contentResolver.openInputStream(uri)?.use { input ->
                    out.outputStream().use { o ->
                        val buf = ByteArray(1 shl 16)
                        var total = 0L
                        while (true) {
                            val n = input.read(buf)
                            if (n < 0) break
                            total += n
                            if (total > 30L * 1024 * 1024) throw IllegalStateException("too big")
                            o.write(buf, 0, n)
                        }
                    }
                }
                if (out.length() > 0) paths.add(out.absolutePath) else out.delete()
            } catch (e: Exception) {
                out.delete() // skip a picture that can't be read
            }
        }
        return if (paths.isEmpty()) null else mapOf("images" to paths)
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

    companion object {
        private val IMAGE_EXTENSIONS = listOf("png", "jpg", "jpeg", "webp", "bmp", "heic", "heif", "gif")
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        audioFx?.dispose()
        audioFx = null
        ringtone?.dispose()
        ringtone = null
        visualizer?.dispose()
        visualizer = null
        ocr?.dispose()
        ocr = null
        deepLink?.setMethodCallHandler(null)
        deepLink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
