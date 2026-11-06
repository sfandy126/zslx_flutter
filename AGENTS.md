# 项目开发约束

本文件适用于整个仓库。任何 AI 编码助手在新增、修改或修复代码前，应先阅读相关代码并遵循以下约束。保持改动范围与任务一致，沿用项目已有实现方式。

## 组件与代码约定

1. **跨平台 Widget**：优先使用Material交互组件。
2. **状态管理**：使用 `provider` 管理和共享应用状态，优先沿用项目已有的 Provider 模式。
3. **网络图片**：统一使用 `MDNetImage`（`lib/widgets/network_image.dart`），不要直接使用 `Image.network` 或自行创建网络图片缓存逻辑。
4. **提示和加载状态**：统一使用 `MDTotast`（`lib/utils/totast.dart`）显示提示、错误、成功状态和加载状态，不要直接调用其他 Toast 或 Loading API。页面加载进度使用 `MDTotast.showLoading()`，避免使用页面自带的进度组件（如 `CircularProgressIndicator`、`LinearProgressIndicator`）。
5. **路由**：优先使用 `AppRouter`（`lib/router/app_router.dart`）及其路由名称进行页面跳转和返回，不要在页面中重复实现路由逻辑。
6. **列表刷新和分页**：列表需要下拉刷新或上拉加载更多时，优先使用 `RefreshListView`（`lib/widgets/refresh_list_view.dart`）。
7. **下拉刷新**：优先使用自定义 `MDRefreshHeader`，避免使用 `RefreshIndicator`，保持项目下拉刷新样式统一。
8. **上拉刷新/加载更多**：优先使用自定义 `MDRefreshFooter`，避免使用 `RefreshIndicator`，保持项目下拉刷新样式统一。
9. **颜色**：优先使用 `AppColors`（`lib/utils/app_colors.dart`）中的项目颜色；确需新增颜色时，集中添加到 `AppColors`，避免散落硬编码。
10. **自定义导航栏**：优先使用 `MDAppBar`（`lib/widgets/custom_appbar.dart`），保持项目导航栏样式和返回行为一致。

## 渠道与构建

- 渠道、包名、应用名称和版本配置以 `flavorizr.yaml` 为唯一入口。修改后运行 `dart run tool/build.dart sync` 同步配置。
- 不要手动修改由同步命令生成的 `android/app/flavorizr.gradle.kts`、`ios/Flutter/AppInfo.xcconfig`、`lib/flavors.dart`，以及 `pubspec.yaml` 中的版本号。
- 本地调试使用 `dart run tool/build.dart run <渠道>`；Android 打包使用 `dart run tool/build.dart android [渠道...]`；全部 Android 和 iOS 打包使用 `dart run tool/build.dart all`。打包会递增构建号，仅在任务需要打包时执行。

## 验证与交付

- 修改 Dart 代码后格式化改动文件，并运行适合改动范围的分析或测试；涉及构建配置时验证对应的构建任务。
- 交付时说明实际改动、已运行的验证及结果；未验证的部分要明确说明。
