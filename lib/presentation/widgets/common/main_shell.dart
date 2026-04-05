import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({required this.child, super.key});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/lots')) return 1;
    if (location.startsWith('/farms')) return 2;
    if (location.startsWith('/admin')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esAdmin = ref.watch(authProvider).maybeWhen(data: (sesion) => sesion?.usuario.esAdmin ?? false, orElse: () => false);
    final idx = _currentIndex(context);

    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
      const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Lotes'),
      const BottomNavigationBarItem(icon: Icon(Icons.landscape_outlined), activeIcon: Icon(Icons.landscape), label: 'Fincas'),
      if (esAdmin)
        const BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Usuarios'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
    ];

    final routes = [
      AppRoutes.dashboard,
      AppRoutes.lots,
      AppRoutes.farms,
      if (esAdmin) AppRoutes.adminUsers,
      AppRoutes.profile,
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx.clamp(0, items.length - 1),
          items: items,
          onTap: (i) => context.go(routes[i]),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}
