plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.chat_v0"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.chat_v0"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val apiKey = System.getenv("GOOGLE_MAPS_API_KEY") ?: "MISSING_KEY"
        println("✅ API 키 확인: $apiKey")
        resValue("string", "google_maps_api_key", apiKey)
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.

            // ✅ 릴리즈 빌드에서도 최적화 기능 비활성화
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false // ⛔ 개발 중 임시 활성화 (배포 전엔 false로 바꿔야 함)

            // 🔽 추후 Proguard를 사용하게 될 경우 사용 (지금은 없어도 됨)
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            signingConfig = signingConfigs.getByName("debug")

        }
    }
}

flutter {
    source = "../.."
}
