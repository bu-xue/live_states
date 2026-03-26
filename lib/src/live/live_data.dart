part of 'live_view.dart';

/// Base class providing basic value operations.
abstract class _ValueChangeNotifier<T> extends ChangeNotifier with Debugger {
  /// Initial value.
  final T initialValue;

  /// Whether to notify listeners only if the data has actually changed. Defaults to true.
  final bool verifyDataChange;

  late T _currentValue;

  _ValueChangeNotifier(this.initialValue, {this.verifyDataChange = true}) {
    _initValue();
  }

  void _initValue() {
    _currentValue = initialValue;
  }

  /// Get value without triggering automatic observation.
  // ignore: unnecessary_getters_setters
  T get onlyValue => _currentValue;

  /// Set value without notifying listeners.
  // ignore: unnecessary_getters_setters
  set onlyValue(T value) => _currentValue = value;

  /// Get value and trigger automatic observation.
  T get value {
    _onLiveDataGet();
    return onlyValue;
  }

  /// Set value and notify listeners if the value has changed.
  set value(T value) {
    if (verifyDataChange && _currentValue == value) {
      debug("LiveData", "verify value change but set value not changed");
      return;
    }
    _onUpdateValue(onlyValue, value);
  }

  @mustCallSuper
  void _onUpdateValue(T oldValue, T newValue) {
    onlyValue = newValue;
    devtools.debugDataChanged(debugId: debugId, value: newValue == null ? null : '$newValue');
    notifyListeners();
  }

  void _onLiveDataGet();

  /// Call all the registered listeners.
  @override
  void notifyListeners() {
    debug('LiveData', 'notify listeners');
    // Use ignoreObserver to prevent incorrect observation when listeners access other LiveData
    ignoreObserver(super.notifyListeners);
  }

  /// Register a closure to be called when the object changes.
  @override
  void addListener(VoidCallback listener) {
    debug('LiveData', 'add listener: $listener');
    super.addListener(listener);
  }

  /// Remove a previously registered closure.
  @override
  void removeListener(VoidCallback listener) {
    debug('LiveData', 'remove listener: $listener');
    super.removeListener(listener);
  }

  @override
  void dispose() {
    debug('LiveData', 'on dispose');
    super.dispose();
  }
}

/// Mixin that provides Stream capabilities to LiveData.
mixin _WithStream<T> on _ValueChangeNotifier<T> {
  StreamController<T>? _streamController;

  /// The stream controlled by this LiveData.
  Stream<T> get stream {
    _createStreamControllerIfNotExists();
    return IgnoreStream(_streamController!.stream);
  }

  /// Adds a subscription to this LiveData similar to a stream.
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    debug('LiveData', 'listen');
    return stream.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  void dispose() {
    _disposeStreamController();
    super.dispose();
  }

  void _notify() {
    if (_streamController != null && !_streamController!.isClosed) {
      _streamController!.add(onlyValue);
    }
  }

  void _createStreamControllerIfNotExists() {
    if (_streamController == null) {
      debug('LiveData', 'create stream controller');
      _streamController ??= StreamController.broadcast(
        sync: true,
        onCancel: () {
          _disposeStreamController();
        },
      );
      addListener(_notify);
    }
  }

  void _disposeStreamController() {
    removeListener(_notify);
    try {
      _streamController?.close();
    } finally {
      _streamController = null;
    }
    debug('LiveData', 'dispose stream controller');
  }
}

/// Mixin that binds notifyListeners when the value is a ChangeNotifier.
mixin _WithChangeNotifier<T> on _ValueChangeNotifier<T> {
  @override
  void _initValue() {
    super._initValue();
    final value = _currentValue;
    if (value is ChangeNotifier) {
      value.addListener(notifyListeners);
    }
  }

  @override
  set onlyValue(T value) {
    final oldValue = _currentValue;
    if (value == oldValue) {
      return;
    }
    if (oldValue is ValueNotifier) {
      oldValue.removeListener(notifyListeners);
    }
    if (value is ChangeNotifier) {
      value.addListener(notifyListeners);
    }
    super.onlyValue = value;
  }

  @override
  void dispose() {
    final value = onlyValue;
    if (value is ChangeNotifier) {
      value.removeListener(notifyListeners);
    }
    super.dispose();
  }
}

/// An object that manages state and can be observed.
///
/// Accessing [value] within a [LiveScope] adds the scope as a listener.
/// Setting [value] notifies all listeners.
/// [LiveData] itself is a [ChangeNotifier].
/// It also provides a [listen] method similar to a [Stream].
/// When the value type [T] is a [ChangeNotifier], its [notifyListeners] will also trigger [notify].
class LiveData<T> extends _ValueChangeNotifier<T> with _WithStream<T>, _WithChangeNotifier<T> {
  /// Unique identifier.
  final String name;

  final String? _debugName;

  final Function(T oldValue, T newValue)? onUpdateValue;

  LiveOwner owner;

  /// Constructs a LiveData object.
  /// [initialValue] is the starting value.
  /// [owner] is the manager responsible for automatic disposal.
  /// [debugName] is used for console debugging.
  /// [verifyDataChange] controls whether notifications are sent only when the value actually changes.
  ///
  /// Typically declared as members of [LiveStates] or [LiveViewModel].
  /// Example:
  /// ```dart
  /// late final counter = LiveData<int>(0, owner, debugName: 'count');
  /// ```
  LiveData(
    super.initialValue,
    this.owner, {
    this.onUpdateValue,
    String? debugName,
    super.verifyDataChange,
  }) : name = const Uuid().v4(),
       _debugName = debugName {
    owner._addLiveData(this);
    devtools.debugLiveDataRegister(owner.vmDebugId, this);
  }

  @override
  void _onLiveDataGet() => owner.onLiveDataGet(this);

  /// Manually trigger notification.
  void notify() {
    notifyListeners();
  }

  @override
  void _onUpdateValue(T oldValue, T newValue) {
    onUpdateValue?.call(oldValue, newValue);
    super._onUpdateValue(oldValue, newValue);
  }

  @override
  void dispose() {
    devtools.debugLiveDataUnregister(this);
    owner._removeLiveData(this);
    super.dispose();
  }

  @override
  String toString() {
    return 'LiveData{$name, $_currentValue}';
  }

  @override
  String? get debugName => _debugName;

  @override
  String get debugId => name;
}
