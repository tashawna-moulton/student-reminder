plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ⚠️ Must match your Firebase Android app package
    namespace = "com.rayacademy.studentsreminder"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ✅ Use Java 17 (recommended with current AGP)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ⚠️ Must match `namespace` and Firebase Android app id
        applicationId = "com.rayacademy.studentsreminder"

        // ✅ Good for geolocator etc.
        minSdk = flutter.minSdkVersion
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Provide Maps key via placeholder (preferred)
        manifestPlaceholders["MAPS_API_KEY"] = "YOUR_ANDROID_MAPS_API_KEY"
        // Replace the value above with your actual Android Maps API key
    }

    buildTypes {
        release {
            // TODO: replace with your real signing config for release builds
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
