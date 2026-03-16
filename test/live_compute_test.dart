import 'package:flutter/foundation.dart';
import 'package:live_states/live_states.dart';
import 'package:test/test.dart';

void main() {
  group('LiveCompute tester', () {
    late LiveOwner owner;
    late LiveData<int> data1;
    late LiveData<int> data2;
    late LiveCompute<bool> compute;

    setUp(() {
      owner = LiveOwner.test();
      data1 = LiveData<int>(0, owner, debugName: 'count1');
      data2 = LiveData<int>(1, owner, debugName: 'count2');
      compute = LiveCompute(
        owner,
        () => data1.value + data2.value > 100,
        debugName: 'computeTest',
      );
    });

    tearDown(() {
      owner.dispose();
    });

    test('Initial value is correctly computed', () {
      expect(compute.value, isFalse);
    });

    test('Updates when dependencies change', () {
      int callCount = 0;
      compute.addListener(() => callCount++);

      data1.value = 60;
      data2.value = 50;
      
      expect(callCount, 1);
      expect(compute.value, isTrue);
    });

    test('LiveCompute onUpdateValue callback', () {
      bool? lastOld;
      bool? lastNew;
      final computeWithCB = LiveCompute<bool>(
        owner,
        () => data1.value > 10,
        onUpdateValue: (o, n) {
          lastOld = o;
          lastNew = n;
        },
      );

      expect(computeWithCB.value, isFalse);
      data1.value = 20;
      expect(lastOld, isFalse);
      expect(lastNew, isTrue);
    });

    test('Filters out unnecessary updates (verifyDataChange)', () {
      int callCount = 0;
      compute.addListener(() => callCount++);
      data1.value = 10;
      data2.value = 20;
      expect(callCount, 0);
    });

    test('LiveCompute with verifyDataChange: false should always notify', () {
      int notifyCount = 0;
      final forceCompute = LiveCompute<int>(owner, () => data1.value * 0, verifyDataChange: false);
      forceCompute.addListener(() => notifyCount++);
      
      expect(forceCompute.value, 0);
      data1.value = 10; 
      expect(notifyCount, 1, reason: 'Should notify even if computed value is same when verifyDataChange is false');
    });

    test('Handles nullable types and null return values', () {
      final nullableData = LiveData<int?>(null, owner);
      final nullableCompute = LiveCompute<String?>(
        owner,
        () => nullableData.value == null ? 'None' : 'Some',
      );

      expect(nullableCompute.value, 'None');
      nullableData.value = 10;
      expect(nullableCompute.value, 'Some');
    });

    test('Throws error on manual assignment', () {
      expect(() => compute.value = true, throwsA(isA<FlutterError>()));
    });
  });
}
