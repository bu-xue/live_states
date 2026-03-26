part of 'live_view.dart';

/// A manager class for a set of [LiveData] objects.
///
/// Typically held by [LiveViewModel] and [LiveProvider].
/// Automatically disposes of [LiveData] objects when it is disposed.
class LiveOwner {
  late final String vmDebugId;

  @visibleForTesting
  LiveOwner.test();

  LiveOwner._();

  late final Map<String, LiveData> _liveDataMaps = {};

  void _addLiveData(LiveData liveData) {
    _liveDataMaps[liveData.name] = liveData;
  }

  void _removeLiveData(LiveData liveData) {
    _liveDataMaps.remove(liveData.name);
  }

  @visibleForTesting
  bool containsName(String name) => _liveDataMaps.containsKey(name);

  void dispose() {
    final maps = {..._liveDataMaps};
    maps.forEach((key, value) {
      if (_liveDataMaps.containsKey(key)) {
        value.dispose();
      }
    });
    _liveDataMaps.clear();
  }

  /// Creates a VM instance.
  static LiveViewModel createVM(BuildContext context, LiveViewModelCreator create) {
    final owner = LiveOwner._();
    final vm = create(context, owner);
    owner.vmDebugId = vm.debugId;
    return vm;
  }

  void onLiveDataGet(LiveData liveData) {
    (LiveCompute.findComputeObserver() ?? _LiveScopeObserver.findZoneObserver())?.subscribe(liveData);
  }

  void didUpdateWidget() {
    final keys = {..._liveDataMaps.keys};
    for (final key in keys) {
      final existValue = _liveDataMaps[key];
      if (existValue != null && existValue is LiveCompute) {
        existValue.onUpdate();
      }
    }
  }
}
