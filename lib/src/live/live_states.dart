part of 'live_view.dart';

/// Mixin used to define the state container for [LiveWidget].
/// 
/// Typically used by [LiveViewModel] and [LiveProvider] to hold
/// and manage [LiveData] objects.
mixin LiveStates {
  /// The manager responsible for automatic disposal and dependency tracking.
  LiveOwner get owner;
}
