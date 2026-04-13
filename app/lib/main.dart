import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.initialize();
  runApp(const ProviderScope(child: CafeTraceApp()));
}

// Credenciales de prueba:
// Admin: admin@test.com / admin123
// Usuario: user@test.com / user123

class CafeTraceApp extends ConsumerWidget {
  const CafeTraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CaféTrace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
