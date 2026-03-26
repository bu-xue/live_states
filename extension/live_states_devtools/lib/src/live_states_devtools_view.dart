import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';
import 'package:live_states_devtools/src/states_provider.dart';
import 'widgets/data_graph_view.dart';
import 'widgets/widget_tree_view.dart';


class LiveStatesDevToolsView extends StatelessWidget {
  const LiveStatesDevToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LiveProvider.create(
        builder: (context) {
          return const Scaffold(
            body: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: WidgetTreeView(),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  flex: 7,
                  child: DataGraphView(),
                ),
              ],
            ),
          );
        },
        creator: () => StatesProvider());
  }
}
