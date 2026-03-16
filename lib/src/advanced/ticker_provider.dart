import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../live/live_view.dart';

/// Provides a single [Ticker].
mixin SingleTickerProviderMixin<L extends LiveWidget> on LiveViewModel<L> implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            '$runtimeType is a SingleTickerProviderMixin but multiple tickers were created.'),
        ErrorDescription(
            'A SingleTickerProviderMixin can only be used as a TickerProvider once.'),
        ErrorHint(
          'If a State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a SingleTickerProviderMixin, use a regular TickerProviderMixin.',
        ),
      ]);
    }());
    _ticker = Ticker(onTick,
        debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null);
    _updateTickerModeNotifier();
    _updateTicker(); // Sets _ticker.mute correctly.
    return _ticker!;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription(
          '$runtimeType created a Ticker via its SingleTickerProviderMixin, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose().',
        ),
        ErrorHint(
          'Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.',
        ),
        _ticker!.describeForError('The offending ticker was'),
      ]);
    }());
    _tickerModeNotifier?.removeListener(_updateTicker);
    _tickerModeNotifier = null;
    super.dispose();
  }

  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor.
    _updateTickerModeNotifier();
    _updateTicker();
  }

  void _updateTicker() {
    final TickerModeData values = _tickerModeNotifier!.value;
    if (_ticker != null) {
      _ticker!.muted = !values.enabled;
      _ticker!.forceFrames = values.forceFrames;
    }
  }

  void _updateTickerModeNotifier() {
    final ValueListenable<TickerModeData> newNotifier = TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTicker);
    newNotifier.addListener(_updateTicker);
    _tickerModeNotifier = newNotifier;
  }
}

/// Provides [Ticker] objects.
mixin TickerProviderMixin<L extends LiveWidget> on LiveViewModel<L> implements TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    if (_tickerModeNotifier == null) {
      // Setup TickerMode notifier before we vend the first ticker.
      _updateTickerModeNotifier();
    }
    assert(_tickerModeNotifier != null);
    _tickers ??= <_WidgetTicker>{};
    final TickerModeData values = _tickerModeNotifier!.value;
    final result =
    _WidgetTicker(
      onTick,
      this,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    )
      ..muted = !values.enabled
      ..forceFrames = values.forceFrames;
    _tickers!.add(result);
    _tickers!.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
  }

  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor, get its Notifier.
    _updateTickerModeNotifier();
    _updateTickers();
  }

  void _updateTickers() {
    if (_tickers != null) {
      final TickerModeData values = _tickerModeNotifier!.value;
      final bool muted = !values.enabled;
      for (final Ticker ticker in _tickers!) {
        ticker.muted = muted;
        ticker.forceFrames = values.forceFrames;
      }
    }
  }

  void _updateTickerModeNotifier() {
    final ValueListenable<TickerModeData> newNotifier = TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTickers);
    newNotifier.addListener(_updateTickers);
    _tickerModeNotifier = newNotifier;
  }

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (final Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                '$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time '
                'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                'be disposed before calling super.dispose().',
              ),
              ErrorHint(
                'Tickers used by AnimationControllers '
                'should be disposed by calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.',
              ),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());
    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.dispose();
  }
}

class _WidgetTicker extends Ticker {
  _WidgetTicker(super.onTick, this._creator, {super.debugLabel});

  final TickerProviderMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}
