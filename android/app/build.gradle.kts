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
    ndkVersion = "27.0.12077973"

    // ✅ Use Java 17 (recommended with current AGP)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.students_reminder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
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
