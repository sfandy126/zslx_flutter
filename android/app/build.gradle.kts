import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.zs.zslx"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion // 对应 android studio sdk manger 中sdk tools ndk version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.zs.zslx"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "channel"
    productFlavors {
        listOf(
            "xiaomi",
            "huawei",
            "oppo",
            "vivo",
            "meizu",
            "tengxun",
            "honor",
            "companywebsite",
        ).forEach { channelId ->
            create(channelId) {
                dimension = "channel"
            }
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: error("android/key.properties 缺少 keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: keystoreProperties.getProperty("storePassword")
                    ?: error("android/key.properties 缺少 keyPassword 和 storePassword")
                storeFile = file(
                    keystoreProperties.getProperty("storeFile")
                        ?: error("android/key.properties 缺少 storeFile"),
                )
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: error("android/key.properties 缺少 storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "No android/key.properties found; signing release APK with the debug key. " +
                        "Do not distribute this APK.",
                )
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true // 开启代码混淆
            isShrinkResources = true // 开启资源压缩
        }
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
