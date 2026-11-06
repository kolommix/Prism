package com.kolommix.prism

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.log10
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * Native audio effects for Prism ("prism/audiofx" channel).
 *
 * Each just_audio player (ExoPlayer) has its own audio session. Dart calls
 * `attach(session)` for every session and we keep one Equalizer + BassBoost +
 * LoudnessEnhancer per session, all driven by the same last-known settings.
 *
 * Methods: attach, release, setEq, setBass, setGain, measure (debug builds).
 */
class AudioFxPlugin(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private class Fx(val eq: Equalizer?, val bass: BassBoost?, val loud: LoudnessEnhancer?)

    private val channel = MethodChannel(messenger, "prism/audiofx")
    private val sessions = HashMap<Int, Fx>()

    // Last settings, re-applied to sessions attached later.
    private var eqEnabled = false
    private var levelsMb = IntArray(0)
    private var bassEnabled = false
    private var bassStrength: Short = 0
    private var gainMb = 0

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "attach" -> result.success(attach(call.argument<Int>("session")!!))
                "release" -> {
                    release(call.argument<Int>("session")!!)
                    result.success(null)
                }
                "setEq" -> {
                    eqEnabled = call.argument<Boolean>("enabled") ?: false
                    levelsMb = (call.argument<List<Int>>("levelsMb") ?: emptyList()).toIntArray()
                    sessions.values.forEach { applyEq(it) }
                    result.success(null)
                }
                "setBass" -> {
                    bassEnabled = call.argument<Boolean>("enabled") ?: false
                    bassStrength = (call.argument<Int>("strength") ?: 0).coerceIn(0, 1000).toShort()
                    sessions.values.forEach { applyBass(it) }
                    result.success(null)
                }
                "setGain" -> {
                    gainMb = call.argument<Int>("mB") ?: 0
                    sessions.values.forEach { applyGain(it) }
                    result.success(null)
                }
                "measure" -> measure(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("audiofx", e.message, null)
        }
    }

    /** Creates effects for [session] and returns the Equalizer's band layout. */
    private fun attach(session: Int): Map<String, Any> {
        sessions[session]?.let { return info(it.eq) }
        // Priority 1 so we win over a default system EQ on the same session.
        val eq = runCatching { Equalizer(1, session) }.getOrNull()
        val bass = runCatching { BassBoost(1, session) }.getOrNull()
        val loud = runCatching { LoudnessEnhancer(session) }.getOrNull()
        val fx = Fx(eq, bass, loud)
        sessions[session] = fx
        applyEq(fx)
        applyBass(fx)
        applyGain(fx)
        return info(eq)
    }

    private fun info(eq: Equalizer?): Map<String, Any> {
        if (eq == null) return mapOf("available" to false)
        val range = eq.bandLevelRange
        val freqs = (0 until eq.numberOfBands).map { eq.getCenterFreq(it.toShort()) }
        return mapOf(
            "available" to true,
            "centerFreqsMilliHz" to freqs,
            "minMb" to range[0].toInt(),
            "maxMb" to range[1].toInt(),
        )
    }

    private fun release(session: Int) {
        sessions.remove(session)?.let { fx ->
            runCatching { fx.eq?.release() }
            runCatching { fx.bass?.release() }
            runCatching { fx.loud?.release() }
        }
    }

    private fun applyEq(fx: Fx) {
        val eq = fx.eq ?: return
        runCatching {
            val n = eq.numberOfBands.toInt()
            for (i in 0 until n) {
                val level = if (i < levelsMb.size) levelsMb[i] else 0
                eq.setBandLevel(i.toShort(), level.toShort())
            }
            eq.enabled = eqEnabled
        }
    }

    private fun applyBass(fx: Fx) {
        val bass = fx.bass ?: return
        runCatching {
            if (bass.strengthSupported) bass.setStrength(bassStrength)
            bass.enabled = bassEnabled && bassStrength > 0
        }
    }

    private fun applyGain(fx: Fx) {
        val loud = fx.loud ?: return
        runCatching {
            loud.setTargetGain(gainMb)
            loud.enabled = gainMb > 0
        }
    }

    /**
     * Debug/verification: captures the session's output spectrum with a
     * Visualizer (inserted after the other effects) and returns the level in
     * dB at each requested frequency. Needs RECORD_AUDIO (debug manifest only).
     */
    private fun measure(call: MethodCall, result: MethodChannel.Result) {
        val session = call.argument<Int>("session")!!
        val freqs = call.argument<List<Double>>("freqs")!!
        val viz = Visualizer(session)
        viz.captureSize = Visualizer.getCaptureSizeRange()[1]
        viz.scalingMode = Visualizer.SCALING_MODE_AS_PLAYED
        viz.enabled = true
        val rate = viz.samplingRate / 1000.0 // mHz -> Hz
        val sums = DoubleArray(freqs.size)
        var frames = 0
        val handler = Handler(Looper.getMainLooper())
        val fft = ByteArray(viz.captureSize)
        val sample = object : Runnable {
            override fun run() {
                if (viz.getFft(fft) == Visualizer.SUCCESS) {
                    val n = fft.size
                    freqs.forEachIndexed { i, f ->
                        val k = (f * n / rate).roundToInt().coerceIn(1, n / 2 - 1)
                        val re = fft[2 * k].toDouble()
                        val im = fft[2 * k + 1].toDouble()
                        sums[i] += sqrt(re * re + im * im)
                    }
                    frames++
                }
                if (frames < 20) {
                    handler.postDelayed(this, 50)
                } else {
                    viz.enabled = false
                    viz.release()
                    result.success(sums.map { 20 * log10(it / frames + 1e-9) })
                }
            }
        }
        handler.postDelayed(sample, 300)
    }

    fun dispose() {
        sessions.keys.toList().forEach { release(it) }
        channel.setMethodCallHandler(null)
    }
}
