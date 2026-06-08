plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.saliguri.app"
    compileSdk = 36
    
    // NDK untuk ARM64 (Infinix/Tecno/MediaTek)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.saliguri.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36          // Android 14 compatible
        versionCode = flutter.versionCode().toInt()
        versionName = flutter.versionName()
        
        // Native library untuk ARM64 + ARM32
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // Fix native library sqflite tidak ke-load di Infinix
    packaging {
        jniLibs {
            useLegacyPackaging = true
            pickFirsts += listOf(
                "lib/arm64-v8a/libsqlite3.so",
                "lib/armeabi-v7a/libsqlite3.so"
            )
        }
    }
}

flutter {
    source = "../.."
}
