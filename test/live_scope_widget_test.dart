import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class CounterVM extends LiveViewModel<CounterWidget> {
  late final counter = LiveData<int>(0, owner);
  int buildCount = 0;

  void increment() => counter.value++;
}

class CounterWidget extends LiveWidget {
  final Widget? child;
  const CounterWidget({super.key, this.child});

  @override
  CounterVM createViewModel() => CounterVM();

  @override
  Widget build(BuildContext context, CounterVM viewModel) {
    viewModel.buildCount++;
    return Column(
      children: [
        Text('Parent Build: ${viewModel.buildCount}', key: const Key('parent-build')),
        LiveScope.vm<CounterVM>(
          builder: (context, vm, child) {
            return Text('Count: ${vm.counter.value}', key: const Key('counter-text'));
          },
        ),
        ElevatedButton(
          onPressed: viewModel.increment,
          child: const Text('Increment'),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class InnerVM extends LiveViewModel<InnerWidget> {}

class InnerWidget extends LiveWidget {
  const InnerWidget({super.key});

  @override
  InnerVM createViewModel() => InnerVM();

  @override
  Widget build(BuildContext context, InnerVM viewModel) {
    final outerVM = context.vm<CounterVM>();
    return Text('Outer Count: ${outerVM?.counter.value}');
  }
}

class LifecycleProvider extends LiveProvider {}

void main() {
  testWidgets('LiveScope should only rebuild locally when LiveData changes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CounterWidget())));

    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('Parent Build: 1'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); 

    expect(find.text('Count: 1'), findsOneWidget);
    expect(find.text('Parent Build: 1'), findsOneWidget);
  });

  testWidgets('LiveScope should use explicitly provided viewModel', (WidgetTester tester) async {
    // 构造一个不属于 Widget 树祖先关系的 ViewModel
    final owner = LiveOwner.test();
    final manualVM = CounterVM()
      ..owner = owner
      ..counter.value = 88;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiveScope.vm<CounterVM>(
          viewModel: manualVM,
          builder: (context, vm, child) {
            return Text('Manual Count: ${vm.counter.value}');
          },
        ),
      ),
    ));

    expect(find.text('Manual Count: 88'), findsOneWidget);
    
    manualVM.counter.value = 99;
    await tester.pump();
    expect(find.text('Manual Count: 99'), findsOneWidget);
    
    owner.dispose();
  });

  testWidgets('LiveScope.child optimization test', (WidgetTester tester) async {
    int childBuildCount = 0;
    final owner = LiveOwner.test();
    final counter = LiveData<int>(0, owner);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiveScope.free(
          child: Builder(builder: (context) {
            childBuildCount++;
            return const Text('Static Child');
          }),
          builder: (context, child) {
            return Column(
              children: [
                Text('Data: ${counter.value}'),
                child!,
              ],
            );
          },
        ),
      ),
    ));

    expect(childBuildCount, 1);
    counter.value++;
    await tester.pump();

    expect(childBuildCount, 1, reason: 'The passed child should not be rebuilt by LiveScope');
    owner.dispose();
  });

  testWidgets('LiveScope.followParentUpdate: false should isolate from parent rebuilds', (WidgetTester tester) async {
    int scopeBuildCount = 0;
    final notifier = ValueNotifier(0);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, value, child) {
            return Column(
              children: [
                Text('Parent: $value'),
                LiveScope.free(
                  followParentUpdate: false,
                  builder: (context, child) {
                    scopeBuildCount++;
                    return const Text('Static Scope');
                  },
                ),
              ],
            );
          },
        ),
      ),
    ));

    expect(scopeBuildCount, 1);
    notifier.value++;
    await tester.pump();
    expect(scopeBuildCount, 1);
  });

  testWidgets('Nested LiveViewModel lookup test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CounterWidget(
            child: InnerWidget(),
          ),
        ),
      ),
    );

    expect(find.text('Outer Count: 0'), findsOneWidget);
  });
}
