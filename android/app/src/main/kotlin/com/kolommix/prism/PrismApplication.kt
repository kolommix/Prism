package com.kolommix.prism

import android.app.Application
import android.os.Build
import io.flutter.FlutterInjector

/**
 * Starts Flutter with the OpenGL ES renderer on Samsung Exynos phones.
 *
 * Their Xclipse GPU drivers crash with Flutter's Vulkan renderer on Prism's
 * moving backgrounds (seen on a Galaxy A57 when opening Backgrounds; never on
 * the emulator). OpenGL ES draws the same picture. Must run before the first
 * Flutter engine exists: the first start decides the renderer for the process.
 */
class PrismApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (!exynos()) return
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(this)
            loader.ensureInitializationComplete(this, arrayOf("--impeller-backend=opengles"))
        } catch (_: Throwable) {
            // Flutter starts as usual later.
        }
    }

    private fun exynos(): Boolean {
        val soc = if (Build.VERSION.SDK_INT >= 31) "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}" else ""
        val text = "${Build.HARDWARE} ${Build.BOARD} $soc".lowercase()
        return text.contains("exynos") || text.contains("s5e") || soc.lowercase().startsWith("samsung")
    }
}
