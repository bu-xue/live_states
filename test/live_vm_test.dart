import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class TestLiveViewModel extends LiveViewModel<TestLiveWidget> {
  int activateCount = 0;
  int deactivateCount = 0;
  int dependencyChangeCount = 0;
  bool disposeCalled = false;

  @override
  void activate() {
    super.activate();
    activateCount++;
  }

  @override
  void deactivate() {
    deactivateCount++;
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dependencyChangeCount++;
  }

  @override
  void dispose() {
    disposeCalled = true;
    super.dispose();
  }
}

class TestLiveWidget extends LiveWidget {
  final Widget? child;
  const TestLiveWidget({super.key, this.child});

  @override
  TestLiveViewModel createViewModel() => TestLiveViewModel();

  @override
  Widget build(BuildContext context, covariant TestLiveViewModel viewModel) {
    return child ?? const SizedBox.shrink();
  }
}

void main() {
  group('LiveViewModel Advanced Tests', () {
    testWidgets('Should trigger didChangeDependencies', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestLiveWidget()));
      
      final LiveElement element = tester.element(find.byType(TestLiveWidget));
      final viewModel = element.viewModel as TestLiveViewModel;

      expect(viewModel.dependencyChangeCount, 1);
    });

    testWidgets('AdvancedNode should build and clean parent-child relationship', (tester) async {
      final childKey = UniqueKey();
      
      // 1. Mount parent and child
      await tester.pumpWidget(
        MaterialApp(
          home: TestLiveWidget(
            child: TestLiveWidget(key: childKey),
          ),
        ),
      );

      final parentElement = tester.element(find.byType(TestLiveWidget).first) as LiveElement;
      final childElement = tester.element(find.byKey(childKey)) as LiveElement;

      final parentVM = parentElement.viewModel;
      final childVM = childElement.viewModel;

      expect(childVM.parent, parentVM);
      expect(parentVM.children.containsValue(childVM), isTrue);

      // 2. Unmount child only
      await tester.pumpWidget(
        const MaterialApp(
          home: TestLiveWidget(
            child: SizedBox(),
          ),
        ),
      );

      expect(parentVM.children.containsValue(childVM), isFalse, reason: 'Child VM should be removed from parent children map on unmount');
    });

    testWidgets('Should trigger activate and deactivate via GlobalKey reparenting', (tester) async {
      final key = GlobalKey();
      
      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            Positioned(key: const Key('pos1'), child: TestLiveWidget(key: key)),
            const SizedBox(),
          ],
        ),
      ));

      final LiveElement element = tester.element(find.byKey(key));
      final viewModel = element.viewModel as TestLiveViewModel;

      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            const SizedBox(),
            Positioned(key: const Key('pos2'), child: TestLiveWidget(key: key)),
          ],
        ),
      ));

      expect(viewModel.deactivateCount, 1);
      expect(viewModel.activateCount, 1);
    });
  });
}
