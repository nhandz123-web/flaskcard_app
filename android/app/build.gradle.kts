plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.flashcard_app" // Thay bằng package name của bạn
        minSdk = 21
        targetSdk = 33 // Có thể cập nhật lên 35 sau
        versionCode = 1
        versionName = "1.0.0"
        namespace = "com.example.flashcard_app"
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.0") // đổi sang jdk8
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
