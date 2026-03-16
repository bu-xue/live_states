import 'package:live_states/src/utils/debug_config.dart';

/// A mixin that provides debugging capabilities to classes.
/// 
/// Classes mixing in [Debugger] can use the [debug] method to output logs
/// when [LiveStatesDebugger.enabled] is true.
mixin Debugger {
  /// The name used in debug logs to identify the instance.
  String? get debugName => null;

  /// Outputs a debug message if debugging is enabled.
  /// 
  /// [tag] identifies the source or category of the log.
  /// [info] is the message to be displayed.
  void debug(String tag, String info) {
    try {
      if (LiveStatesDebugger.enabled) {
        if (debugName != null) {
          // ignore: avoid_print
          LiveStatesDebugger.debuggerCallback('$tag(${debugName!})', info);
        }
      }
    } catch (e) {
      // Suppress debug errors to avoid crashing the app during logging.
    }
  }
}
