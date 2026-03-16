import 'advanced_node.dart';

/// Mixin that makes the current [LiveViewModel] a refreshable node.
///
/// When a [LiveViewModel] uses this mixin, it gains [refresh] and [onRefresh] methods.
/// When the current [LiveViewModel] and all its children need to be reloaded,
/// [refresh] can be called. This triggers [onRefresh] for the current node
/// and all its [Refreshable] child nodes in a top-down order.
mixin Refreshable on AdvancedNode {
  /// Callback method for refreshing the current node.
  Future<bool> onRefresh();

  /// Triggers the refresh process for the current node and all its child nodes.
  Future<bool> refresh() async {
    final result = await Future.wait([
      onRefresh(),
      ..._subRefresh(children.values.toList()),
    ]);
    return !result.any((refreshSuccess) => !refreshSuccess);
  }

  List<Future> _subRefresh(List<AdvancedNode> children) {
    final result = <Future>[];
    for (var e in children) {
      if (e is Refreshable) {
        result.add(e.onRefresh());
      }
      result.addAll(_subRefresh(e.children.values.toList()));
    }
    return result;
  }
}
