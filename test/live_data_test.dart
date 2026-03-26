import 'package:flutter/foundation.dart';
import 'package:live_states/live_states.dart';
import 'package:test/test.dart';

void main() {
  const initialValue = 42;
  group('LiveData tester', () {
    late LiveOwner owner;
    late LiveData<int> liveData;

    setUp(() {
      owner = LiveOwner.test()..vmDebugId = 'vm';
      liveData = LiveData<int>(initialValue, owner, debugName: 'testLiveData');
    });

    tearDown(() {
      owner.dispose();
    });

    test('Initializes with correct values', () {
      expect(liveData.value, initialValue);
      expect(liveData.debugName, 'testLiveData');
      expect(liveData.owner, owner);
    });

    test('onUpdateValue callback should be triggered', () {
      int? oldVal;
      int? newVal;
      
      final dataWithCallback = LiveData<int>(
        1, 
        owner, 
        onUpdateValue: (o, n) {
          oldVal = o;
          newVal = n;
        },
      );

      dataWithCallback.value = 2;
      expect(oldVal, 1);
      expect(newVal, 2);
    });

    test('onlyValue should NOT trigger observation or notification or callback', () {
      int notifyCount = 0;
      int callbackCount = 0;
      
      final data = LiveData<int>(1, owner, onUpdateValue: (_, __) => callbackCount++);
      data.addListener(() => notifyCount++);
      
      // 1. Setting onlyValue should not trigger notify or callback
      data.onlyValue = 999;
      expect(notifyCount, 0);
      expect(callbackCount, 0);
      expect(data.onlyValue, 999);
      
      // 2. Accessing onlyValue in LiveCompute should not establish dependency
      final compute = LiveCompute(owner, () => data.onlyValue > 100);
      expect(compute.value, isTrue);
      
      data.value = 0; // Update value to trigger notifications
      // If dependency was established, compute would become false.
      // But since onlyValue was used, it should not update.
      expect(compute.value, isTrue, reason: 'onlyValue should not be tracked as dependency');
    });

    test('Notifies listeners on value change', () {
      int callCount = 0;
      liveData.addListener(() => callCount++);
      
      liveData.value++;
      expect(callCount, 1);
      expect(liveData.value, initialValue + 1);
    });

    test('Does not notify if verifyDataChange is enabled and value is same', () {
      int callCount = 0;
      liveData.addListener(() => callCount++);
      
      liveData.value = initialValue; // No change
      expect(callCount, 0);
    });

    test('Streams values correctly using emits', () {
      expect(liveData.stream, emitsInOrder([43, 44]));
      
      liveData.value = 43;
      liveData.value = 44;
    });

    test('Handles ChangeNotifier as value (Binding test)', () {
      final innerNotifier = ValueNotifier<int>(0);
      final wrapper = LiveData<ValueNotifier<int>>(innerNotifier, owner);
      
      int notifyCount = 0;
      wrapper.addListener(() => notifyCount++);
      
      innerNotifier.value = 100;
      expect(notifyCount, 1);
      
      final newNotifier = ValueNotifier<int>(200);
      wrapper.value = newNotifier;
      expect(notifyCount, 2);
      
      innerNotifier.value = 300;
      expect(notifyCount, 2);
      
      newNotifier.value = 400;
      expect(notifyCount, 3);
    });

    test('Dispose through owner', () {
      owner.dispose();
      expect(() => liveData.notifyListeners(), throwsA(isA<AssertionError>()));
    });
  });
}
