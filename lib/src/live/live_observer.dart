part of 'live_view.dart';

/// 可以监听LiveData的监听者。
mixin LiveObserver on Debugger {
  late final Map<LiveData, StreamSubscription> subscriptions = {};

  void onUpdate();

  void clear() {
    final ss = [...subscriptions.values];
    for (var subscription in ss) {
      subscription.cancel();
    }
    subscriptions.clear();
  }

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
