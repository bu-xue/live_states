import 'package:flutter/foundation.dart';
import 'package:live_states/live_states.dart';
import 'package:test/test.dart';

void main() {
  group('LiveObserver Tests', () {
    late LiveOwner owner;
    late LiveData<int> counter;
    late MockLiveObserver observer;

    setUp(() {
      owner = LiveOwner.test()..vmDebugId = 'vm';
      counter = LiveData<int>(0, owner, debugName: 'counter');
      observer = MockLiveObserver();
    });

    tearDown(() {
      owner.dispose();
    });

    test('Should call onUpdate synchronously when LiveData changes', () {
      observer.subscribe(counter);

      int callCount = 0;
      observer.update = () => callCount++;

      counter.value = 1;
      expect(callCount, 1);
    });

    test('Should not subscribe multiple times to the same LiveData', () {
      observer.subscribe(counter);
      observer.subscribe(counter);

      expect(observer.subscriptions.length, 1);
    });

    test('Should clear all subscriptions', () {
      observer.subscribe(counter);
      expect(observer.subscriptions.isNotEmpty, isTrue);

      observer.clear();
      expect(observer.subscriptions.isEmpty, isTrue);

      int callCount = 0;
      observer.update = () => callCount++;
      counter.value = 1;
      expect(callCount, 0);
    });

    test('Should automatically remove subscription when LiveData is disposed', () {
      observer.subscribe(counter);
      expect(observer.subscriptions.containsKey(counter), isTrue);

      counter.dispose();
      
      // onDone in stream is usually asynchronous, but let's check if our implementation handles it
      // Note: In current implementation, onDone removes the subscription.
      expect(observer.subscriptions.containsKey(counter), isFalse);
    });

    test('Should stop observing after observer itself is cleared', () {
      observer.subscribe(counter);
      int callCount = 0;
      observer.update = () => callCount++;

      observer.clear();
      counter.value = 99;
      
      expect(callCount, 0);
    });
  });
}

class MockLiveObserver with Debugger, LiveObserver {
  VoidCallback? update;

  @override
  void onUpdate() {
    update?.call();
  }

  @override
  String get debugId => 'mock';
}
