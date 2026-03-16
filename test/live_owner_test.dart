import 'package:live_states/live_states.dart';
import 'package:test/test.dart';

void main() {
  group('LiveOwner Tests', () {
    late LiveOwner owner;
    late LiveData<int> counter1;
    late LiveData<int> counter2;
    late LiveCompute<bool> compute;

    setUp(() {
      owner = LiveOwner.test();
      counter1 = LiveData(0, owner);
      counter2 = LiveData(0, owner);
      compute = LiveCompute(owner, () => counter1.value + counter2.value > 100,
          verifyDataChange: false);
    });

    tearDown(() {
      owner.dispose();
    });

    test('Should track LiveData registration automatically', () {
      expect(owner.containsName(counter1.name), isTrue);
      expect(owner.containsName(counter2.name), isTrue);
      expect(owner.containsName(compute.name), isTrue);
    });

    test('Should remove registration when LiveData is disposed', () {
      counter1.dispose();
      expect(owner.containsName(counter1.name), isFalse);
    });

    test('didUpdateWidget should force re-compute of LiveCompute', () {
      expect(compute.value, isFalse);
      counter1.onlyValue = 200; 
      
      int notifyCount = 0;
      compute.addListener(() => notifyCount++);

      owner.didUpdateWidget();
      
      expect(notifyCount, 1);
      expect(compute.value, isTrue);
    });

    test('dispose should clear all managed data safely', () {
      final name1 = counter1.name;
      owner.dispose();
      expect(owner.containsName(name1), isFalse);
      expect(() => counter1.notifyListeners(), throwsA(isA<AssertionError>()));
    });

    test('Should handle multiple dispose calls safely', () {
      owner.dispose();
      // Second call should not throw
      expect(() => owner.dispose(), returnsNormally);
    });
  });
}
