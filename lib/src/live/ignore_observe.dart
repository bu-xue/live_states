part of 'live_view.dart';

@internal
R ignoreObserver<R>(R Function() run) {
  return runZoned(() => run(), zoneValues: {_inLiveCompute: null, _inLiveScopeObserver: null});
}

@internal
class IgnoreStream<T> extends Stream<T> {
  final Stream<T> _source;

  IgnoreStream(this._source);

  @override
  StreamSubscription<T> listen(
      void Function(T data)? onData, {
        Function? onError,
        void Function()? onDone,
        bool? cancelOnError,
      }) {
    return _source.listen(
          (data) {
        if (onData == null) return;
        ignoreObserver(() {
          onData(data);
        });
      },
      onError: (error, stack) {
        if (onError == null) return;
        ignoreObserver(() {
          if (onError is void Function(Object, StackTrace)) {
            onError(error, stack);
          } else if (onError is void Function(Object)) {
            onError(error);
          }
        });
      },
      onDone: () {
        if (onDone == null) return;
        ignoreObserver(() {
          onDone();
        });
      },
      cancelOnError: cancelOnError,
    );
  }
}