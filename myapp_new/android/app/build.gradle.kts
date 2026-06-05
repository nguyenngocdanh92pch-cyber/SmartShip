plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.myapp_new"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // 🎯 1. BẬT CÔNG TẮC BỘ PHIÊN DỊCH JAVA 8 (Cú pháp chuẩn Kotlin)
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.myapp_new"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        
        // --- ĐOẠN SỬA ĐỔI NẰM Ở ĐÂY ---
        minSdk = flutter.minSdkVersion
        multiDexEnabled = true
        // ------------------------------

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Thêm thư viện hỗ trợ chia nhỏ file code cho Android
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // 🎯 2. CẤP VŨ KHÍ CHO BỘ PHIÊN DỊCH HOẠT ĐỘNG
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}