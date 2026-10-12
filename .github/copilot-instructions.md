# 项目开发约束

新增或修改代码时遵循以下约定：

1. **跨平台 Widget**：优先使用 `flutter_platform_widgets` 提供的平台自适应组件，避免在页面中硬编码仅适用于单一平台的 Material 或 Cupertino 交互组件；库未提供对应组件时，使用合适的 Flutter Widget。
2. **状态管理**：使用 `provider` 管理和共享应用状态，优先沿用项目已有的 Provider 模式。
3. **网络图片**：统一使用 `MDNetImage`（`lib/widgets/network_image.dart`），不要直接使用 `Image.network` 或自行创建网络图片缓存逻辑。
4. **提示和加载状态**：统一使用 `MDTotast`（`lib/utils/totast.dart`）显示提示、错误、成功状态和加载状态，不要直接调用其他 Toast 或 Loading API。
5. **路由**：优先使用 `AppRouter`（`lib/router/app_router.dart`）及其路由名称进行页面跳转和返回，不要在页面中重复实现路由逻辑。
6. **列表刷新和分页**：列表需要下拉刷新或上拉加载更多时，优先使用 `RefreshListView`（`lib/widgets/refresh_list_view.dart`）。
7. **颜色**：优先使用 `AppColors`（`lib/utils/app_colors.dart`）中的项目颜色；确需新增颜色时，集中添加到 `AppColors`，避免散落硬编码。
8. **自定义导航栏**：优先使用 `MDAppBar`（`lib/widgets/custom_appbar.dart`），保持项目导航栏样式和返回行为一致。
