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
