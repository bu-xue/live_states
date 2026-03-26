part of 'data_graph_view.dart';

mixin DataGraphViewStates on LiveStates {}

const double _levelW = 220.0; // 层级间距（水平）
const double _gapH = 100.0; // 节点间距（垂直）
const Duration _nodeDur = Duration(milliseconds: 100);
const Duration _edgeDur = Duration(milliseconds: 150);

class AnimationHelper {
  final AnimationController controller;
  late final LiveData<double> animateValue;
  Completer? completer;

  AnimationHelper(
      {required LiveOwner owner, required TickerProvider vsync, required Duration duration})
      : animateValue = LiveData(0.0, owner),
        controller = AnimationController(vsync: vsync, duration: duration) {
    controller.addListener(() {
      animateValue.value = controller.value;
    });
  }

  double get value => animateValue.value;

  /// 返回当前动画的 Future，如果未在动画则返回已完成的 Future
  Future<void> get done => completer?.future ?? Future.value();

  void ready() {
    completer = Completer();
  }

  Future<void> forwardThenReset({double? from}) async {
    await controller.forward(from: from);
    controller.reset();
    completer?.complete();
  }

  Future<void> dispose() async {
    controller.dispose();
    animateValue.dispose();
  }
}

class DataGraphViewVM extends LiveViewModel<DataGraphView>
    with DataGraphViewStates, TickerProviderMixin {
  Graph? get graph => context.provider<StatesProvider>()?.showGraph.value;

  late final LiveCompute<bool> hasNodes =
      LiveCompute(owner, () => graph?.nodes.isNotEmpty ?? false);

  late final LiveCompute<Map<Node, Offset>> positions =
      LiveCompute(owner, () => graph?.calculatePositions() ?? {});

  late final Map<Node, AnimationHelper> nodesCtrl = {};

  late final Map<Edge, AnimationHelper> edgesCtrl = {};

  StreamSubscription? _dataSub;
  StreamSubscription? _notifySub;
  StreamSubscription? _graphSub;

  @override
  void init() {
    super.init();
    _subscribeToGraph();
    _subscribeToStreams();
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _notifySub?.cancel();
    _graphSub?.cancel();
    for (var h in [...nodesCtrl.values, ...edgesCtrl.values]) {
      h.dispose();
    }
    nodesCtrl.clear();
    edgesCtrl.clear();
    super.dispose();
  }

  void selectNode(Node node) {
    context.provider<StatesProvider>()?.selectDataNode(node.id);
  }

  void _handleGraphChanged(Graph? graph) {
    final nodes = graph?.nodes ?? {};
    final edges = graph?.edges ?? {};

    // 同步节点控制器
    nodesCtrl.removeWhere((node, helper) {
      if (!nodes.contains(node)) {
        helper.dispose();
        return true;
      }
      return false;
    });
    for (final node in nodes) {
      nodesCtrl.putIfAbsent(
          node, () => AnimationHelper(owner: owner, vsync: this, duration: _nodeDur));
    }

    // 同步边控制器
    edgesCtrl.removeWhere((edge, helper) {
      if (!edges.contains(edge)) {
        helper.dispose();
        return true;
      }
      return false;
    });
    for (final edge in edges) {
      edgesCtrl.putIfAbsent(
          edge, () => AnimationHelper(owner: owner, vsync: this, duration: _edgeDur));
    }
  }

  void _subscribeToGraph() {
    final provider = context.provider<StatesProvider>();
    if (provider == null) return;
    _graphSub = provider.showGraph.listen(_handleGraphChanged);
    // 初始化执行一次
    _handleGraphChanged(graph);
  }

  void _handleNodeAnimation(Node node) {
    final helper = nodesCtrl[node];
    if (helper == null) return;
    helper.ready();
    Future.delayed(Duration.zero, () async {
      // 依赖检查：等待所有流入该节点的边动画完成 (数据送达)
      await Future.wait(node.subscriptions
          .map((s) => Edge(observer: node, subject: s))
          .map((e) => edgesCtrl[e]?.done)
          .nonNulls);
      await nodesCtrl[node]?.forwardThenReset();
    });
  }

  void _handleEdgeAnimation(Edge edge) {
    final helper = edgesCtrl[edge];
    if (helper == null) return;
    helper.ready();
    Future.delayed(Duration.zero, () async {
      // 依赖检查：等待源节点的脉冲动画完成 (数据产生)
      await nodesCtrl[edge.subject]?.done;
      await edgesCtrl[edge]?.forwardThenReset();
    });
  }

  void _subscribeToStreams() {
    _dataSub = context
        .provider<StatesProvider>()
        ?.dataChangedEventStream
        .asyncMap((edge) => Future.delayed(Duration.zero, () => edge))
        .listen(_handleNodeAnimation);
    _notifySub = context
        .provider<StatesProvider>()
        ?.notifyHappenedEventStream
        .asyncMap((edge) => Future.delayed(Duration.zero, () => edge))
        .listen(_handleEdgeAnimation);
  }
}

extension on Graph {
  Map<Node, Offset>? calculatePositions() {
    if (this.nodes.isEmpty) return null;
    final positions = <Node, Offset>{};
    final nodes = [...this.nodes];

    final outEdges = <Node, List<Node>>{};
    final inDegree = <Node, int>{};
    for (final n in nodes) {
      outEdges[n] = [];
      inDegree[n] = 0;
    }
    for (final e in edges) {
      outEdges[e.subject]!.add(e.observer);
      inDegree[e.observer] = (inDegree[e.observer] ?? 0) + 1;
    }

    final level = <Node, int>{for (final n in nodes) n: 0};
    final queue = <Node>[...nodes.where((n) => inDegree[n] == 0)];

    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final child in outEdges[cur]!) {
        final candidate = level[cur]! + 1;
        if (candidate > level[child]!) {
          level[child] = candidate;
        }
        inDegree[child] = inDegree[child]! - 1;
        if (inDegree[child] == 0) {
          queue.add(child);
        }
      }
    }

    final byLevel = <int, List<Node>>{};
    for (final n in nodes) {
      byLevel.putIfAbsent(level[n]!, () => []).add(n);
    }

    for (final entry in byLevel.entries) {
      final l = entry.key;
      final ns = entry.value;
      final totalH = (ns.length - 1) * _gapH;
      for (int i = 0; i < ns.length; i++) {
        // 水平布局：x 坐标由层级决定，y 坐标在该层内居中分布
        positions[ns[i]] = Offset(l * _levelW, -totalH / 2 + i * _gapH);
      }
    }
    return positions;
  }
}
