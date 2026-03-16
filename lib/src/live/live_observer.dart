part of 'live_view.dart';

/// A mixin that provides observation capabilities for [LiveData].
mixin LiveObserver on Debugger {
  /// Internal map to store active subscriptions.
  late final Map<LiveData, StreamSubscription> subscriptions = {};

  /// Callback triggered when any observed [LiveData] changes.
  void onUpdate();

  /// Cancels all active subscriptions and clears the observer.
  void clear() {
    final ss = [...subscriptions.values];
    for (var subscription in ss) {
      subscription.cancel();
    }
    subscriptions.clear();
  }

  /// Subscribes to a [LiveData] object.
  /// 
  /// If the [liveData] is already being observed, this call is ignored.
  void subscribe(LiveData liveData) {
    final debugName = liveData.debugName ?? liveData.name;
    debug('LiveObserver', 'subscribe LiveData($debugName)');
    if (subscriptions.containsKey(liveData)) {
      return;
    }
    final subscription = liveData.listen(
      (_) {
        debug('LiveObserver', 'notify by LiveData($debugName)');
        onUpdate();
      },
      onDone: () {
        subscriptions.remove(liveData);
      },
    );
    subscriptions[liveData] = subscription;
  }
}
