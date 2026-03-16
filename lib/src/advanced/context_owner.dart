import 'package:flutter/widgets.dart';

/// Helper for context management.
mixin ContextOwner {

  BuildContext get context;

  bool get mounted => context.mounted;

  late final List<VoidCallback> _listeners = [];

  void addContextUnmountListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeContextUnmountListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void disposeContext() {
    for (var listener in _listeners) {
      listener.call();
    }
    _listeners.clear();
  }

  /// Check if the context is still available.
  void checkContext() {
    if (!context.mounted) {
      throw Exception('ContextInvalidException: context is unmounted');
    }
  }
}
