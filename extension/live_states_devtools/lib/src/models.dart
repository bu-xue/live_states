import 'package:animated_tree_view/animated_tree_view.dart' as tree;
import 'package:flutter/foundation.dart';

enum ViewType { root, provider, widget, scope }

enum NodeType { scope, computed, livedata }

const rootId = 'root';

class ViewNode extends tree.TreeNode {
  final String id;
  final ViewType type;
  final String? debugName;
  final String? parentId;
  final Set<String> dataNodeIds = {};

  ViewNode({required this.id, required this.type, this.debugName, this.parentId, super.key})
      : super(data: debugName ?? id);

  factory ViewNode.fromJSON(Map<String, dynamic> json) {
    return ViewNode(
      id: json['id'],
      type: ViewType.values.byName(json['type']),
      debugName: json['debugName'],
      parentId: json['parentId'] ?? rootId,
    );
  }

  factory ViewNode.root() => ViewNode(id: rootId, type: ViewType.root, key: tree.INode.ROOT_KEY);
}

class Node {
  final String id;
  final NodeType type;
  final String? debugName;
  final ViewNode parent; // The WidgetNode it belongs to
  final Map<String, dynamic> extra;
  final Set<Node> subscriptions = {};
  final Set<Node> observers = {};

  String? currentValue;

  Node({
    required this.id,
    required this.type,
    this.debugName,
    required this.parent,
    this.currentValue,
    this.extra = const {},
  });

  // get 所有层级订阅者
  Set<Node> get allSubscriptions {
    final subs = <Node>{};
    for (var sub in subscriptions) {
      subs.add(sub);
      subs.addAll(sub.allSubscriptions);
    }
    return subs;
  }

  // get 所有层级观察者
  Set<Node> get allObservers {
    final obs = <Node>{};
    for (var ob in observers) {
      obs.add(ob);
      obs.addAll(ob.allObservers);
    }
    return obs;
  }

  Set<Edge> get allSubscriptionsEdges {
    final edges = <Edge>{};
    for (var sub in subscriptions) {
      edges.add(Edge(observer: this, subject: sub));
      edges.addAll(sub.allSubscriptionsEdges);
    }
    return edges;
  }

  Set<Edge> get allObserversEdges {
    final edges = <Edge>{};
    for (var obs in observers) {
      edges.add(Edge(observer: obs, subject: this));
      edges.addAll(obs.allObserversEdges);
    }
    return edges;
  }
}

class Edge {
  final Node observer;
  final Node subject;

  Edge({required this.observer, required this.subject});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Edge &&
          runtimeType == other.runtimeType &&
          observer == other.observer &&
          subject == other.subject;

  @override
  int get hashCode => Object.hash(observer, subject);
}

class Graph {
  final Set<Node> nodes = {};
  final Set<Edge> edges = {};

  Graph();

  void addNode({required Node node}) {
    nodes.add(node);
  }

  void addEdge({required Edge edge}) {
    edges.add(edge);
  }

  factory Graph.fromNodes(Set<Node> nodes) {
    final graph = Graph();
    graph.nodes.addAll(nodes);
    graph.nodes.addAll(nodes.expand((n) => n.allSubscriptions));
    graph.nodes.addAll(nodes.expand((n) => n.allObservers));
    graph.edges.addAll(nodes.expand((n) => n.allSubscriptionsEdges));
    graph.edges.addAll(nodes.expand((n) => n.allObserversEdges));
    return graph;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Graph &&
          runtimeType == other.runtimeType &&
          setEquals(nodes, other.nodes) &&
          setEquals(edges, other.edges);

  @override
  int get hashCode => Object.hash(nodes, edges);
}
