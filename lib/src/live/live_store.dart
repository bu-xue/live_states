part of 'live_view.dart';

class LiveStore extends StatefulWidget {
  final List<LiveProviderCreator> providerCreates;
  final WidgetBuilder builder;
  static GlobalKey? _liveStoreUniqueKey;

  const LiveStore({
    super.key,
    required this.providerCreates,
    required this.builder,
  });

  @override
  State<LiveStore> createState() => _LiveStoreState();

  static Provider? provider<Provider extends LiveProvider>() {
    if (_liveStoreUniqueKey == null) {
      return null;
    }
    return _liveStoreUniqueKey?.currentContext?.provider<Provider>();
  }

  /// 仅用于单元测试重置静态状态
  @visibleForTesting
  static void resetForTest() {
    _liveStoreUniqueKey = null;
  }
}

class _LiveStoreState extends State<LiveStore> {
  @override
  void initState() {
    super.initState();
    assert(() {
      if (LiveStore._liveStoreUniqueKey != null) {
        throw FlutterError.fromParts([
          ErrorSummary(
              'LiveStore should only be used once in the widget tree.'),
          ErrorDescription('Multiple LiveStore widgets are not allowed.'),
          ErrorHint(
              'Ensure that only one LiveStore exists in your widget tree.'),
        ]);
      }
      return true;
    }());
    LiveStore._liveStoreUniqueKey = GlobalKey();
  }

  Widget _buildUnderProvider(BuildContext context) {
    return Builder(
      key: LiveStore._liveStoreUniqueKey,
      builder: widget.builder,
    );
  }

  @override
  Widget build(BuildContext context) => LiveProvider.multi(
        widget.providerCreates,
        _buildUnderProvider,
      );

  @override
  void dispose() {
    LiveStore._liveStoreUniqueKey = null;
    super.dispose();
  }
}
