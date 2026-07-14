import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is driven by `android/key.properties` (gitignored, never committed):
// storePassword / keyPassword / keyAlias / storeFile. Present locally → the release APK is
// signed with the private NOOP release key. Absent (fresh clone, CI without the key) → the
// build cleanly falls back to debug signing so it still compiles. The keystore + this file
// live ONLY on the maintainer's machine; losing them means never being able to ship an update
// that existing installs can accept, so they must be backed up out-of-band.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "dev.chuk.noop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.chuk.noop"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sign with the private NOOP release key when key.properties is present;
            // otherwise fall back to debug so a keyless clone/CI still builds.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    // Legacy JNI packaging: store the native .so libs COMPRESSED in the APK
    // (extractNativeLibs=true) instead of uncompressed+aligned. Flutter's default
    // (false) makes the download APK carry ~21 MB of raw libs; compressing them
    // roughly halves the download — the size IzzyOnDroid/F-Droid distribution
    // cares about. Trade-off is a one-time extraction on install; acceptable for a
    // side-loaded / F-Droid app.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}
