part of 'live_view.dart';

/// A mixin that provides observation capabilities for [LiveData].
mixin LiveObserver on Debugger {
  /// Internal map to store active subscriptions.
  late final Map<LiveData, StreamSubscription> subscriptions = {};

  /// Callback triggered when any observed [LiveData] changes.
  void onUpdate();

  /// Cancels all active subscriptions and clears the observer.
  void clear() {
    final ss = [...subscriptions.entries];
    for (var s in ss) {
      s.value.cancel();
      devtools.debugUnsubscribe(observerId: s.key.debugId, subjectId: debugId);
    }
    subscriptions.clear();
  }

  /// Subscribes to a [LiveData] object.
  void subscribe(LiveData liveData) {
    final debugName = liveData.debugName ?? liveData.name;
    final subjectId = liveData.debugId;
    final observerId = debugId;
    debug('LiveObserver', 'subscribe LiveData($debugName)');
    if (subscriptions.containsKey(liveData)) {
      return;
    }

    // Notify DevTools using the polymorphism-based observerId
    devtools.debugSubscribe(observerId: observerId, subjectId: subjectId);

    final subscription = liveData.listen(
      (_) {
        debug('LiveObserver', 'notify by LiveData($debugName)');
        devtools.debugNotify(senderId: subjectId, recipientId: observerId);
        onUpdate();
      },
      onDone: () {
        devtools.debugUnsubscribe(observerId: observerId, subjectId: subjectId);
        subscriptions.remove(liveData);
      },
    );
    subscriptions[liveData] = subscription;
  }
}
