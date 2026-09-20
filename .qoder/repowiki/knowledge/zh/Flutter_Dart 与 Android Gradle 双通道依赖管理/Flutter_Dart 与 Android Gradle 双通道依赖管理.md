---
kind: dependency_management
name: Flutter/Dart 与 Android Gradle 双通道依赖管理
category: dependency_management
scope:
    - '**'
source_files:
    - pubspec.yaml
    - pubspec.lock
    - android/settings.gradle.kts
    - android/build.gradle.kts
    - android/app/build.gradle.kts
    - flutter_gen.yaml
    - analysis_options.yaml
---

## 1. 使用的系统/工具

本项目采用 Flutter 工程标准的双通道依赖管理：
- **Dart/Flutter 层**：通过 `pubspec.yaml` 声明 Dart SDK 与第三方包，使用 `pub get` 解析并生成 `pubspec.lock`（锁定每个包的精确版本与 sha256），构建时由 Flutter 工具链从 `https://pub.dev` 下载。
- **Android 原生层**：通过 Gradle Kotlin DSL（`android/build.gradle.kts`、`android/settings.gradle.kts`、`android/app/build.gradle.kts`）声明 Android/Kotlin/Flutter Gradle 插件及仓库源，由 Gradle 拉取。
- **iOS 层**：作为 Flutter 宿主工程，依赖由 Flutter 工具链在 Xcode 工程中隐式处理，本仓库未单独维护 CocoaPods 清单。

## 2. 关键文件

- `pubspec.yaml`：Dart 依赖声明中心。包含 `environment.sdk: ^3.12.2`、`dependencies`（运行时依赖如 dio、provider、rxdart、flutter_platform_widgets 等）、`dev_dependencies`（build_runner、flutter_lints、flutter_gen_runner、flutter_auditor、flutter_launcher_icons）以及 `flutter:` 资源与图标配置。
- `pubspec.lock`：由 pub 生成的锁定文件，记录所有直接/传递依赖的精确版本号与 sha256，来源统一为 `hosted` + `url: https://pub.dev`。
- `android/settings.gradle.kts`：Gradle 插件与仓库源入口，声明 `google()`、`mavenCentral()`、`gradlePluginPortal()` 三个仓库，并通过 `includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")` 内联 Flutter Gradle 工具。
- `android/build.gradle.kts`：顶层 Gradle 配置，集中定义 `google()`、`mavenCentral()` 仓库，并将构建产物输出到根目录 `build/`。
- `android/app/build.gradle.kts`：应用模块配置，声明 `com.android.application` 插件、`dev.flutter.flutter-gradle-plugin`、`compileSdk/targetSdk/minSdk`、Java 17、Kotlin JVM_17 等。
- `flutter_gen.yaml`：配合 `flutter_gen_runner` 将 SVG 等资源转为 Dart 代码（`integrations.flutter_svg: true`）。
- `analysis_options.yaml`：启用 `flutter_lints` 进行静态分析。

## 3. 架构与约定

- **单一依赖入口**：Dart 侧所有第三方包集中在 `pubspec.yaml` 的 `dependencies` / `dev_dependencies` 两段；Android 侧插件版本集中在 `settings.gradle.kts` 的 `plugins { id(...) version "..." }` 块中，避免分散在各子项目。
- **版本约束风格混合**：部分依赖使用 caret 范围（如 `dio: ^5.4.0`、`provider: ^6.1.2`），部分使用精确版本（如 `device_info_plus: 11.5.0`、`common_utils: 2.1.0`、`image_picker: 1.2.0`），最终由 `pubspec.lock` 固化。
- **私有化发布开关**：`publish_to: 'none'` 显式禁止 `flutter pub publish`，表明该工程为内部私有应用，不向 pub.dev 公开。
- **构建产物收敛**：Gradle 通过 `rootProject.layout.buildDirectory = ../../build` 将 Android 构建输出统一到根 `build/` 目录，便于清理和 CI 缓存。
- **资源代码生成**：通过 `flutter_gen_runner` + `flutter_svg` 集成，在 `lib/gen/` 下自动生成资源访问代码，业务代码无需手写路径。

## 4. 约定与约束

- **Dart 依赖必须经 `pub get` 同步**：新增或修改 `pubspec.yaml` 后需运行 `flutter pub get` 更新 `pubspec.lock`，以保证团队成员与 CI 获得一致的传递依赖树。
- **Android 插件版本集中管理**：Android Gradle 插件 (`com.android.application`)、Kotlin 插件 (`org.jetbrains.kotlin.android`)、Flutter Gradle 插件 (`dev.flutter.flutter-plugin-loader`) 的版本均在 `settings.gradle.kts` 的 `plugins {}` 块中声明，不在 `app/build.gradle.kts` 中重复指定。
- **仓库源限定为官方源**：Android Gradle 仅配置 `google()`、`mavenCentral()`、`gradlePluginPortal()`，未发现私有 Maven/Nexus 镜像或 `GRADLE_OPTS` 代理配置；Dart 依赖全部来自 `https://pub.dev`，未见 `pubspec_overrides.yaml` 或自定义 `pubspec.yaml` 中的 `publish_to` 覆盖。
- **SDK 版本锁定**：Dart SDK 通过 `environment.sdk: ^3.12.2` 约束；Android 编译使用 Java 17（`sourceCompatibility/targetCompatibility = VERSION_17`，`jvmTarget = JVM_17`），确保跨平台构建一致性。
- **无 vendoring**：未发现 `vendor/` 或 Git submodule 形式的源码级依赖锁定，所有第三方库均通过包管理器远程拉取。
- **开发期工具与运行时解耦**：lint、代码生成、图标生成等工具放在 `dev_dependencies`，不参与生产构建产物。