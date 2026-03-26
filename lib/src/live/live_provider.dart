part of 'live_view.dart';

typedef LiveProviderCreator<P extends LiveProvider> = P Function();

/// Inherit from this class to implement shared data.
abstract class LiveProvider with LiveStates, ContextOwner {
  late LiveOwner _owner;

  @override
  LiveOwner get owner => _owner;

  @mustCallSuper
  void init() {}

  @mustCallSuper
  void dispose() {}

  static Widget create<P extends LiveProvider>({
    Key? key,
    required LiveProviderCreator creator,
    required WidgetBuilder builder,
    String? debugName,
  }) {
    return InnerLiveProvider.create(
      key: key,
      creator: creator,
      child: Builder(builder: builder),
      debugName: debugName,
    );
  }

  static Widget multi(List<LiveProviderCreator> creators, WidgetBuilder builder) {
    Widget child = Builder(builder: builder);
    for (var creator in creators.reversed) {
      child = InnerLiveProvider.create(creator: creator, child: child);
    }
    return child;
  }

  @override
  late final BuildContext context;
}

@internal
class InnerLiveProvider extends LiveWidget {
  final Widget child;
  final LiveProviderCreator creator;

  @override
  Widget build(BuildContext context, LiveViewModel viewModel) => child;

  @override
  LiveViewModel createViewModel() => InnerLiveProviderVM();

  const InnerLiveProvider.create({
    super.key,
    required this.child,
    required this.creator,
    super.debugName,
  });
}

@internal
class InnerLiveProviderVM extends LiveViewModel<InnerLiveProvider> {
  late final LiveProvider provider;

  InnerLiveProviderVM();

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
  Provider? provider<Provider extends LiveProvider>() {
    Provider? findProvider(Element element) {
      if (element is LiveElement) {
        final vm = element.viewModel;
        if (vm is InnerLiveProviderVM && vm.provider is Provider) {
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
