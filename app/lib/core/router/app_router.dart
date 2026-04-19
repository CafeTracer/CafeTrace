import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers/providers.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/lots/lots_list_screen.dart';
import '../../presentation/screens/lots/lot_detail_screen.dart';
import '../../presentation/screens/lots/lot_form_screen.dart';
import '../../presentation/screens/records/record_form_screen.dart';
import '../../presentation/screens/records/report_screen.dart';
import '../../presentation/screens/farms/farms_screen.dart';
import '../../presentation/screens/farms/farm_form_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/admin/admin_user_form_screen.dart';
import '../../presentation/widgets/common/main_shell.dart';

// Rutas nombradas — usar siempre estas constantes para navegar
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const lots = '/lots';
  static const lotDetail = '/lots/:id';
  static const lotCreate = '/lots/new';
  static const lotEdit = '/lots/:id/edit';
  static const recordCreate = '/lots/:id/records/new';
  static const report = '/lots/:id/report';
  static const farms = '/farms';
  static const farmCreate = '/farms/new';
  static const profile = '/profile';
  static const adminUsers = '/admin/users';
  static const adminUserCreate = '/admin/users/new';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isAuthenticated = authState.maybeWhen(data: (sesion) => sesion != null, orElse: () => false);
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isLoginRoute) return AppRoutes.login;
      if (isAuthenticated && isLoginRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // Login — fuera del shell
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),

      // Shell con Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.lots,
            builder: (_, _) => const LotsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const LotFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => LotDetailScreen(
                  idLote: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => LotFormScreen(
                      idLote: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                  GoRoute(
                    path: 'records/new',
                    builder: (_, state) => RecordFormScreen(
                      idLote: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'report',
                    builder: (_, state) => ReportScreen(
                      idLote: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.farms,
            builder: (_, _) => const FarmsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const FarmFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (_, _) => const AdminUsersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const AdminUserFormScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
