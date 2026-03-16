# live_states

A high-performance, lightweight state management framework for Flutter that implements a pure MVVM architecture with **Zone-based automatic dependency tracking**.

`live_states` is designed to eliminate boilerplate code. By leveraging Dart's `Zone` mechanism, it automatically detects which data your UI depends on during the build process, ensuring surgical precision in rebuilds without manual listener management.

---

## 🌟 Why live_states?

| Feature | **LiveStates** | Provider | Riverpod | Bloc / Redux | GetX |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tracking** | **Automatic (Zone)** | Manual (`watch`) | Manual (`ref.watch`) | Manual (Streams) | Automatic (Proxy) |
| **Boilerplate** | **Zero** | Low to Medium | Medium | High | Low |
| **Rebuild Scope**| **Granular (Scope)**| Widget-level | Widget-level | Widget-level | Component-level |
| **Lifecycle** | **Deeply Integrated**| Limited | Explicit | Independent | Global/Manual |
| **Architecture** | **Native MVVM** | DI-focused | Functional/Global | Event-driven | Variable |

---

## 🚀 Key Features

- **🚀 Automatic Dependency Tracking**: No need to manually add listeners. If you access a `LiveData` during build inside a `LiveScope`, it's tracked automatically.
- **🎯 Precise Rebuilds**: Granular control over widget updates with `LiveScope`, minimizing UI jank by isolating rebuilds from parent widgets.
- **🏗️ Pure MVVM Architecture**: Strictly separates business logic (`LiveViewModel`) from presentation (`LiveWidget`).
- **♻️ Full Lifecycle Management**: ViewModels are aware of `init`, `dispose`, `activate`, `deactivate`, and `didUpdateWidget`.
- **🧬 Advanced Mixins**: Built-in support for cascaded refreshes, state recovery, and animation tickers directly in the VM.
- **📦 Dependency Injection**: Scalable state sharing via `LiveProvider` and global `LiveStore`.

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  live_states: ^1.0.0
```

---

## 🚀 exhaustive Feature Guide

### 1. Basic Reactive State (`LiveData`)
`LiveData` is the atomic unit of state. Use `.value` to trigger rebuilds or `.onlyValue` for silent updates.

```dart
class UserVM extends LiveViewModel<UserWidget> {
  // Simple reactive state
  late final username = LiveData<String>('Guest', owner);
  
  void updateUsername(String name) {
    username.value = name; // Triggers listeners/rebuilds
  }

  void updateSilently(String name) {
    username.onlyValue = name; // Update data without triggering UI refresh
  }
}
```

### 2. Derived State (`LiveCompute`)
`LiveCompute` creates a value that automatically re-calculates when its dependencies change. It optimizes performance by preventing downstream rebuilds if the *result* of the calculation hasn't changed.

```dart
class CartVM extends LiveViewModel {
  late final items = LiveData<List<Item>>([], owner);
  
  // Re-calculates ONLY when 'items' changes. 
  // Observers only rebuild if 'totalPrice' actually changes.
  late final totalPrice = LiveCompute<double>(owner, () {
    return items.value.fold(0, (sum, item) => sum + item.price);
  });
}
```

### 3. Precision Rebuilds (`LiveScope`)
`LiveScope` is the bridge between data and UI. It tracks every `LiveData` accessed within its `builder`.

```dart
@override
Widget build(BuildContext context, CounterVM viewModel) {
  return Column(
    children: [
      // Only this specific Text rebuilds when counter changes
      LiveScope.vm<CounterVM>(
        builder: (context, vm, child) => Text('Count: ${vm.counter.value}'),
      ),
      // This part is completely static and NEVER rebuilds
      const Text('I am a static label'),
    ],
  );
}
```

### 4. Advanced Lifecycles (`activate` / `deactivate`)
Ideal for handling visibility changes in `PageView` or `Tab` without polluting the UI layer.

```dart
class VideoPlayerVM extends LiveViewModel {
  @override
  void activate() => player.resume(); // Called when page becomes visible

  @override
  void deactivate() => player.pause(); // Called when page is hidden
}
```

### 5. Cascaded Refresh (`Refreshable`)
Trigger a recursive reload signal across your entire ViewModel tree with a single call.

```dart
class ParentVM extends LiveViewModel with Refreshable {
  @override
  Future<bool> onRefresh() async {
    await fetchData();
    return true;
  }
  
  void pullToRefresh() => refresh(); // Triggers onRefresh here and in all children
}
```

### 6. State Persistence (`Recoverable`)
Automatically save and restore state when a widget is unmounted and re-mounted (e.g., during complex navigation).

```dart
class SearchVM extends LiveViewModel with Recoverable {
  @override
  String get storageKey => 'unique_search_cache_key';

  @override
  Map<String, dynamic>? storage() => {'query': query.value};

  @override
  void recover(Map<String, dynamic>? storage) {
    if (storage != null) query.value = storage['query'];
  }
}
```

### 7. Global & Scoped DI (`LiveStore` / `LiveProvider`)
Inject and find data across the widget tree effortlessly.

```dart
// Global Injection (at App root)
LiveStore(
  providerCreates: [() => AuthService(), () => AppConfig()],
  builder: (context) => MyApp(),
);

// Access anywhere via context
final auth = context.provider<AuthService>();

// Access globally without context
final config = LiveStore.provider<AppConfig>();
```

### 8. Animation Support (`TickerProvider`)
Manage standard Flutter animations directly inside your ViewModel.

```dart
class AnimationVM extends LiveViewModel with SingleTickerProviderMixin {
  late final controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  
  @override
  void dispose() {
    controller.dispose(); // Mixin will assert error if you leak tickers!
    super.dispose();
  }
}
```

---

## 🛠️ Performance Tuning

1.  **`followParentUpdate: false`**: Set this in `LiveScope` to make it *completely* independent of parent rebuilds.
2.  **`LiveScope.child`**: Pass pre-built static widget trees to `child` to avoid re-allocation during local refreshes.
3.  **`LiveData.onlyValue`**: Use `.onlyValue` to read data without establishing a reactive dependency in a `LiveScope`.

---

## 🧪 Stability

This package is built with a "test-first" mentality. Every core component is verified against memory leaks, nested dependency resolution, and lifecycle accuracy. Check [TEST_SUITE.md](./test/TEST_SUITE.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
