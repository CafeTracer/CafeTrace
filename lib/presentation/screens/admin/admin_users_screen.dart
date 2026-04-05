import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

// ── LISTA DE USUARIOS (ADMIN) ─────────────────────────────────────────────────
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.admin,
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('${AppRoutes.adminUsers}/new'),
          ),
        ],
      ),
      body: usuariosAsync.when(
        loading: () => const CenteredLoader(),
        error: (e, _) => ErrorView(
          message: 'Error al cargar usuarios.',
          onRetry: () => ref.read(usuariosProvider.notifier).refresh(),
        ),
        data: (usuarios) {
          if (usuarios.isEmpty) {
            return EmptyView(
              message: 'No hay usuarios registrados.',
              icon: Icons.group_outlined,
              actionLabel: 'Crear usuario',
              onAction: () => context.push('${AppRoutes.adminUsers}/new'),
            );
          }
          return RefreshIndicator(
            color: AppTheme.admin,
            onRefresh: () => ref.read(usuariosProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final u = usuarios[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: u.esAdmin
                          ? AppTheme.admin.withOpacity(0.12)
                          : AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        u.iniciales,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: u.esAdmin ? AppTheme.admin : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(u.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.correo, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: u.esAdmin ? AppTheme.admin.withOpacity(0.1) : AppTheme.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              u.esAdmin ? 'Admin' : 'Productor',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: u.esAdmin ? AppTheme.admin : AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Switch(
                    value: u.activo,
                    activeColor: AppTheme.estadoActivo,
                    onChanged: (v) async {
                      try {
                        await ref.read(usuariosProvider.notifier).cambiarEstado(
                          idUsuario: u.id,
                          activo: v,
                        );
                        if (context.mounted) {
                          showSuccessSnack(context, v ? 'Usuario activado.' : 'Usuario desactivado.');
                        }
                      } catch (e) {
                        if (context.mounted) showErrorSnack(context, extractAppError(e).message);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.admin,
        onPressed: () => context.push('${AppRoutes.adminUsers}/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo usuario'),
      ),
    );
  }
}
