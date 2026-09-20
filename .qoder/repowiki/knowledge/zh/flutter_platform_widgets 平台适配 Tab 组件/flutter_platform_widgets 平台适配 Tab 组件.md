---
kind: external_dependency
name: flutter_platform_widgets 平台适配 Tab 组件
slug: flutter-platform-widgets
category: external_dependency
category_hints:
    - framework_behavior
scope:
    - '**'
---

### 概述
- 通过 `flutter_platform_widgets` 包在 Flutter 中提供跨平台的系统级导航栏（Bottom Navigation Bar）适配，替代原生 Material/Cupertino 各自实现。

### 在本项目中的使用方式
- 入口位于 `lib/pages/starts/tabbar_page.dart`：
  - 使用 `PlatformTabController` 管理 Tab 切换状态；
  - 外层容器使用 `PlatformTabScaffold`，并通过 `materialTabs` / `cupertinoTabs` 回调分别注入 `MaterialNavBarData` 与 `CupertinoTabBarData`，实现同一份 UI 在不同平台呈现系统原生风格；
  - `items` 仍使用 `BottomNavigationBarItem` 描述每个 Tab 的图标与标签。
- 依赖声明在 `pubspec.yaml` 的 `dependencies` 区域，同时引入 `cupertino_icons` 作为 iOS 风格图标来源。

### 集成要点
- 新增或修改 Tab 时，只需维护 `_tabItems` 列表与 `_pages` 页面数组，无需再分别写 Material 和 Cupertino 两套实现。
- 样式定制集中在 `materialTabs` 与 `cupertinoTabs` 两个回调中配置颜色、背景、边框等参数。
- 注意该包目前不覆盖鸿蒙平台，若后续接入鸿蒙需另行处理。