import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../utils/debug.dart';
import 'context_owner.dart';
import '../live/live_view.dart';

/// Base class providing advanced capabilities for [LiveViewModel].
@internal
mixin AdvancedNode on ContextOwner, Debugger {
  final String _innerUniqueKey = const Uuid().v4();

  late final Map<String, AdvancedNode> _children = {};
  AdvancedNode? _parent;

  @internal
  Map<String, AdvancedNode> get children => Map.from(_children);

  @internal
  AdvancedNode? get parent => _parent;

  @internal
  String get uniqueKey => _innerUniqueKey;

  @internal
  void mountNode() {
    try {
      context.visitAncestorElements((element) {
        if (element is LiveElement) {
          _parent = element.viewModel;
          return false;
        }
        return true;
      });
      _parent?._children[uniqueKey] = this;
    } catch (e) {
      debug('AdvancedNode', 'mountNode with Exception: $e');
    }
  }

  @internal
  void unmountNode() {
    try {
      _parent?._children.remove(uniqueKey);
      _parent = null;
    } catch (e) {
      debug('unmountNode', 'mountNode with Exception: $e');
    }
  }
}
