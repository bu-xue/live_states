import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_states/live_states.dart';

class LifecycleProvider extends LiveProvider {
  bool initCalled = false;
  bool disposeCalled = false;

  @override
  void init() {
    super.init();
    initCalled = true;
  }

  @override
  void dispose() {
    disposeCalled = true;
    super.dispose();
  }
}

class AuthProvider extends LiveProvider {
  final String name;
  late final username = LiveData<String>('Guest', owner);
  
  AuthProvider(this.name);
}

class ServiceProvider extends LiveProvider {
  AuthProvider? auth;
  @override
  void init() {
    super.init();
    // 验证在 multi 注入模式下，后面的 Provider 能找到前面的 Provider
    auth = context.provider<AuthProvider>();
  }
}

AuthProvider? _providerFromVM;

class ProviderAccessVM extends LiveViewModel<ProviderAccessWidget> {
  @override
  void init() {
    super.init();
    _providerFromVM = context.provider<AuthProvider>();
  }
}

class ProviderAccessWidget extends LiveWidget {
  const ProviderAccessWidget({super.key});
  @override
  ProviderAccessVM createViewModel() => ProviderAccessVM();
  @override
  Widget build(BuildContext context, ProviderAccessVM viewModel) => const SizedBox.shrink();
}

void main() {
  group('LiveProvider Detailed Tests', () {
    testWidgets('LiveProvider lifecycle (init/dispose) test', (tester) async {
      late LifecycleProvider provider;

      await tester.pumpWidget(
        MaterialApp(
          home: LiveProvider.create(
            creator: () {
              provider = LifecycleProvider();
              return provider;
            },
            builder: (context) => const SizedBox.shrink(),
          ),
        ),
      );

      expect(provider.initCalled, isTrue);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(provider.disposeCalled, isTrue);
    });

    testWidgets('LiveProviderScope should react to Provider Data changes', (tester) async {
      late AuthProvider auth;

      await tester.pumpWidget(
        MaterialApp(
          home: LiveProvider.create(
            creator: () {
              auth = AuthProvider('Service');
              return auth;
            },
            builder: (context) => LiveScope.p<AuthProvider>(
              builder: (context, provider, child) {
                return Text('User: ${provider.username.value}');
              },
            ),
          ),
        ),
      );

      expect(find.text('User: Guest'), findsOneWidget);

      auth.username.value = 'Admin';
      await tester.pump();

      expect(find.text('User: Admin'), findsOneWidget);
    });

    testWidgets('LiveProvider.multi should support cascade dependency', (tester) async {
      late ServiceProvider service;

      await tester.pumpWidget(
        MaterialApp(
          home: LiveProvider.multi(
            [
              () => AuthProvider('Auth'),
              () => service = ServiceProvider(),
            ],
            (context) => const SizedBox.shrink(),
          ),
        ),
      );

      expect(service.auth, isNotNull, reason: 'ServiceProvider should find AuthProvider in multi injection');
      expect(service.auth!.name, 'Auth');
    });

    testWidgets('Nearest Provider lookup with nested scopes', (tester) async {
      String? resultName;
      await tester.pumpWidget(
        MaterialApp(
          home: LiveProvider.create(
            creator: () => AuthProvider('Outer'),
            builder: (context) => LiveProvider.create(
              creator: () => AuthProvider('Inner'),
              builder: (context) => Builder(
                builder: (ctx) {
                  resultName = ctx.provider<AuthProvider>()?.name;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(resultName, 'Inner');
    });

    testWidgets('LiveViewModel should be able to access LiveProvider via context', (tester) async {
      _providerFromVM = null;

      await tester.pumpWidget(
        MaterialApp(
          home: LiveProvider.create(
            creator: () => AuthProvider('VM-Access'),
            builder: (context) => const ProviderAccessWidget(),
          ),
        ),
      );

      expect(_providerFromVM, isNotNull);
      expect(_providerFromVM!.name, 'VM-Access');
    });
  });
}
