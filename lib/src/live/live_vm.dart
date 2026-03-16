part of 'live_view.dart';

/// Typedef for [LiveViewModel] creation method.
typedef LiveViewModelCreator = LiveViewModel Function(
    BuildContext context, LiveOwner owner);

enum _ViewModelLifecycle {
  created,
  ready,
  defunct,
}

/// Inherit from [LiveViewModel] to define your ViewModel.
///
/// Provides four lifecycle methods:
/// * [init]: Called before the first build. Used for initialization.
/// * [dispose]: Called when the Element is unmounted. (LiveData is automatically disposed).
/// * [didUpdateWidget]: Called when the associated widget changes.
/// * [didChangeDependencies]: Called when dependencies change.
///
/// ViewModel classes typically define actions for business logic and state updates.
abstract class LiveViewModel<L extends LiveWidget>
    with Debugger, ContextOwner, AdvancedNode, LiveStates {
  @override
  late final LiveOwner owner;

  @override
  late final BuildContext context;

  /// Gets the associated widget.
  L get widget => context.widget as L;

  LiveViewModel();

  _ViewModelLifecycle _debugLifecycleState = _ViewModelLifecycle.created;

  @visibleForTesting
  bool get created =>
      _debugLifecycleState == _ViewModelLifecycle.created;

  @visibleForTesting
  bool get ready =>
      _debugLifecycleState == _ViewModelLifecycle.ready;

  @visibleForTesting
  bool get defunct => _debugLifecycleState == _ViewModelLifecycle.defunct;

  @mustCallSuper
  void init() {
    assert(_debugLifecycleState == _ViewModelLifecycle.created);
    assert(() {
      _debugLifecycleState = _ViewModelLifecycle.ready;
      return true;
    }());
    mountNode();
  }

  @mustCallSuper
  void dispose() {
    assert(_debugLifecycleState == _ViewModelLifecycle.ready);
    assert(() {
      _debugLifecycleState = _ViewModelLifecycle.defunct;
      return true;
    }());
    unmountNode();
    disposeContext();
    owner.dispose();
  }

  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  @protected
  @mustCallSuper
  void didUpdateWidget(L oldWidget) {
    owner.didUpdateWidget();
  }

  /// Factory method to create a VM instance.
  static LiveViewModel create({
    required LiveViewModelCreator create,
    required LiveElement context,
  }) {
    return LiveOwner.createVM(context, create);
  }

  @protected
  @mustCallSuper
  void activate() {}

  @protected
  @mustCallSuper
  void deactivate() {}
}

extension VMForBuildContext on BuildContext {
  /// Finds the nearest [LiveViewModel] of type [ViewModel] in ancestors.
  ViewModel? vm<ViewModel extends LiveViewModel>() {
    ViewModel? findVM(Element element) {
      if (element is LiveElement) {
        final vm = element.viewModel;
        if (vm is ViewModel) {
          return vm;
        }
      }
      return null;
    }

    ViewModel? result = findVM(this as Element);
    if (result != null) {
      return result;
    }
    visitAncestorElements((element) {
      result = findVM(element);
      return result == null;
    });
    return result;
  }
}
