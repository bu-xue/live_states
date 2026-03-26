import 'package:live_states/src/live/live_view.dart';
import 'package:test/test.dart';

void main() {
  group('ignoreObserver Tester', () {
    late LiveOwner owner;

    setUp(() {
      owner = LiveOwner.test()..vmDebugId = 'vm';
    });

    tearDown(() {
      owner.dispose();
    });

    test('ignoreObserver should prevent LiveCompute from tracking dependencies', () async {
      final data = LiveData<int>(0, owner, debugName: 'source-data');
      
      int computeCallCount = 0;
      final compute = LiveCompute(owner, () {
        computeCallCount++;
        final value = ignoreObserver(() => data.value);
        return value > 10;
      }, debugName: 'ignoring-compute');

      expect(compute.value, isFalse);
      expect(computeCallCount, 1);

      data.value = 100;
      await Future.delayed(Duration.zero); 

      expect(computeCallCount, 1);
      expect(compute.value, isFalse, reason: 'Value should remain false because the change was ignored');
    });

    test('IgnoreStream should isolate listener callbacks', () async {
      final data = LiveData<int>(0, owner);
      int observationCount = 0;

      // 在一个追踪 Zone 中监听 Stream
      final compute = LiveCompute(owner, () {
        data.listen((_) {
          // 这里的访问不应被追踪，因为 IgnoreStream 会 wrap 回调
          observationCount++;
          final _ = data.value;
        });
        return true;
      });

      expect(compute.value, isTrue);
      
      data.value = 1;
      await Future.delayed(Duration.zero);
      
      // 验证：Stream 监听器触发了，但没有导致 compute 重新运行（即没建立追踪关系）
      expect(observationCount, 1);
    });

    test('nested ignoreObserver should work correctly', () async {
      final data1 = LiveData<int>(0, owner);
      final data2 = LiveData<int>(0, owner);

      final compute = LiveCompute(owner, () {
        final v1 = data1.value;
        final v2 = ignoreObserver(() => data2.value);
        return v1 + v2 > 50;
      });

      expect(compute.value, isFalse);

      data2.value = 100;
      await Future.delayed(Duration.zero);
      expect(compute.value, isFalse); 

      data1.value = 1;
      await Future.delayed(Duration.zero); 
      expect(compute.value, isTrue);
    });
  });
}
