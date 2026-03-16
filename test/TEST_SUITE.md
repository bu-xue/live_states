# flutter_live_states Test Suite Documentation

This document describes all unit and widget test scenarios for the `flutter_live_states` package.

## 1. Reactive Core

### [live_data_test.dart]
- **Base Functionality**: Initial value setting, DebugName validation, Owner binding.
- **Notification Mechanism**: Synchronous `addListener` triggering, `verifyDataChange` filtering.
- **onlyValue Isolation**: Verifies that setting `onlyValue` does not trigger notifications, callbacks, or dependency tracking.
- **Advanced Binding**: When the value is a `ChangeNotifier`, internal property changes automatically trigger LiveData notifications.
- **Stream**: Validates asynchronous emission of `liveData.stream`.

### [live_compute_test.dart]
- **Computation Logic**: Validates initial computation and automatic re-computation after dependency changes, including `onUpdateValue` callback.
- **Chained Dependencies**: Validates the propagation of deep nested dependencies (A -> B -> C).
- **Forced Rebuild**: Verifies that `verifyDataChange: false` forces notifications even if the result remains the same.
- **Nullable Handling**: Correctness of `LiveData<T?>` and `LiveCompute` with `null` values.

### [ignore_observer_test.dart]
- **Observation Block**: Verifies that `ignoreObserver` blocks dependency recording in computation or build blocks.
- **IgnoreStream**: Verifies access isolation inside Stream listeners to prevent unexpected tracking.

---

## 2. View & Scope

### [live_scope_widget_test.dart]
- **Local Rebuild**: Changes in Data only rebuild the `LiveScope` interior, keeping Parent isolated.
- **Explicit VM**: Validates the effectiveness of manually passing a ViewModel instance to `LiveScope.vm`.
- **Performance Optimization**: Verifies the `child` property pass-through mechanism to prevent static sub-component rebuilds.
- **Isolation**: Verifies that `followParentUpdate: false` blocks passive rebuilds from the parent.

### [live_widget_test.dart]
- **Lifecycle**: Validates `init`, `dispose`, `didUpdateWidget`, `didChangeDependencies`.
- **Param Response**: Automatic perception of ViewModel and LiveCompute when Widget properties change.
- **Safety Assertions**: Prohibits InheritedWidget access during `init()` or after `dispose()`.

---

## 3. Modularity & Management

### [live_vm_test.dart]
- **Lifecycle Switching**: Uses GlobalKey to verify `activate` and `deactivate` during navigation.
- **Tree Structure**: Automatic establishment of parent-child relationships via `AdvancedNode` and automatic unbinding on disposal.

### [live_provider_test.dart]
- **DI Injection**: Validates `LiveProvider.create` and `multi` injection.
- **Cascade Lookup**: In `multi` mode, verifies subsequent Providers can find previous ones.
- **Scope Lookup**: Validates "nearest ancestor" lookup logic for `context.provider<T>()`.

### [live_store_test.dart]
- **Global Management**: Validates `LiveStore` singleton constraint and static `provider<T>()` lookup.
- **Cleanup Logic**: Resetting static references during disposal and in test environments.

---

## 4. Advanced Mixins

### [recoverable_test.dart]
- **Auto Recovery**: State persistence up the node tree on unmount and automatic recovery on re-mount.

### [refreshable_test.dart]
- **Cascaded Refresh**: Recursive triggering of `onRefresh` for all child nodes.

### [ticker_provider_test.dart]
- **Animation Support**: Validates SingleTicker/MultiTicker, TickerMode synchronization, and leak detection.

---
## How to Run Tests
```bash
flutter test
```
