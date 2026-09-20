---
kind: build_system
name: Flutter 跨平台构建与产物管理（pubspec/Gradle/Xcode）
category: build_system
scope:
    - '**'
source_files:
    - pubspec.yaml
    - pubspec.lock
    - flutter_gen.yaml
    - analysis_options.yaml
    - android/build.gradle.kts
    - android/app/build.gradle.kts
    - android/gradle.properties
    - ios/Runner.xcodeproj/project.pbxproj
---

## 1. 使用的系统与方法

本项目采用 Flutter 官方标准的多端构建体系：以 `pubspec.yaml` 为单一依赖与资源声明入口，通过 Flutter SDK 驱动 Android（Gradle Kotlin DSL）与 iOS（Xcode project）两个原生宿主工程完成编译、打包与签名。Dart 代码静态分析使用 `flutter_lints`，资源代码生成使用 `flutter_gen_runner` + `build_runner`，图标生成使用 `flutter_launcher_icons`。

## 2. 关键文件与职责

- `pubspec.yaml`：应用名、版本 `1.0.0+1`、SDK 约束 `^3.12.2`、所有 Dart 依赖与 dev_dependencies、`flutter:` 区块声明 assets（`assets/images/`、`assets/images/tabbar/`）、`flutter_gen` 集成 svg、`flutter_launcher_icons` 配置（源图 `assets/icons/appLogo1024.png`，同时输出到 android/ios）。
- `android/build.gradle.kts`：统一仓库（google/mavenCentral），并将根 build 目录重定向到项目根 `build/`，子项目构建产物也落在此处；注册 `clean` 任务删除该目录。
- `android/app/build.gradle.kts`：Android 应用模块，namespace `com.zs.zslx`，compileSdk/targetSdk 由 Flutter 插件提供，minSdk=24（Android 7.0），Java/Kotlin JVM target 均为 17；`buildTypes.release` 当前复用 debug signingConfig；通过 `flutter { source = "../.." }` 指向 Flutter 源码根。
- `android/gradle.properties`：JVM 堆 `-Xmx8G -XX:MaxMetaspaceSize=4G`，启用 AndroidX，关闭新 DSL 与内置 Kotlin。
- `flutter_gen.yaml`：指定生成输出目录 `lib/gen/`，并开启 flutter_svg 集成。
- `analysis_options.yaml`：继承 `package:flutter_lints/flutter.yaml`，仅忽略 `duplicate_import` 错误。
- `ios/Runner.xcodeproj/project.pbxproj`：标准 Xcode 工程，包含 Runner 目标与 RunnerTests 目标，引用 `Debug.xcconfig` / `Release.xcconfig` / `Generated.xcconfig` 等 Flutter 生成的配置文件。

## 3. 架构与约定

- **单源版本**：Android 的 `versionCode=1`、`versionName=1.0.0` 与 iOS 的 CFBundleShortVersionString/CFBundleVersion 均与 `pubspec.yaml` 中的 `version: 1.0.0+1` 保持一致（注释中明确说明 build-name/build-number 的映射关系）。
- **构建产物集中**：Gradle 顶层脚本将全部构建输出收敛到仓库根 `build/` 下，便于清理与 CI 缓存。
- **资源生成管线**：`flutter_gen_runner` 在 `lib/gen/` 生成类型安全的资源访问代码；`flutter_launcher_icons` 根据 `assets/icons/appLogo1024.png` 自动生成多分辨率图标并注入 Android/iOS 工程。
- **静态检查**：通过 `flutter analyze`（由 `analysis_options.yaml` 驱动）执行 lint，未引入自定义规则，仅覆盖 Flutter 官方推荐集合并忽略重复导入。
- **测试**：默认 `test/widget_test.dart` 配合 `flutter_test`，iOS 侧有 `RunnerTests.swift` 单元测试目标。

## 4. 约定与约束

- **依赖锁定**：所有第三方包版本被 `pubspec.lock` 锁定，升级需显式运行 `flutter pub upgrade --major-versions`（见 `pubspec.yaml` 注释）。
- **Android 最低版本**：`minSdk = 24` 作为硬性下限，低于 Android 7.0 的设备不可安装。
- **JDK/Kotlin 版本**：Java 与 Kotlin 编译器目标固定为 `VERSION_17` / `JVM_17`，要求构建环境 JDK ≥ 17。
- **发布签名**：`buildTypes.release.signingConfig` 当前指向 `debug`，注释提示需替换为正式签名配置；因此 release 构建目前不会做真实签名校验。
- **资源路径约束**：新增图片必须放入 `assets/images/` 或 `assets/images/tabbar/`，并在 `pubspec.yaml` 的 `flutter.assets` 中声明，否则无法被 `flutter build` 打包。
- **无外部 CI/Dockerfile**：仓库内未发现 GitHub Actions、Fastlane、Dockerfile 或自定义 shell 构建脚本；构建与发布流程依赖本地 `flutter build` 命令及 Gradle/Xcode 工具链。

## 5. 适用性判断

本仓库是典型的 Flutter 工程，具备完整的跨平台构建配置（pubspec + Gradle + Xcode）与资源/依赖/分析管线，属于“build_system”类别的高证据场景。