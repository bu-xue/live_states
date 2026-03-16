import 'package:meta/meta.dart';
import '../live/live_view.dart';
import 'advanced_node.dart';

const _childrenStorageKey = '_childrenStorageKey';

/// Mixin that makes the current [LiveViewModel] a recoverable node.
mixin Recoverable on AdvancedNode {
  late final Map<String, Map<String, dynamic>> _childrenStates = {};

  /// Unique key for storing the node's state.
  String get storageKey;

  /// Callback for storing state.
  Map<String, dynamic>? storage() => null;

  /// Callback for recovering state.
  void recover(Map<String, dynamic>? storage) {}

  Recoverable? _parentRecoverable;

  Map<String, Map<String, dynamic>> get _parentChildrenStates =>
      _parentRecoverable?._childrenStates ?? _topChildrenStates;

  @override
  void mountNode() {
    super.mountNode();
    var node = parent;
    while(node != null) {
      if(node is Recoverable) {
        _parentRecoverable = node;
        break;
      }
      node = node.parent;
    }
    final cs = _parentChildrenStates.remove('$storageKey$_childrenStorageKey');
    if (cs != null && cs is Map<String, Map<String, dynamic>>) {
      _childrenStates.addAll(cs);
    }
    recover(_parentChildrenStates.remove(storageKey));
  }

  @override
  void unmountNode() {
    try {
      final s = storage();
      if (s?.isNotEmpty == true) {
        _parentChildrenStates[storageKey] = s!;
      }
      _parentChildrenStates['$storageKey$_childrenStorageKey'] =
          _childrenStates;
    } finally {
      _parentRecoverable = null;
      super.unmountNode();
    }
  }

  /// Reset global state for unit testing only.
  @visibleForTesting
  static void resetForTest() {
    _topChildrenStates.clear();
  }
}

final Map<String, Map<String, dynamic>> _topChildrenStates = {};
