import 'dart:async';

import 'package:dart_scope_functions/dart_scope_functions.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:live_states/live_states.dart';

import 'models.dart';

mixin States on LiveStates {
  late final rootWidgetNode = ViewNode.root();
  late final widgetNodes = {rootWidgetNode.id: rootWidgetNode};
  late final widgetTree = LiveData(rootWidgetNode, owner);

  late final Map<String, Node> dataNodes = {};

  late final selectedWidgetId = LiveData<String?>(null, owner);
  late final selectedDataNodeId = LiveData<String?>(null, owner);

  late final showGraph = LiveCompute<Graph?>(owner, () => _updateGraph());

  Graph? _updateGraph() {
    final selectedDataNode = selectedDataNodeId.value?.let((id) => dataNodes[id]);
    final selectedWidget = selectedWidgetId.value?.let((id) => widgetNodes[id]);
    if (selectedDataNode == null && selectedWidget == null) {
      return null;
    }
    if (selectedDataNode != null || selectedWidget?.type == ViewType.scope) {
      final id = selectedDataNode?.id ?? selectedWidget!.id;
      final node = dataNodes[id];
      if (node == null) {
        return null;
      }
      return Graph.fromNodes({node});
    } else {
      // 展示 Widget 下的所有数据节点及其内部关系
      final nIds = selectedWidget!.dataNodeIds;
      return Graph.fromNodes(nIds.map((id) => dataNodes[id]).nonNulls.toSet());
    }
  }
}

class StatesProvider extends LiveProvider with States {
  StreamSubscription? serviceSubscription;

  final _dataChangedEventStreamController = StreamController<Node>.broadcast();
  final _notifyHappenedEventStreamController = StreamController<Edge>();

  Stream<Node> get dataChangedEventStream => _dataChangedEventStreamController.stream;

  Stream<Edge> get notifyHappenedEventStream => _notifyHappenedEventStreamController.stream;

  late final Map<Edge, Timer> waitingUnsubscript = {};

  @override
  void init() {
    super.init();
    _listenExtensionEvent();
  }

  @override
  void dispose() {
    serviceSubscription?.cancel();
    _dataChangedEventStreamController.close();
    super.dispose();
  }

  void _listenExtensionEvent() async {
    final service = await serviceManager.onServiceAvailable;
    serviceSubscription = service.onExtensionEvent.listen((event) {
      final kind = event.extensionKind ?? '';
      final data = event.extensionData?.data ?? {};
      if (kind.startsWith('live_states:')) {
        _handleEvent(kind, data);
      }
    });
  }

  void _handleEvent(String kind, Map<String, dynamic> data) {
    switch (kind) {
      case 'live_states:widget_mount':
        final newNode = ViewNode.fromJSON(data);
        final parent = widgetNodes[newNode.parentId];
        if (parent != null) {
          widgetNodes[newNode.id] = newNode;
          parent.add(newNode);
          widgetTree.notify();
          if (newNode.type == ViewType.scope) {
            dataNodes[newNode.id] = Node(
              id: newNode.id,
              type: NodeType.scope,
              debugName: newNode.debugName,
              parent: parent,
            );
            showGraph.update();
          }
        }

        break;

      case 'live_states:widget_unmount':
        final id = data['id'] as String;
        final node = widgetNodes.remove(id);
        if (node?.parentId != null) widgetNodes[node!.parentId]?.remove(node);
        widgetTree.notify();
        dataNodes.remove(id)?.let((node){
          for (var observer in node.observers) {
            dataNodes[observer.id]?.subscriptions.remove(node);
          }
          for (var subject in node.subscriptions) {
            dataNodes[subject.id]?.observers.remove(node);
          }
          showGraph.update();
        });
        break;

      case 'live_states:node_created':
        final parentId = data['parentId'] as String?;
        final parent = widgetNodes[parentId];
        if (parent != null) {
          final id = data['id'] as String;
          final type = NodeType.values.byName(data['type'] as String);
          final debugName = data['debugName'] as String?;
          final value = data['value']?.toString();
          dataNodes[id] = Node(
            id: id,
            type: type,
            debugName: debugName,
            parent: parent,
            currentValue: value,
          );
          parent.dataNodeIds.add(id);
          showGraph.update();
        }
        break;

      case 'live_states:node_disposed':
        final id = data['id'] as String;
        dataNodes.remove(id)?.let((node) {
          node.parent.dataNodeIds.remove(id);
          for (var observer in node.observers) {
            dataNodes[observer.id]?.subscriptions.remove(node);
          }
          for (var subject in node.subscriptions) {
            dataNodes[subject.id]?.observers.remove(node);
          }
        });
        showGraph.update();
        break;

      case 'live_states:subscription_created':
        final observerId = data['observerId'] as String;
        final subjectId = data['subjectId'] as String;
        final observer = dataNodes[observerId];
        final subject = dataNodes[subjectId];
        if (observer != null && subject != null) {
          final edge = Edge(observer: observer, subject: subject);
          final unsubscriber = waitingUnsubscript[edge];
          if (unsubscriber != null) {
            unsubscriber.cancel();
          } else {
            observer.subscriptions.add(subject);
            subject.observers.add(observer);
            showGraph.update();
          }
        }
        break;

      case 'live_states:subscription_disposed':
        final observerId = data['observerId'] as String;
        final subjectId = data['subjectId'] as String;
        final observer = dataNodes[observerId];
        final subject = dataNodes[subjectId];
        if (observer != null && subject != null) {
          waitingUnsubscript[Edge(observer: observer, subject: subject)] =
              Timer(const Duration(milliseconds: 100), () {
            final observer = dataNodes[observerId];
            final subject = dataNodes[subjectId];
            if (observer != null && subject != null) {
              observer.subscriptions.remove(subject);
              subject.observers.remove(observer);
              showGraph.update();
            }
          });
        }
        break;

      case 'live_states:data_changed':
        final id = data['debugId'] as String;
        final value = data['value']?.toString();
        dataNodes[id]?.let((dataNode) {
          dataNode.currentValue = value;
          _dataChangedEventStreamController.add(dataNode);
        });
        break;

      case 'live_states:notify_happened':
        final senderId = data['senderId'] as String;
        final recipientId = data['recipientId'] as String;
        final sender = dataNodes[senderId];
        final recipient = dataNodes[recipientId];
        if (sender != null &&
            recipient != null &&
            sender.observers.contains(recipient) &&
            recipient.subscriptions.contains(sender)) {
          _notifyHappenedEventStreamController.add(Edge(subject: sender, observer: recipient));
        }
        break;
    }
  }

  void selectWidget(String? id) {
    selectedWidgetId.value = id;
    selectedDataNodeId.value = null;
  }

  void selectDataNode(String? id) {
    selectedDataNodeId.value = id;
  }
}
