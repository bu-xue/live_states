# live_states 🚀

**Stop watching, start living.**  
A surgical precision, high-performance MVVM framework for Flutter that eliminates boilerplate with **Zone-based automatic dependency tracking**.

[![Pub Version](https://img.shields.io/pub/v/live_states)](https://pub.dev/packages/live_states)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

---

## 📸 Demo

![LiveStates Demo](./gif/live_states.gif)

---

## 🛠️ DevTools Extension: Visual Topology & Inspection

`live_states` comes with a powerful DevTools extension to help you audit your data flow in real-time.

### 1. Visual Data Flow
See how data flows from `LiveData` through `LiveCompute` and finally into your `Scopes`. The topology graph updates in real-time with pulse animations whenever data changes.

![Visual Topology](./gif/data_flow.gif)

### 2. Perspective Switching
Seamlessly navigate between the **Widget Tree** and **Data Flow** views. Simply click a node in the left widget tree to find its data, or **double-click** a node in the right graph to locate its owner widget.

![Perspective Switching](./gif/perspective_switch.gif)

### 3. Detailed Inspection
Hover your mouse over any node to peek at its comprehensive live state, including its unique ID, current value, and a full list of its subjects and observers.

![Detailed Inspection](./gif/detailed_inspection.gif)

---

## ✨ The "Aha!" Moment

### 🪄 Implicit vs. Explicit Tracking
Stop manually listing what you want to watch. In other frameworks, missing a `watch` call means your UI stays stale. In `live_states`, if you touch it, we track it.

```dart
// ❌ Traditional (Riverpod/Provider)
// You must explicitly watch every single state. High mental overhead.
final name = ref.watch(nameProvider);
final age = ref.watch(ageProvider);
final score = ref.watch(scoreProvider);
return Text('$name ($age): $score');

// ✅ live_states (Automatic)
// Just access .value. The Zone-based tracker handles the magic.
LiveScope.free(
  builder: (context, _) => Text('${vm.name.value} (${vm.age.value}): ${vm.score.value}')
)
```

---

## 🌟 Why live_states?

| Feature | **LiveStates** | Provider / Riverpod | Bloc / Redux | GetX |
| :--- | :--- | :--- | :--- | :--- |
| **Tracking** | **Automatic (Zone)** | Manual (`watch`) | Manual (Streams) | Proxy-based |
| **Boilerplate** | **Zero** | Medium | High | Low |
| **Precision** | **Surgical (Scope)** | Widget-level | Widget-level | Component-level |
| **Lifecycle** | **Deep Integration** | Explicit | Independent | Global/Manual |
| **Architecture** | **Pure MVVM** | Functional/DI | Event-driven | Variable |

---

## 🚀 Key Features

```mermaid
graph TD
    subgraph View_Layer
        W[LiveWidget] --> S[LiveScope]
    end

    subgraph Logic_Layer
        VM[LiveViewModel] --> LD[LiveData]
        VM --> LC[LiveCompute]
    end

    LD -- "1. Auto-track (Zone)" --> S
    LC -- "2. Derived & Filtered" --> S
    S -- "3. Surgical Rebuild" --> W
    
    Action(User_Action) --> VM
    VM -- "Update .value" --> LD
```

- **🪄 Magic Dependency Tracking**: Leveraging Dart's `Zone` mechanism to automatically detect dependencies during the build process. No more manual listeners.
- **🎯 Surgical Rebuilds**: `LiveScope` allows you to isolate updates to the smallest possible Widget node, preventing unnecessary parent re-renders.
- **🏗️ Pure MVVM Architecture**: A clean separation of concerns. Your View talks to the ViewModel, and the ViewModel manages the State.
- **♻️ Deep Lifecycle Hooks**: ViewModels that are actually aware of Flutter's lifecycle (`init`, `dispose`, `activate`, `deactivate`).
- **🧬 Reactive Computing**: `LiveCompute` handles complex derived states with built-in change verification to suppress redundant UI updates.
- **💾 State Persistence**: `Recoverable` mixin allows your VM state to survive widget unmounting and app restarts effortlessly.

---

## 📦 Getting Started

### 1. Define your ViewModel
```dart
class CounterVM extends LiveViewModel<CounterPage> {
  // Define reactive data
  late final counter = LiveData<int>(0, owner);

  // Derived state: only notifies if the BOOLEAN result changes!
  late final isEven = LiveCompute<bool>(owner, () => counter.value % 2 == 0);

  void increment() => counter.value++;
}
```

### 2. Build your View
```dart
class CounterPage extends LiveWidget {
  @override
  CounterVM createViewModel() => CounterVM();

  @override
  Widget build(BuildContext context, CounterVM viewModel) {
    return Scaffold(
      body: Center(
        child: LiveScope.vm<CounterVM>(
          builder: (context, vm, _) => Text('Count: ${vm.counter.value}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: viewModel.increment),
    );
  }
}
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
