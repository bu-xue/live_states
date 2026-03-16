import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class ParentVM extends LiveViewModel<ParentWidget> with Refreshable {
  int refreshCount = 0;

  @override
  Future<bool> onRefresh() async {
    refreshCount++;
    return true;
  }
}

class ParentWidget extends LiveWidget {
  final Widget child;
  const ParentWidget({super.key, required this.child});

  @override
  ParentVM createViewModel() => ParentVM();

  @override
  Widget build(BuildContext context, ParentVM viewModel) => child;
}

class ChildVM extends LiveViewModel<ChildWidget> with Refreshable {
  int refreshCount = 0;

  @override
  Future<bool> onRefresh() async {
    refreshCount++;
    return true;
  }
}

class ChildWidget extends LiveWidget {
  const ChildWidget({super.key});

  @override
  ChildVM createViewModel() => ChildVM();

  @override
  Widget build(BuildContext context, ChildVM viewModel) => const SizedBox();
}

void main() {
  group('Refreshable Tests', () {
    testWidgets('Should trigger cascaded refresh from parent to children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentWidget(
            child: ChildWidget(),
          ),
        ),
      );

      final parentElement = tester.element(find.byType(ParentWidget)) as LiveElement;
      final childElement = tester.element(find.byType(ChildWidget)) as LiveElement;

      final parentVM = parentElement.viewModel as ParentVM;
      final childVM = childElement.viewModel as ChildVM;

      expect(parentVM.refreshCount, 0);
      expect(childVM.refreshCount, 0);

      // 触发父节点刷新
      final success = await parentVM.refresh();

      expect(success, isTrue);
      expect(parentVM.refreshCount, 1);
      expect(childVM.refreshCount, 1, reason: 'Child onRefresh should be called when parent refresh() is triggered');
    });

    testWidgets('Should handle deeply nested refreshable nodes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentWidget(
            // 中间隔一层非 Refreshable 的普通 Widget
            child: Center(
              child: ChildWidget(),
            ),
          ),
        ),
      );

      final parentElement = tester.element(find.byType(ParentWidget)) as LiveElement;
      final childElement = tester.element(find.byType(ChildWidget)) as LiveElement;

      final parentVM = parentElement.viewModel as ParentVM;
      final childVM = childElement.viewModel as ChildVM;

      await parentVM.refresh();

      expect(parentVM.refreshCount, 1);
      expect(childVM.refreshCount, 1, reason: 'Deeply nested child should still be refreshed');
    });
  });
}
