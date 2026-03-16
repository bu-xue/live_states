typedef DebuggerCallback = void Function(String tag, String message);

class LiveStatesDebugger {
  LiveStatesDebugger._();

  static bool enabled = false;

  static DebuggerCallback debuggerCallback = (tag, message) {
    // ignore: avoid_print
    print('### $tag: $message');
  };
}
