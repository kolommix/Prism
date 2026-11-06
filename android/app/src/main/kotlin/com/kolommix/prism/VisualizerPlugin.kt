package com.kolommix.prism

import android.media.audiofx.Visualizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Real FFT of the player's own audio session (android.media.audiofx.Visualizer).
// Needs RECORD_AUDIO, which Dart asks for before calling "start".
class VisualizerPlugin(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val method = MethodChannel(messenger, "prism/visualizer")
    private val events = EventChannel(messenger, "prism/visualizer/fft")
    private var visualizer: Visualizer? = null
    private var sink: EventChannel.EventSink? = null

    init {
        method.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val session = call.argument<Int>("session")
                if (session == null) {
                    result.error("args", "no session", null)
                    return
                }
                try {
                    stop()
                    val v = Visualizer(session)
                    v.enabled = false
                    v.captureSize = 1024
                    v.setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                        override fun onWaveFormDataCapture(vis: Visualizer?, data: ByteArray?, rate: Int) {}

                        override fun onFftDataCapture(vis: Visualizer?, data: ByteArray?, rate: Int) {
                            if (data != null) sink?.success(data)
                        }
                    }, Visualizer.getMaxCaptureRate(), false, true)
                    v.enabled = true
                    visualizer = v
                    result.success(mapOf("samplingHz" to v.samplingRate / 1000))
                } catch (e: Exception) {
                    stop()
                    result.error("visualizer", e.message, null)
                }
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun stop() {
        visualizer?.let {
            it.enabled = false
            it.release()
        }
        visualizer = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun dispose() {
        stop()
        method.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }
}
