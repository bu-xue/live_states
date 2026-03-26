import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';
import 'src/live_states_devtools_view.dart';

void main() {
  LiveStatesDebugger.enabled = false;
  runApp(const LiveStatesDevToolsExtension());
}

class LiveStatesDevToolsExtension extends StatelessWidget {
  const LiveStatesDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(
      child: MaterialApp(
        // 添加 MaterialApp
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: const LiveStatesDevToolsView(),
      ),
    );
  }
}
