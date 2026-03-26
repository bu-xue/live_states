import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../advanced/advanced_node.dart';
import '../advanced/context_owner.dart';
import '../utils/debug.dart';

part 'live_data.dart';

part 'live_vm.dart';

part 'live_scope.dart';

part 'live_provider.dart';

part 'live_compute.dart';

part 'live_owner.dart';

part 'live_observer.dart';

part 'live_states.dart';

part 'live_store.dart';

part 'ignore_observe.dart';

const _inMount = 'inMount';

/// View components need to inherit from [LiveWidget].
///
/// [LiveWidget] consists of three parts:
///
/// 1. Parameters:
/// 	* 	Initialize state in the [init] method of [LiveViewModel], and listen for changes in the [didUpdateWidget] method.
/// 	*   Can be used directly in [build], where changes will also trigger the build method.
/// 2. [createViewModel] method: Constructs a ViewModel object, called when the Element is mounted.
/// 3. [build] method: Builds the view. Generally listens to parameters, data provided by [LiveViewModel] and [LiveProvider].
/// Control rebuild range using [LiveScope].
///
/// Example:
/// ```dart
/// class TestWidget extends LiveWidget {
///   final String title;
///
///   const TestWidget({
///     super.key,
///     required this.title,
///   });
///
///   @override
///   TestWidgetVM createViewModel() => TestWidgetVM();
///
///   @override
///   Widget build(BuildContext context, TestWidgetVM viewModel) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text(title),
///       ),
///       body: Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: <Widget>[
///             const Text(
///               'You have pushed the button this many times:',
///             ),
///             LiveScope.free(builder: (context, child) {
///               return Text(
///                 '${viewModel.counter.value}',
///                 style: Theme.of(context).textTheme.headlineMedium,
///               );
///             }),
///           ],
///         ),
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: viewModel.incrementCounter,
///         tooltip: 'Increment',
///         child: const Icon(Icons.add),
///       ),
///     );
///   }
/// }
/// ```
abstract class LiveWidget extends Widget {
  final String? debugName;

  const LiveWidget({super.key, this.debugName});

  @override
  LiveElement createElement() => LiveElement(this);

  LiveViewModel createViewModel();

  Widget build(BuildContext context, covariant LiveViewModel viewModel);
}

class LiveElement extends ComponentElement with Debugger {
  late LiveViewModel _viewModel;

  LiveViewModel get viewModel => _viewModel;

  @override
  LiveWidget get widget => super.widget as LiveWidget;

  bool _didChangeDependencies = false;

  LiveElement(LiveWidget super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    _viewModel = LiveViewModel.create(
      create:
          (BuildContext context, LiveOwner owner) => ignoreObserver(() {
            return widget.createViewModel()
              ..context = context
              ..owner = owner;
          }),
      context: this,
    );
    assert(_viewModel._debugLifecycleState == _ViewModelLifecycle.created);
    runZoned(() => super.mount(parent, newSlot), zoneValues: {_inMount: true});
  }

  @override
  void activate() {
    super.activate();
    ignoreObserver(() {
      _viewModel.activate();
    });
    markNeedsBuild();
  }

  @override
  void deactivate() {
    ignoreObserver(() {
      _viewModel.deactivate();
    });
    super.deactivate();
  }

  @override
  void rebuild({bool force = false}) {
    if (Zone.current[_inMount] == true) {
      _firstBuild();
    }
    super.rebuild(force: force);
  }

  void _firstBuild() {
    assert(_viewModel._debugLifecycleState == _ViewModelLifecycle.created);
    ignoreObserver(() {
      _viewModel.init();
      _viewModel.didChangeDependencies();
      devtools.debugWidgetMount(_viewModel);
    });
  }

  @override
  void performRebuild() {
    if (_didChangeDependencies) {
      ignoreObserver(() {
        _viewModel.didChangeDependencies();
      });
      _didChangeDependencies = false;
    }
    super.performRebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _didChangeDependencies = true;
  }

  @override
  Widget build() => widget.build(this, _viewModel);

  @override
  void update(Widget newWidget) {
    final oldWidget = widget;
    super.update(newWidget);
    ignoreObserver(() {
      _viewModel.didUpdateWidget(oldWidget);
    });
    rebuild(force: true);
  }

  @override
  void unmount() {
    devtools.debugWidgetUnmount(_viewModel);
    ignoreObserver(() {
      _viewModel.dispose();
    });
    assert(() {
      if (_viewModel._debugLifecycleState == _ViewModelLifecycle.defunct) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('${_viewModel.runtimeType}.dispose failed to call super.dispose.'),
        ErrorDescription(
          'dispose() implementations must always call their superclass dispose() method, to ensure '
          'that all the resources used by the widget are fully released.',
        ),
      ]);
    }());
    super.unmount();
  }

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    assert(() {
      final Type targetType = ancestor.widget.runtimeType;
      if (_viewModel._debugLifecycleState == _ViewModelLifecycle.created) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'dependOnInheritedWidgetOfExactType<$targetType>() or dependOnInheritedElement() was called before ${_viewModel.runtimeType}.init() completed.',
          ),
          ErrorDescription(
            'When an inherited widget changes, for example if the value of Theme.of() changes, '
            "its dependent widgets are rebuilt. If the dependent widget's reference to "
            'the inherited widget is in a constructor or an init() method, '
            'then the rebuilt dependent widget will not reflect the changes in the '
            'inherited widget.',
          ),
          ErrorHint(
            'Typically references to inherited widgets should occur in widget build() methods. Alternatively, '
            'initialization based on inherited widgets can be placed in the didChangeDependencies method, which '
            'is called after initState and whenever the dependencies change thereafter.',
          ),
        ]);
      }
      if (_viewModel._debugLifecycleState == _ViewModelLifecycle.defunct) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'dependOnInheritedWidgetOfExactType<$targetType>() or dependOnInheritedElement() was called after dispose(): $this',
          ),
          ErrorDescription(
            'This error happens if you call dependOnInheritedWidgetOfExactType() on the '
            'BuildContext for a widget that no longer appears in the widget tree '
            '(e.g., whose parent widget no longer includes the widget in its '
            'build). This error can occur when code calls '
            'dependOnInheritedWidgetOfExactType() from a timer or an animation callback.',
          ),
          ErrorHint(
            'The preferred solution is to cancel the timer or stop listening to the '
            'animation in the dispose() callback. Another solution is to check the '
            '"mounted" property of this object before calling '
            'dependOnInheritedWidgetOfExactType() to ensure the object is still in the '
            'tree.',
          ),
          ErrorHint(
            'This error might indicate a memory leak if '
            'dependOnInheritedWidgetOfExactType() is being called because another object '
            'is retaining a reference to this State object after it has been '
            'removed from the tree. To avoid memory leaks, consider breaking the '
            'reference to this object during dispose().',
          ),
        ]);
      }
      return true;
    }());
    return super.dependOnInheritedElement(ancestor, aspect: aspect);
  }

  @override
  String get debugId => 'element_${_viewModel.debugId}';
}
