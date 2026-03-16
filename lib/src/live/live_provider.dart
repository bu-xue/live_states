part of 'live_view.dart';

typedef LiveProviderCreator<P extends LiveProvider> = P Function();

/// Inherit from this class to implement shared data.
///
/// [LiveProvider] is similar to [LiveViewModel]. Both mix in [LiveStates] 
/// and hold a [LiveOwner] to manage [LiveData] objects.
/// Lifecycle methods include [init] and [dispose].
abstract class LiveProvider with LiveStates, ContextOwner {
  late LiveOwner _owner;

  @override
  LiveOwner get owner => _owner;

  @mustCallSuper
  void init() {}

  @mustCallSuper
  void dispose() {}

  /// Injects a [LiveProvider] instance into the current subtree.
  /// Descendant widgets can access it via:
  /// ```dart
  /// context.provider<T extends LiveProvider>()
  /// ```
  static Widget create<P extends LiveProvider>({
    Key? key,
    required LiveProviderCreator creator,
    required WidgetBuilder builder,
  }) {
    return _LiveProvider.create(
      key: key,
      creator: creator,
      child: Builder(builder: builder),
    );
  }

  /// Injects multiple [LiveProvider] instances.
  static Widget multi(
      List<LiveProviderCreator> creators, WidgetBuilder builder) {
    Widget child = Builder(builder: builder);
    for (var creator in creators.reversed) {
      child = _LiveProvider.create(
        creator: creator,
        child: child,
      );
    }
    return child;
  }

  @override
  late final BuildContext context;
}

class _LiveProvider extends LiveWidget {
  final Widget child;
  final LiveProviderCreator creator;

  @override
  Widget build(BuildContext context, LiveViewModel viewModel) => child;

  @override
  LiveViewModel createViewModel() => _LiveProviderVM();

  const _LiveProvider.create({
    super.key,
    required this.child,
    required this.creator,
  });
}

class _LiveProviderVM extends LiveViewModel<_LiveProvider> {
  late final LiveProvider provider;

  _LiveProviderVM();

  @override
  void init() {
    super.init();
    provider = widget.creator();
    provider.context = context;
    provider._owner = owner;
    provider.init();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }
}

extension Provider4BuildContext on BuildContext {
  /// Finds the nearest [LiveProvider] of type [Provider] in ancestors.
  Provider? provider<Provider extends LiveProvider>() {
    Provider? findProvider(Element element) {
      if (element is LiveElement) {
        final vm = element.viewModel;
        if (vm is _LiveProviderVM && vm.provider is Provider) {
          return vm.provider as Provider;
        }
      }
      return null;
    }

    Provider? result = findProvider(this as Element);
    if (result != null) {
      return result;
    }
    visitAncestorElements((element) {
      result = findProvider(element);
      return result == null;
    });
    return result;
  }
}
