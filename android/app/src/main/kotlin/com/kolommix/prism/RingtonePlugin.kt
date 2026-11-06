package com.kolommix.prism

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Sets a file as the phone's ringtone. Android makes the user allow "modify
// system settings" for the app on a system screen; "needsPermission" says if
// that is still missing and "openPermission" opens that screen.
class RingtonePlugin(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "prism/ringtone")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "needsPermission" -> result.success(!Settings.System.canWrite(context))
            "openPermission" -> {
                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, Uri.parse("package:${context.packageName}"))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(null)
            }
            "set" -> {
                val path = call.argument<String>("path")
                val title = call.argument<String>("title") ?: "Prism"
                if (path == null) {
                    result.error("args", "no path", null)
                    return
                }
                try {
                    val uri = addToMediaStore(File(path), title)
                    RingtoneManager.setActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE, uri)
                    result.success(uri.toString())
                } catch (e: Exception) {
                    result.error("ringtone", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun addToMediaStore(file: File, title: String): Uri {
        val mime = if (file.extension.lowercase() == "mp3") "audio/mpeg" else "audio/mp4"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.TITLE, title)
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$title.${file.extension}")
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.Audio.Media.IS_RINGTONE, true)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_RINGTONES)
            } else {
                val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_RINGTONES)
                dir.mkdirs()
                val target = File(dir, "$title.${file.extension}")
                file.copyTo(target, overwrite = true)
                put(MediaStore.MediaColumns.DATA, target.absolutePath)
            }
        }
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val uri = context.contentResolver.insert(collection, values) ?: error("MediaStore refused the file")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.contentResolver.openOutputStream(uri)?.use { out -> file.inputStream().use { it.copyTo(out) } }
        }
        return uri
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
