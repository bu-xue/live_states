import 'package:flutter/foundation.dart';

import 'devtools_helper.dart';

typedef DebuggerCallback = void Function(String tag, String message);

class LiveStatesDebugger {
  LiveStatesDebugger._();

  static DevToolsHelper devtoolsHelper = DevToolsHelper(enable: enabled);

  static bool _enabled = kDebugMode;

  static bool get enabled => _enabled;

  static set enabled(bool value) {
    _enabled = value;
    devtoolsHelper.enable = value;
  }

  static DebuggerCallback debuggerCallback = (tag, message) {
    // ignore: avoid_print
    print('### $tag: $message');
  };
}
