import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class TestLiveViewModel extends LiveViewModel<TestLiveWidget> {
  late final counter = LiveData<int>(0, owner);
  late final titleLength = LiveCompute<int>(owner, () => widget.title.length);

  bool initCalled = false;
  bool disposeCalled = false;
  String? lastTitle;
  String? oldTitle;
  Color? themeColor;

  @override
  void init() {
    super.init();
    initCalled = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColor = Theme.of(context).primaryColor;
  }

  @override
  void dispose() {
    disposeCalled = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(TestLiveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldTitle = oldWidget.title;
    lastTitle = widget.title;
  }

  void increment() => counter.value++;
}

class TestLiveWidget extends LiveWidget {
  final String title;
  const TestLiveWidget({super.key, this.title = ''});

  @override
  TestLiveViewModel createViewModel() => TestLiveViewModel();

  @override
  Widget build(BuildContext context, covariant TestLiveViewModel viewModel) {
    return Column(
      children: [
        Text('Title: $title'),
        Text('Length: ${viewModel.titleLength.value}'),
        LiveScope.vm<TestLiveViewModel>(
          builder: (context, vm, child) => Text('Counter: ${vm.counter.value}'),
        ),
        ElevatedButton(onPressed: viewModel.increment, child: const Text('Add')),
      ],
    );
  }
}

class ErrorVM extends LiveViewModel<ErrorWidget> {
  @override
  void init() {
    Theme.of(context);
    super.init();
  }
}

class ErrorWidget extends LiveWidget {
  const ErrorWidget({super.key});
  @override
  ErrorVM createViewModel() => ErrorVM();
  @override
  Widget build(BuildContext context, ErrorVM viewModel) => const SizedBox();
}

late BuildContext _savedContext;

class DisposeTestVM extends LiveViewModel<DisposeTestWidget> {
  @override
  void init() {
    super.init();
    _savedContext = context;
  }
}

class DisposeTestWidget extends LiveWidget {
  const DisposeTestWidget({super.key});
  @override
  DisposeTestVM createViewModel() => DisposeTestVM();
  @override
  Widget build(BuildContext context, DisposeTestVM viewModel) => const SizedBox();
}

void main() {
  group('LiveWidget & ViewModel Detailed Tests', () {
    testWidgets('Should trigger didChangeDependencies and access Theme safely', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(primaryColor: Colors.red),
        home: const TestLiveWidget(title: 'v1'),
      ));

      final LiveElement element = tester.element(find.byType(TestLiveWidget));
      final viewModel = element.viewModel as TestLiveViewModel;

      expect(viewModel.themeColor, Colors.red);
    });

    testWidgets('LiveCompute should respond to Widget property changes and verify oldWidget', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: TestLiveWidget(key: key, title: 'abc'),
      ));

      expect(find.text('Length: 3'), findsOneWidget);

      // 更新 Widget 属性
      await tester.pumpWidget(MaterialApp(
        home: TestLiveWidget(key: key, title: 'abcdef'),
      ));

      final LiveElement element = tester.element(find.byKey(key));
      final viewModel = element.viewModel as TestLiveViewModel;

      expect(find.text('Length: 6'), findsOneWidget);
      expect(viewModel.oldTitle, 'abc', reason: 'oldWidget parameter should point to previous instance');
      expect(viewModel.lastTitle, 'abcdef', reason: 'viewModel.widget should point to current instance');
    });

    testWidgets('Should throw error if accessing InheritedWidget in init()', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ErrorWidget()));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception.toString(), contains('was called before ErrorVM.init() completed'));
    });

    testWidgets('Should throw error if accessing InheritedWidget after dispose()', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DisposeTestWidget()));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(() => Theme.of(_savedContext), throwsA(isA<FlutterError>().having(
        (e) => e.message, 'message', contains('deactivated widget')
      )));
    });

    testWidgets('context.vm<T>() extension should find ancestor ViewModel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestLiveWidget(title: 'Root'),
          ),
        ),
      );

      final innerTextFinder = find.text('Title: Root');
      final BuildContext innerContext = tester.element(innerTextFinder);
      
      final foundVM = innerContext.vm<TestLiveViewModel>();
      expect(foundVM, isNotNull);
      expect(foundVM!.widget.title, 'Root');
    });
  });
}
