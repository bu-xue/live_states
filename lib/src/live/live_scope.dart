part of 'live_view.dart';

const _inLiveScopeObserver = "inLiveScopeObserver";

mixin _LiveScopeObserver on LiveObserver {
  late final tag = const Uuid().v4();

  R liveBuild<R>(R Function() build) {
    final result = runZoned(() => build(), zoneValues: {
      _inLiveScopeObserver: this,
    });
    debug('LiveScope',
        'observe[${subscriptions.keys.map((e) => e.debugName).nonNulls.join(',')}]');

    return result;
  }

  static LiveObserver? findZoneObserver() {
    return (Zone.current[_inLiveScopeObserver] as _LiveScopeObserver?);
  }
}

/// Typedef for [LiveScope] builder.
typedef LiveScopeBuilder<ViewModel extends LiveViewModel> = Widget Function(
    BuildContext context, ViewModel vm, Widget? child);

/// Typedef for [LiveProviderScope] builder.
typedef LiveProviderScopeBuilder<Provider extends LiveProvider> = Widget
    Function(BuildContext context, Provider provider, Widget? child);

/// Typedef for [FreeLiveScope] builder.
typedef FreeLiveScopeBuilder = Widget Function(
    BuildContext context, Widget? child);

/// A Widget that automatically listens to [LiveData] and controls rebuild range.
///
/// Within a [LiveScope], any accessed [LiveData] during the build process will
/// automatically be registered as a dependency. When the data changes,
/// only the scope itself will rebuild.
///
/// Features:
/// 1. Automatic dependency tracking for accessed [LiveData].
/// 2. Precise control over the rebuild range.
///
/// Types:
/// 1. [LiveScope]: Generic type for [LiveViewModel].
/// 2. [LiveProviderScope]: Generic type for [LiveProvider].
/// 3. [FreeLiveScope]: No generic restriction.
class LiveScope<ViewModel extends LiveViewModel> extends _LiveScope {
  final LiveScopeBuilder<ViewModel> builder;
  final ViewModel? viewModel;

  /// Constructs a [LiveScope] that finds the nearest [LiveViewModel].
  const LiveScope({
    super.key,
    required this.builder,
    this.viewModel,
    super.child,
    super.followParentUpdate,
    super.debugName,
  });

  /// Factory for [LiveScope] with a specific [LiveViewModel].
  static LiveScope vm<ViewModel extends LiveViewModel>({
    Key? key,
    required LiveScopeBuilder<ViewModel> builder,
    Widget? child,
    ViewModel? viewModel,
    String? debugName,
    bool? followParentUpdate,
  }) =>
      LiveScope<ViewModel>(
        key: key,
        builder: builder,
        viewModel: viewModel,
        debugName: debugName,
        followParentUpdate: followParentUpdate,
        child: child,
      );

  /// Factory for [LiveProviderScope] with a specific [LiveProvider].
  static LiveProviderScope p<Provider extends LiveProvider>({
    Key? key,
    required LiveProviderScopeBuilder<Provider> builder,
    Widget? child,
    String? debugName,
    bool? followParentUpdate,
  }) =>
      LiveProviderScope<Provider>(
        key: key,
        builder: builder,
        debugName: debugName,
        followParentUpdate: followParentUpdate,
        child: child,
      );

  /// Factory for [FreeLiveScope] with no generic restriction.
  static FreeLiveScope free({
    Key? key,
    required FreeLiveScopeBuilder builder,
    Widget? child,
    String? debugName,
    bool? followParentUpdate,
  }) =>
      FreeLiveScope(
        key: key,
        builder: builder,
        debugName: debugName,
        followParentUpdate: followParentUpdate,
        child: child,
      );

  @override
  Widget build(BuildContext context, ViewModel? states) {
    return builder(context, states!, child);
  }

  @override
  Element createElement() {
    return LiveVMScopeElement<ViewModel>(this);
  }
}

