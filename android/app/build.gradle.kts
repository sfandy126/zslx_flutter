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

    // 百家云直播 UI 使用 Data Binding，宿主需生成聚合 DataBinderMapperImpl。
    buildFeatures {
        dataBinding = true
    }

    // 友盟 Native 崩溃采集需要将 .so 解压到安装目录。
    packaging {
        jniLibs.useLegacyPackaging = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // applicationId / app_name 由 flavorizr.yaml 生成到 flavorizr.gradle.kts 的各渠道 flavor
        minSdk = 26 //flutter.minSdkVersion // 对应android API 26 对应 android 系统版本号8.0
        targetSdk = flutter.targetSdkVersion
        // 版本号来自 flavorizr.yaml：打包时 tool/build.dart 按渠道传 --build-name/--build-number
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            val storeFileProperty = keystoreProperties.getProperty("storeFile")
            val configuredStoreFile = if (storeFileProperty.isNullOrBlank()) {
                null
            } else {
                rootProject.file(storeFileProperty)
            }

            if (configuredStoreFile?.isFile == true) {
                create("release") {
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                        ?: error("android/key.properties 缺少 keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                        ?: keystoreProperties.getProperty("storePassword")
                        ?: error("android/key.properties 缺少 keyPassword 和 storePassword")
                    storeFile = configuredStoreFile
                    storePassword = keystoreProperties.getProperty("storePassword")
                        ?: error("android/key.properties 缺少 storePassword")
                }
            } else {
                logger.warn(
                    "Android keystore not found at ${configuredStoreFile?.absolutePath ?: "the configured storeFile"}; " +
                        "release builds will use the debug signing key.",
                )
            }
        }
    }
    
    val releaseSigningConfig = signingConfigs.findByName("release")

    buildTypes {
        debug {
            // 微信开放平台按“包名 + 签名证书”识别应用。
            // Debug 也使用 key.properties 中的正式证书，避免 debug/release
            // 安装包的应用签名不同而被微信拒绝。
            signingConfig = if (releaseSigningConfig != null) {
                releaseSigningConfig
            } else {
                logger.warn(
                    "No android/key.properties found; signing debug APK with the debug key. " +
                        "微信支付/微信登录可能因应用签名不一致而失败.",
                )
                signingConfigs.getByName("debug")
            }
        }
        release {
            signingConfig = if (releaseSigningConfig != null) {
                releaseSigningConfig
            } else {
                logger.warn(
                    "No android/key.properties found; signing release APK with the debug key. " +
                        "Do not distribute this APK.",
                )
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true // 开启代码混淆
            isShrinkResources = true // 开启资源压缩
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // 百家云传递依赖的 Retrofit 2.6.0 缺少 R8 full mode 规则。
    // 对齐 core/converter/adapter，使用随 JAR 发布的官方 consumer rules。
    val retrofitVersion = "2.11.0"
    implementation("com.squareup.retrofit2:retrofit:$retrofitVersion")
    implementation("com.squareup.retrofit2:converter-gson:$retrofitVersion")
    implementation("com.squareup.retrofit2:adapter-rxjava2:$retrofitVersion")
    implementation("com.google.code.gson:gson:2.11.0")
    // OSS 图片降采样后修正 EXIF 方向，不保留 GPS 等原图元数据。
    implementation("androidx.exifinterface:exifinterface:1.4.2")
}

flutter {
    source = "../.."
}

// Flutter 的 --target-platform 不会移除依赖 SDK 自带的其他 ABI 原生库。
// 在最终打包阶段过滤，确保魅族 APK 仅保留 arm64-v8a。
androidComponents {
    onVariants(selector().withFlavor("channel" to "meizu")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(
            setOf("**/armeabi/**", "**/armeabi-v7a/**", "**/x86/**", "**/x86_64/**"),
        )
    }
}
// ----- BEGIN flavorDimensions (autogenerated by flutter_flavorizr) -----
apply { from("flavorizr.gradle.kts") }
// ----- END flavorDimensions (autogenerated by flutter_flavorizr) -----
