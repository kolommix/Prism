package com.kolommix.prism

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

// Reads the text in a picture with Tesseract, on the phone (nothing is sent
// anywhere). Same answer as the Windows bridge (windows/runner/ocr_bridge.cpp):
// "read" {path} -> {width, height, engines: [{lang, lines: [[{text, x, y, w, h}]]}]}
class OcrPlugin(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "prism/ocr")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "read") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("ocr", "no path", null)
                return@setMethodCallHandler
            }
            worker.execute {
                try {
                    val value = read(path)
                    main.post { result.success(value) }
                } catch (e: Throwable) {
                    main.post { result.error("ocr", e.message ?: e.javaClass.simpleName, null) }
                }
            }
        }
    }

    // Tesseract reads its data from files, not from the app's assets: copied
    // once into the app's own folder (the folder name changes with the data).
    private fun dataDir(): File {
        val root = File(context.noBackupFilesDir, "tesseract-4.1.0")
        val tessdata = File(root, "tessdata").apply { mkdirs() }
        for (name in LANG_FILES) {
            val target = File(tessdata, name)
            if (target.exists() && target.length() > 0) continue
            val tmp = File(tessdata, "$name.part")
            context.assets.open("tessdata/$name").use { input -> tmp.outputStream().use { input.copyTo(it) } }
            if (!tmp.renameTo(target)) throw IllegalStateException("could not save $name")
        }
        return root
    }

    private fun read(path: String): Map<String, Any> {
        val bitmap = load(path)
        val api = TessBaseAPI()
        try {
            if (!api.init(dataDir().absolutePath, "rus+eng", TessBaseAPI.OEM_LSTM_ONLY)) {
                throw IllegalStateException("tesseract init failed")
            }
            api.pageSegMode = TessBaseAPI.PageSegMode.PSM_SPARSE_TEXT
            api.setImage(bitmap)
            api.getUTF8Text() // runs the reading
            val lines = ArrayList<List<Map<String, Any>>>()
            var line = ArrayList<Map<String, Any>>()
            val it = api.resultIterator ?: return answer(bitmap, lines)
            try {
                it.begin()
                do {
                    if (it.isAtBeginningOf(TessBaseAPI.PageIteratorLevel.RIL_TEXTLINE) && line.isNotEmpty()) {
                        lines.add(line)
                        line = ArrayList()
                    }
                    val text = it.getUTF8Text(TessBaseAPI.PageIteratorLevel.RIL_WORD)?.trim()
                    val confidence = it.confidence(TessBaseAPI.PageIteratorLevel.RIL_WORD)
                    val r = it.getBoundingRect(TessBaseAPI.PageIteratorLevel.RIL_WORD)
                    if (!text.isNullOrEmpty() && confidence >= 40f) {
                        line.add(
                            mapOf(
                                "text" to text,
                                "x" to r.left.toDouble(),
                                "y" to r.top.toDouble(),
                                "w" to r.width().toDouble(),
                                "h" to r.height().toDouble(),
                            ),
                        )
                    }
                } while (it.next(TessBaseAPI.PageIteratorLevel.RIL_WORD))
                if (line.isNotEmpty()) lines.add(line)
            } finally {
                it.delete()
            }
            return answer(bitmap, lines)
        } finally {
            api.recycle()
            bitmap.recycle()
        }
    }

    private fun answer(bitmap: Bitmap, lines: List<List<Map<String, Any>>>): Map<String, Any> = mapOf(
        "width" to bitmap.width,
        "height" to bitmap.height,
        "engines" to listOf(mapOf("lang" to "rus+eng", "lines" to lines)),
    )

    // Upright (phone photos store their turn in EXIF), not huge, small
    // screenshots made bigger, and light text on dark turned into dark on
    // light: Tesseract reads that much better.
    private fun load(path: String): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw IllegalArgumentException("not a picture")
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 4000) sample *= 2
        var bmp = BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            },
        ) ?: throw IllegalArgumentException("not a picture")

        val turn = try {
            when (ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        } catch (e: Exception) {
            0f
        }
        val scale = if (maxOf(bmp.width, bmp.height) < 1200) 2f else 1f
        if (turn != 0f || scale != 1f) {
            val m = Matrix().apply {
                postScale(scale, scale)
                postRotate(turn)
            }
            val turned = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true)
            if (turned !== bmp) bmp.recycle()
            bmp = turned
        }

        if (meanLight(bmp) < 110) {
            val out = Bitmap.createBitmap(bmp.width, bmp.height, Bitmap.Config.ARGB_8888)
            val invert = ColorMatrix(
                floatArrayOf(
                    -1f, 0f, 0f, 0f, 255f,
                    0f, -1f, 0f, 0f, 255f,
                    0f, 0f, -1f, 0f, 255f,
                    0f, 0f, 0f, 1f, 0f,
                ),
            )
            Canvas(out).drawBitmap(bmp, 0f, 0f, Paint().apply { colorFilter = ColorMatrixColorFilter(invert) })
            bmp.recycle()
            bmp = out
        }
        return bmp
    }

    // Average brightness 0..255 from a grid of points.
    private fun meanLight(b: Bitmap): Int {
        var sum = 0L
        var n = 0
        val stepX = maxOf(1, b.width / 64)
        val stepY = maxOf(1, b.height / 64)
        var y = 0
        while (y < b.height) {
            var x = 0
            while (x < b.width) {
                val c = b.getPixel(x, y)
                sum += (((c shr 16) and 0xff) * 3 + ((c shr 8) and 0xff) * 6 + (c and 0xff)) / 10
                n++
                x += stepX
            }
            y += stepY
        }
        return if (n == 0) 255 else (sum / n).toInt()
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    companion object {
        private val LANG_FILES = listOf("eng.traineddata", "rus.traineddata")
    }
}
