import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class SingleTickerVM extends LiveViewModel<SingleTickerWidget> with SingleTickerProviderMixin {
  late AnimationController controller;

  @override
  void init() {
    super.init();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class SingleTickerWidget extends LiveWidget {
  const SingleTickerWidget({super.key});
  @override
  SingleTickerVM createViewModel() => SingleTickerVM();
  @override
  Widget build(BuildContext context, SingleTickerVM viewModel) => const SizedBox();
}

class MultiTickerVM extends LiveViewModel<MultiTickerWidget> with TickerProviderMixin {
  late AnimationController controller1;
  late AnimationController controller2;

  @override
  void init() {
    super.init();
    controller1 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    controller2 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }
}

class MultiTickerWidget extends LiveWidget {
  const MultiTickerWidget({super.key});
  @override
  MultiTickerVM createViewModel() => MultiTickerVM();
  @override
  Widget build(BuildContext context, MultiTickerVM viewModel) => const SizedBox();
}

class LeakySingleVM extends LiveViewModel<LeakySingleWidget> with SingleTickerProviderMixin {
  late AnimationController controller;
  @override
  void init() {
    super.init();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
  }
}

class LeakySingleWidget extends LiveWidget {
  const LeakySingleWidget({super.key});
  @override
  LeakySingleVM createViewModel() => LeakySingleVM();
  @override
  Widget build(BuildContext context, LeakySingleVM viewModel) => const SizedBox();
}

class LeakyMultiVM extends LiveViewModel<LeakyMultiWidget> with TickerProviderMixin {
  late AnimationController controller1;
  late AnimationController controller2;
  @override
  void init() {
    super.init();
    controller1 = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    controller2 = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
  }
}

class LeakyMultiWidget extends LiveWidget {
  const LeakyMultiWidget({super.key});
  @override
  LeakyMultiVM createViewModel() => LeakyMultiVM();
  @override
  Widget build(BuildContext context, LeakyMultiVM viewModel) => const SizedBox();
}

void main() {
  group('TickerProvider Tests', () {
    testWidgets('SingleTickerProviderMixin should provide ticker', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SingleTickerWidget()));
      final element = tester.element(find.byType(SingleTickerWidget)) as LiveElement;
      final vm = element.viewModel as SingleTickerVM;
      expect(vm.controller, isNotNull);
    });

    testWidgets('TickerProviderMixin should allow multiple tickers', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MultiTickerWidget()));
      final element = tester.element(find.byType(MultiTickerWidget)) as LiveElement;
      final vm = element.viewModel as MultiTickerVM;
      expect(vm.controller1, isNotNull);
      expect(vm.controller2, isNotNull);
    });

    testWidgets('TickerMode changes should be handled safely', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: false,
            child: SingleTickerWidget(key: key),
          ),
        ),
      );
      final element = tester.element(find.byKey(key)) as LiveElement;
      final vm = element.viewModel as SingleTickerVM;
      expect(vm.controller, isNotNull);
    });

    testWidgets('SingleTickerProviderMixin leak detection', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LeakySingleWidget()));
      final element = tester.element(find.byType(LeakySingleWidget)) as LiveElement;
      final vm = element.viewModel as LeakySingleVM;

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception.toString(), contains('was disposed with an active Ticker'));
      vm.controller.dispose();
    });

    testWidgets('TickerProviderMixin leak detection', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LeakyMultiWidget()));
      final element = tester.element(find.byType(LeakyMultiWidget)) as LiveElement;
      final vm = element.viewModel as LeakyMultiVM;

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception.toString(), contains('was disposed with an active Ticker'));
      
      vm.controller1.dispose();
      vm.controller2.dispose();
    });
  });
}
