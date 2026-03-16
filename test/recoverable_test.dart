import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class RecoverableVM extends LiveViewModel<RecoverableWidget> with Recoverable {
  late final counter = LiveData<int>(0, owner);

  @override
  String get storageKey => 'counter_key';

  @override
  Map<String, dynamic>? storage() {
    return {'count': counter.value};
  }

  @override
  void recover(Map<String, dynamic>? storage) {
    if (storage != null) {
      counter.value = storage['count'] ?? 0;
    }
  }
}

class RecoverableWidget extends LiveWidget {
  const RecoverableWidget({super.key});

  @override
  RecoverableVM createViewModel() => RecoverableVM();

  @override
  Widget build(BuildContext context, RecoverableVM viewModel) {
    return LiveScope.vm<RecoverableVM>(
      builder: (context, vm, child) => Text('Count: ${vm.counter.value}'),
    );
  }
}

class AnotherVM extends LiveViewModel<AnotherWidget> with Recoverable {
  @override
  String get storageKey => 'another_key';
  
  @override
  Map<String, dynamic>? storage() => {'data': 'secret'};
}

class AnotherWidget extends LiveWidget {
  const AnotherWidget({super.key});
  @override
  AnotherVM createViewModel() => AnotherVM();
  @override
  Widget build(BuildContext context, AnotherVM viewModel) => const SizedBox();
}

void main() {
  group('Recoverable Tests', () {
    setUp(() {
      Recoverable.resetForTest();
    });

    tearDown(() {
      Recoverable.resetForTest();
    });

    testWidgets('Should save and recover state across rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RecoverableWidget()));
      final element = tester.element(find.byType(RecoverableWidget)) as LiveElement;
      final vm = element.viewModel as RecoverableVM;
      
      vm.counter.value = 99;
      await tester.pump();
      expect(find.text('Count: 99'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      
      await tester.pumpWidget(const MaterialApp(home: RecoverableWidget()));
      
      expect(find.text('Count: 99'), findsOneWidget);
    });

    testWidgets('Should isolate states by storageKey', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AnotherWidget()));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      await tester.pumpWidget(const MaterialApp(home: RecoverableWidget()));
      expect(find.text('Count: 0'), findsOneWidget);
    });
  });
}
