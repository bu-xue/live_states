## 1.1.0

### DevTools Extension (Interactive Data Flow Topology)

- **Interactive Topology Graph**: A high-performance, visual graph representing the relationship between `LiveData`, `LiveCompute` states, and `Scopes`.
- **Advanced Visuals**: 
  - Cyberpunk-inspired aesthetic with glassmorphism node designs.
  - Distinct shapes (Hexagon, Capsule, Rounded Rect) and high-contrast colors for different node types.
  - Animated data flow particles ("Comet Tail" effect) to visualize real-time state updates.
- **Sequential Animation System**: Managed animation dependency chain (Source Node Pulse -> Edge Flow -> Target Node Pulse) using `asyncMap` for synchronized visual feedback.
- **Rich Node Inspection**: 
  - Detailed Tooltips displaying ID, Name, Value, and full Subject/Observer lists.
  - Double-click interaction to select nodes for deeper inspection in the DevTools suite.
- **Performance Optimization**: 
  - Component-based rendering using `Stack` and `RepaintBoundary` to achieve smooth 60FPS animations.
  - Static background caching to minimize GPU redraws.
- **Improved Layout**: Implemented a horizontal (Left-to-Right) tree layout algorithm for better readability of data flow paths.

## 1.0.1

### Refinement & Polish

- **Documentation**: Comprehensive README overhaul with a new "Aha!" moment section, comparison tables, and Mermaid-based architecture diagrams.
- **Example App**: Refactored the example into a professional Shopping Cart application showcasing `LiveCompute` and `Recoverable` features.
- **I18n**: Translated all source code comments to English for better international accessibility.
- **Project Metadata**: Updated `pubspec.yaml` with repository links, optimized topics, and refined metadata to improve pub.dev score.
- **CI/CD**: Added GitHub Actions for automated Web Demo deployment to GitHub Pages.
- **Quality Assurance**: Introduced strict `analysis_options.yaml` and refined `.gitignore` for a cleaner development environment.

## 1.0.0

### Features

- **Automatic Dependency Tracking**: Automatically identifies `LiveData` dependencies during the build process using Dart `Zone` mechanism.
- **Precise Local Rebuilds**: Introduces `LiveScope` to minimize the rebuild range and boost performance.
- **MVVM Architecture**: Clear isolation between View (`LiveWidget`) and Business Logic (`LiveViewModel`).
- **Lifecycle Integration**: Deep binding between `LiveViewModel` and Flutter's `Element` lifecycle (mount, unmount, etc.).
- **Reactive Data**: 
  - `LiveData`: Observable state with stream support.
  - `LiveCompute`: Derived state (computed properties) with change verification to prevent unnecessary UI refreshes.
- **Advanced Nodes**:
  - `Recoverable`: Built-in state saving and recovery mechanism.
  - `Refreshable`: Top-down cascading refresh support for complex node trees.
- **Animation Support**: Built-in `SingleTickerProviderMixin` and `TickerProviderMixin` for `LiveViewModel`.
- **Dependency Injection**: `LiveProvider` for shared state management across the widget tree.
- **Debug Tooling**: Integrated `Debugger` with detailed logging for state transitions and dependency tracking.
