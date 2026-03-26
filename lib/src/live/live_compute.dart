part of 'live_view.dart';

const _inLiveCompute = 'inLiveCompute';

/// A type that can be derived based on existing state or other calculated values.
///
/// We often encounter situations where values are derived from existing state or other calculated values, which can be achieved through simple get methods, for example:
///
/// ```dart
/// late final counter = LiveData<int>(0, owner, debugName: 'count');
/// late final counter2 = LiveData<int>(0, owner, debugName: 'count2');
/// int get total => counter.value + counter2.value;
/// ```
///
/// When listening to total, it actually listens to both counter and counter2 at the same time. This will not be a problem in most cases, but in some cases, it will trigger unnecessary refreshes, for example:
///
/// ```dart
/// bool get totalMoreThan100 => counter.value + counter2.value > 100;
/// ```
///
/// When we need to judge whether the sum of counter and counter2 exceeds 100, the probability of this value changing is small. However, if it is monitored through the get method above, most changes in counter and counter2 will cause unnecessary refreshes. In this case, LiveCompute can be used to mask this change, as follows:
///
/// ```dart
/// late final _totalMoreThan100 =
///   LiveCompute<bool>(owner, () => counter.value + counter2.value > 100);
/// bool get totalMoreThan100 => _totalMoreThan100.value;
/// ```
///
/// At this time, it is this LiveCompute called _totalMoreThan100 that is being monitored. In most cases, changes in counter and counter2 will only trigger re-calculation of LiveCompute. UI refresh will only be triggered when the sum and the size of 100 change.
///
class LiveCompute<T> extends LiveData<T?> with LiveObserver {
  bool _initialized = false;
  bool _disposed = false;
  final T Function() compute;

  /// Constructs an object that derives values based on existing state or other calculated values.
  /// [owner] is the owner of the current state, used for unified release to avoid leaks.
  /// If [debugName] is assigned, debug information will be output to the console in key environments.
  /// [compute] is the method for deriving values based on existing state or other calculated values.
  LiveCompute(
    LiveOwner owner,
    this.compute, {
    super.onUpdateValue,
    super.debugName,
    super.verifyDataChange,
  }) : super(null, owner);

  static LiveObserver? findComputeObserver() {
    return (Zone.current[_inLiveCompute] as LiveCompute?);
  }

  @override
  String get debugId => name;

  @internal
  @override
  set value(T? value) {
    assert(() {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('LiveCompute cannot be assigned.'),
      ]);
    }());
  }

  @override
  T get value {
    _tryInit();
    debug('LiveCompute', 'get ($_currentValue)');
    return super.value as T;
  }

  @override
  StreamSubscription<T?> listen(void Function(T? event) onData,
      {Function? onError, void Function()? onDone}) {
    _tryInit();
    return super.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  void addListener(VoidCallback listener) {
    _tryInit();
    super.addListener(listener);
  }

  void _tryInit() {
    if (!_initialized) {
      _currentValue = _init();
      _initialized = true;
    }
  }

  T _init() {
    return runZoned(() => compute.call(), zoneValues: {_inLiveCompute: this});
  }

  T? _compute() {
    clear();
    return runZoned(() {
      return compute.call();
    }, zoneValues: {_inLiveCompute: this});
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }

  @override
  void onUpdate() {
    if (_disposed) {
      return;
    }
    if (!_initialized) {
      return;
    }
    final newValue = _compute();
    debug('LiveCompute', 'notify to update from $_currentValue to $newValue');
    if (newValue is T) {
      super.value = newValue;
    }
  }

  void update() {
    onUpdate();
  }
}
