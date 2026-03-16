/// LiveStates is a lightweight and high-performance state management framework.
///
/// Key Features:
/// 1. Automatic Dependency Tracking: Based on the Zone mechanism, it automatically identifies LiveData dependencies during the build process.
/// 2. Precise Local Rebuilds: Use LiveScope to control the rebuild range to the minimum extent.
/// 3. Full Lifecycle: Deeply binding between ViewModel and Widget lifecycles.
/// 4. Zero Integration Cost: MVVM pattern, clearly isolating view and business logic.
library;

export 'src/live/live_view.dart' hide IgnoreStream, ignoreObserver;

export 'src/advanced/ticker_provider.dart';
export 'src/advanced/refreshable.dart';
export 'src/advanced/recoverable.dart';

export 'src/utils/debug_config.dart';
export 'src/utils/debug.dart' show Debugger;
