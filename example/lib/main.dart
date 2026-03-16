import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';

void main() {
  runApp(const MaterialApp(home: ExampleHome()));
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin{
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


class CounterVM extends LiveViewModel<ExampleHome> {
  // 1. Define states
  late final counter = LiveData<int>(0, owner, debugName: 'count');
  
  // 2. Computed state: only changes if result changes
  late final isEven = LiveCompute<bool>(owner, () => counter.value % 2 == 0);

  // 3. Action
  void increment() => counter.value++;
}

class ExampleHome extends LiveWidget {
  const ExampleHome({super.key});

  @override
  CounterVM createViewModel() => CounterVM();

  @override
  Widget build(BuildContext context, CounterVM viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('LiveStates Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            
            // Precise rebuild: only this scope updates when counter changes
            LiveScope.vm<CounterVM>(
              builder: (context, vm, child) {
                return Text(
                  '${vm.counter.value}',
                  style: Theme.of(context).textTheme.headlineLarge,
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Computed state usage
            LiveScope.vm<CounterVM>(
              builder: (context, vm, child) {
                return Text(
                  vm.isEven.value ? 'Even Number' : 'Odd Number',
                  style: TextStyle(color: vm.isEven.value ? Colors.green : Colors.orange),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
