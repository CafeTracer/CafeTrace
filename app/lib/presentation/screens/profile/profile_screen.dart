import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    final fmt = DateFormat('dd/MM/yyyy');

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const CenteredLoader(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar y datos principales
          Center(
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: usuario.esAdmin ? AppTheme.admin : AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    // child: Text(
                    //   usuario.iniciales,
                    //   style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                    // ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario.nombreCompleto,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(usuario.correo, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: usuario.esAdmin ? AppTheme.admin.withOpacity(0.1) : AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    usuario.esAdmin ? 'Administrador' : 'Productor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: usuario.esAdmin ? AppTheme.admin : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Información de cuenta
          const SectionTitle('Información de cuenta'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _InfoTile(icon: Icons.person_outline, label: 'Nombre', value: usuario.nombre),
                const Divider(height: 1),
                _InfoTile(icon: Icons.person_outline, label: 'Apellido', value: usuario.apellido),
                const Divider(height: 1),
                _InfoTile(icon: Icons.email_outlined, label: 'Correo', value: usuario.correo),
                if (usuario.telefono != null) ...[
                  const Divider(height: 1),
                  _InfoTile(icon: Icons.phone_outlined, label: 'Teléfono', value: usuario.telefono!),
                ],
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Miembro desde',
                  value: fmt.format(usuario.fechaCreacion),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Acciones
          const SectionTitle('Configuración'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  title: const Text('Cambiar contraseña', style: TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () => showSuccessSnack(context, 'Próximamente disponible.'),
                ),
                if (usuario.esAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group_outlined, color: AppTheme.admin),
                    title: const Text('Gestionar usuarios', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () => context.go(AppRoutes.adminUsers),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cerrar sesión
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Cerrar sesión',
                message: '¿Estás seguro de que deseas cerrar sesión?',
                confirmLabel: 'Cerrar sesión',
                isDestructive: true,
              );
              if (ok) await ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          ),
          const SizedBox(height: 16),

          const Center(
            child: Text(
              'CaféTrace v1.0.0 · UPB 2026',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primary, size: 20),
    title: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
    subtitle: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
    dense: true,
  );
}
