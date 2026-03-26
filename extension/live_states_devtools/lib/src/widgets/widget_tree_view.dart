import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';
import '../models.dart';
import '../states_provider.dart';

class WidgetTreeView extends StatelessWidget {
  const WidgetTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    final states = context.provider<StatesProvider>()!;

    return Column(
      children: [
        const AreaPaneHeader(title: Text('Widget Tree')),
        Expanded(
          child: LiveScope.free(builder: (context, child) {
            return TreeView.simpleTyped<dynamic, ViewNode>(
              tree: states.widgetTree.value,
              showRootNode: true,
              builder: (BuildContext context, ViewNode node) {
                final isSelected = states.selectedWidgetId.value == node.id;
                final typeColor = _getTypeColor(node.type);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => states.selectWidget(node.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).highlightColor : null,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        children: [
                          if (node.type != ViewType.root)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.type.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).disabledColor,
                                    ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              node.debugName ?? node.id,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
  Color _getTypeColor(ViewType type) {
    switch (type) {
      case ViewType.provider:
        return Colors.indigoAccent;
      case ViewType.widget:
        return Colors.teal;
      case ViewType.scope:
        return Colors.deepOrangeAccent;
      case ViewType.root:
        return Colors.blueGrey;
    }
  }
}

