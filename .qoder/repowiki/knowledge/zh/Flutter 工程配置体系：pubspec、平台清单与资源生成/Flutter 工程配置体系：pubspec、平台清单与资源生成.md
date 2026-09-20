---
kind: configuration_system
name: Flutter 工程配置体系：pubspec、平台清单与资源生成
category: configuration_system
scope:
    - '**'
source_files:
    - pubspec.yaml
    - flutter_gen.yaml
    - analysis_options.yaml
    - lib/main.dart
    - lib/utils/app_colors.dart
    - lib/utils/exports.dart
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml
    - ios/Runner/Info.plist
---

## 1. 使用的系统与工具

本仓库是一个 Flutter 跨平台应用，其“配置系统”由以下三部分构成：
- **Dart/Flutter 包级配置**：`pubspec.yaml` 声明应用元信息（名称、版本、环境 SDK）、依赖、资源目录以及构建工具插件。
- **平台原生清单**：Android 的 `android/app/src/main/AndroidManifest.xml` + `android/app/build.gradle.kts`，iOS 的 `ios/Runner/Info.plist`，用于声明应用 ID、最低/目标 SDK、权限、启动页等。
- **资源与代码生成配置**：通过 `flutter_gen.yaml` + `flutter_launcher_icons` 在 `pubspec.yaml` 中启用，将 `assets/images/` 下的图片及 SVG 编译为类型安全的 Dart 访问器，输出到 `lib/gen/`。

没有发现独立的运行时配置文件（如 `.env`、`config.json`、`application.properties`）或运行时配置加载逻辑；所有可配置项集中在上述静态配置文件中。

## 2. 关键文件

- `pubspec.yaml`：应用名 `zslx_flutter`、版本 `1.0.0+1`、SDK 约束 `^3.12.2`；集中声明网络（dio）、状态管理（provider）、本地存储（shared_preferences）、屏幕适配（flutter_screenutil）、SVG（flutter_svg）等依赖；声明 `assets/images/` 与 `assets/images/tabbar/` 两个资源目录；通过 `flutter_gen_runner` 和 `flutter_launcher_icons` 完成资源与图标生成。
- `flutter_gen.yaml`：指定生成输出目录为 `lib/gen/`，并开启 `flutter_svg` 集成以生成 SVG 快捷方法。
- `analysis_options.yaml`：继承 `package:flutter_lints/flutter.yaml`，仅对 `duplicate_import` 做 ignore 处理，作为静态分析配置。
- `lib/utils/app_colors.dart`：集中定义主题色、标题色、内容色、背景色等，通过 `HexColor.fromHex` 解析十六进制颜色，是 UI 层唯一的颜色来源。
- `lib/utils/exports.dart`：统一导出 `flutter_svg`、`gen/assets.gen.dart`、`app_colors.dart`、`color_extensions.dart`，供业务模块统一 import。
- `lib/main.dart`：应用入口，直接构造 `MaterialApp`，使用 `AppColors.theme` 作为 seed color 初始化 `ColorScheme`，首页为 `StartPage`。
- `android/app/build.gradle.kts`：声明 Android 命名空间 `com.zs.zslx`、compile/target Java 17、minSdk 24、versionCode 1、versionName 1.0.0；release build 复用 debug signingConfig。
- `android/app/src/main/AndroidManifest.xml`：声明 Activity 为 LAUNCHER、`flutterEmbedding=2`、`applicationName` 占位符、`queries` 允许文本处理。
- `ios/Runner/Info.plist`：通过 `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` 注入 Flutter 构建版本号，声明支持的界面方向、LaunchScreen/Main Storyboard。

## 3. 架构与约定

- **单一事实源**：应用元数据（名称、版本）在 `pubspec.yaml` 中维护一次，Android 的 `versionCode`/`versionName` 与 iOS 的 `CFBundleShortVersionString`/`CFBundleVersion` 分别通过 Gradle 和 Info.plist 变量同步。
- **资源访问类型安全化**：通过 `flutter_gen_runner` 将 `assets/images/` 下资源生成到 `lib/gen/assets.gen.dart`，并在 `lib/utils/exports.dart` 中统一导出，业务侧通过 `Assets.images.*` 访问，避免字符串路径拼写错误。
- **主题集中化**：颜色常量集中在 `AppColors` 类，`main.dart` 用 `AppColors.theme` 作为 `ColorScheme.fromSeed` 的种子，保证全局主题一致性。
- **平台差异通过原生清单承载**：Android 的权限、Activity 行为、Flutter Embedding 版本写在 Manifest；iOS 的 Bundle 标识、启动页、方向限制写在 Info.plist；Dart 层不感知这些差异。
- **无运行时配置加载**：当前工程没有实现读取 `.env`、远程配置中心或动态 feature flag 的逻辑；所有开关（如 release/debug 签名、minSdk、主题色）均通过静态配置决定。

## 4. 约定与约束

- 依赖与资源声明必须放在 `pubspec.yaml` 对应 section，dev_dependencies 与 flutter 配置平级缩进（见注释“此处与dev_dependencies平级，不能缩进”）。
- 资源目录只包含 `assets/images/` 与 `assets/images/tabbar/`，新增资源需放入这两个目录之一才能被 `flutter_gen` 扫描。
- 颜色修改统一走 `lib/utils/app_colors.dart` 中的 `AppColors` 静态字段，禁止在各页面硬编码十六进制颜色。
- Android 最低支持版本固定为 minSdk 24（Android 7.0），targetSdk 跟随 Flutter 提供的版本。
- iOS 版本号通过 `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` 注入，不在 Info.plist 中手写具体数字。
- 静态分析规则继承自 `flutter_lints/flutter.yaml`，如需关闭某条 lint 应在 `analysis_options.yaml` 的 `linter.rules` 中显式设置，而非在单行使用 `// ignore:` 随意覆盖。
- 发布签名目前 release 构建复用 debug 签名（`signingConfigs.getByName("debug")`），属于临时配置，正式发布前应替换为独立 keystore。