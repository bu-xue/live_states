import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class GlobalStoreProvider extends LiveProvider {
  final String name = 'GlobalStore';
}

void main() {
  group('LiveStore Tests', () {
    setUp(() {
      LiveStore.resetForTest();
    });

    tearDown(() {
      LiveStore.resetForTest();
    });

    testWidgets('LiveStore should allow static provider lookup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveStore(
            providerCreates: [() => GlobalStoreProvider()],
            builder: (context) => const Text('App Content'),
          ),
        ),
      );

      final provider = LiveStore.provider<GlobalStoreProvider>();
      expect(provider, isNotNull);
      expect(provider!.name, 'GlobalStore');
    });

    testWidgets('LiveStore should only allow one instance in tree', (tester) async {
      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errorDetails = details;

      // 故意触发多实例错误
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              LiveStore(
                providerCreates: [() => GlobalStoreProvider()],
                builder: (context) => const SizedBox(),
              ),
              LiveStore(
                providerCreates: [() => GlobalStoreProvider()],
                builder: (context) => const SizedBox(),
              ),
            ],
          ),
        ),
      );

      expect(errorDetails, isNotNull);
      expect(errorDetails!.summary.toString(), contains('LiveStore should only be used once'));
      
      FlutterError.onError = originalOnError;
    });

    testWidgets('LiveStore should clear static reference on dispose', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveStore(
            providerCreates: [() => GlobalStoreProvider()],
            builder: (context) => const SizedBox(),
          ),
        ),
      );
      
      expect(LiveStore.provider<GlobalStoreProvider>(), isNotNull);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      
      expect(LiveStore.provider<GlobalStoreProvider>(), isNull);
    });
  });
}
