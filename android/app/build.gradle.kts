import java.net.URI
import java.security.MessageDigest
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kolommix.prism"
    // permission_handler_android needs API 37 (shipped as platform "android-37.0").
    compileSdk = 37
    compileSdkMinor = 0
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kolommix.prism"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing: the keystore and its passwords live OUTSIDE the
    // project (never commit them): %USERPROFILE%\.prism-signing\key.properties
    // or the file named by PRISM_KEY_PROPERTIES. Without it (e.g. a friend
    // building from source) release builds fall back to the debug key.
    val keyProps = Properties()
    val keyFile = file(
        System.getenv("PRISM_KEY_PROPERTIES")
            ?: "${System.getProperty("user.home")}/.prism-signing/key.properties"
    )
    if (keyFile.exists()) keyFile.inputStream().use<java.io.InputStream, Unit> { keyProps.load(it) }

    signingConfigs {
        if (keyProps.isNotEmpty()) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyProps.isNotEmpty()) signingConfigs.getByName("release")
            else signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Reads song names in photos and screenshots, on the phone (no internet).
    implementation("cz.adaptech.tesseract4android:tesseract4android:4.9.0")
}

// Tesseract's English + Russian reading data (tessdata_fast 4.1.0), fetched at
// build time and checked byte for byte, then shipped inside the app as assets.
abstract class FetchTessdata : DefaultTask() {
    @get:Input
    abstract val files: MapProperty<String, String>

    @get:Internal
    abstract val cacheDir: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDir: DirectoryProperty

    @TaskAction
    fun fetch() {
        val out = outputDir.get().asFile.resolve("tessdata").apply { mkdirs() }
        val cache = cacheDir.get().asFile.apply { mkdirs() }
        for ((name, sha) in files.get()) {
            val cached = cache.resolve(name)
            if (!cached.exists() || sha256(cached) != sha) {
                val url = "https://github.com/tesseract-ocr/tessdata_fast/raw/4.1.0/$name"
                val tmp = cache.resolve("$name.part")
                URI(url).toURL().openStream().use { input -> tmp.outputStream().use { input.copyTo(it) } }
                val got = sha256(tmp)
                if (got != sha) {
                    tmp.delete()
                    throw GradleException("$name: checksum $got, expected $sha")
                }
                tmp.renameTo(cached.also { it.delete() })
            }
            cached.copyTo(out.resolve(name), overwrite = true)
        }
    }

    private fun sha256(f: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        f.inputStream().use { s ->
            val buf = ByteArray(1 shl 16)
            while (true) {
                val n = s.read(buf)
                if (n < 0) break
                md.update(buf, 0, n)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }
}

val fetchTessdata = tasks.register<FetchTessdata>("fetchTessdata") {
    files.set(
        mapOf(
            "eng.traineddata" to "7d4322bd2a7749724879683fc3912cb542f19906c83bcc1a52132556427170b2",
            "rus.traineddata" to "e16e5e036cce1d9ec2b00063cf8b54472625b9e14d893a169e2b0dedeb4df225",
        ),
    )
    cacheDir.set(File(gradle.gradleUserHomeDir, "caches/prism-tessdata"))
    outputDir.set(layout.buildDirectory.dir("generated/tessdata"))
}

androidComponents {
    onVariants { variant ->
        variant.sources.assets?.addGeneratedSourceDirectory(fetchTessdata, FetchTessdata::outputDir)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