/// Same as [LiveScope], but restricted to [LiveProvider].
class LiveProviderScope<Provider extends LiveProvider> extends _LiveScope {
  final LiveProviderScopeBuilder<Provider>? builder;

  const LiveProviderScope({
    super.key,
    required this.builder,
    super.child,
    super.followParentUpdate,
    super.debugName,
  });

  @override
  Widget build(BuildContext context, Provider? states) {
    return builder!(context, states!, child);
  }

  @override
  Element createElement() {
    return LiveProviderScopeElement<Provider>(this);
  }
}

/// Same as [LiveScope], but without generic restrictions.
class FreeLiveScope extends _LiveScope {
  final FreeLiveScopeBuilder? builder;

  const FreeLiveScope({
    super.key,
    required this.builder,
    super.child,
    super.followParentUpdate,
    super.debugName,
  });

  @override
  Widget build(BuildContext context, LiveStates? states) {
    return builder!(context, child);
  }

  @override
  Element createElement() {
    return LiveFreeScopeElement(this);
  }
}

abstract class _LiveScope extends Widget {
  final Widget? child;

  final String? debugName;
  final bool followParentUpdate;

  const _LiveScope({
    super.key,
    this.child,
    this.debugName,
    bool? followParentUpdate,
  }) : followParentUpdate = followParentUpdate ?? true;

  Widget build(BuildContext context, covariant LiveStates? states);
}

@internal
abstract class BaseLiveScopeElement extends ComponentElement
    with Debugger, LiveObserver, _LiveScopeObserver {
  @override
  final String debugId;

  @override
  String? get debugName => widget.debugName;

  @override
  _LiveScope get widget => super.widget as _LiveScope;

  bool isMounted = false;

  BaseLiveScopeElement(super.widget) : debugId = const Uuid().v4();

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    isMounted = true;
  }

  @override
  void unmount() {
    isMounted = false;
    clear();
    devtools.debugScopeUnmount(this);
    super.unmount();
  }

  @override
  void performRebuild() {
    if(!isMounted) {
      devtools.debugScopeMount(this);
    }
    clear();
    liveBuild(() => super.performRebuild());
  }

  @override
  void onUpdate() {
    if (isMounted) {
      markNeedsBuild();
      devtools.debugObserverUpdate(debugId: debugId);
    }
  }

  @override
  void update(newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    if (widget.followParentUpdate) {
      rebuild(force: true);
    }
  }
}

@internal
class LiveVMScopeElement<ViewModel extends LiveViewModel> extends BaseLiveScopeElement {
  LiveVMScopeElement(super.widget);

  @override
  LiveScope get widget => super.widget as LiveScope;

  ViewModel? vm;

  @override
  Widget build() {
    assert(() {
      if (vm == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Could not find LiveWidget with $vm in ancestors'),
        ]);
      }
      return true;
    }());
    debug('LiveScope', 'build');
    return widget.build(this, vm!);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    if (widget.viewModel != null) {
      vm = widget.viewModel as ViewModel;
    } else {
      vm = parent?.vm<ViewModel>();
    }
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    vm = null;
    super.unmount();
  }
}

@internal
class LiveProviderScopeElement<Provider extends LiveProvider> extends BaseLiveScopeElement {
  LiveProviderScopeElement(super.widget);

  @override
  LiveProviderScope get widget => super.widget as LiveProviderScope;

  Provider? provider;

  @override
  Widget build() {
    assert(() {
      if (provider == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Could not find Widget with $provider in ancestors'),
        ]);
      }
      return true;
    }());
    debug('LiveScope', 'build');
    return widget.build(this, provider!);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    provider = parent?.provider<Provider>();
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    provider = null;
    super.unmount();
  }
}

@internal
class LiveFreeScopeElement extends BaseLiveScopeElement {
  LiveFreeScopeElement(super.widget);

  @override
  Widget build() {
    debug('LiveScope', 'build');
    return widget.build(this, null);
  }
}
