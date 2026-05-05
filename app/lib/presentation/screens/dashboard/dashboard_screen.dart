import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    final lotesAsync = ref.watch(lotesProvider);
    final fincasAsync = ref.watch(fincasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Buen día, ${usuario?.nombre ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(lotesProvider.notifier).refresh(),
        child: lotesAsync.when(
          loading: () => const CenteredLoader(),
          error: (e, _) => ErrorView(onRetry: () => ref.read(lotesProvider.notifier).refresh()),
          data: (lotes) {
            final activos = lotes.where((l) => l.activo).length;
            final completados = lotes.where((l) => !l.activo).length;
            final fincasValue = fincasAsync.when(
              data: (fincas) => '${fincas.length}',
              loading: () => '...',
              error: (_, __) => '—',
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Resumen
                SectionTitle('Resumen'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _StatCard(icon: Icons.inventory_2_outlined, value: '${lotes.length}', label: 'Total lotes', color: AppTheme.primary),
                    _StatCard(icon: Icons.play_circle_outline, value: '$activos', label: 'Activos', color: AppTheme.estadoActivo),
                    _StatCard(icon: Icons.check_circle_outline, value: '$completados', label: 'Completados', color: AppTheme.estadoCompletado),
                    _StatCard(icon: Icons.landscape_outlined, value: fincasValue, label: 'Fincas', color: AppTheme.accent),
                  ],
                ),
                const SizedBox(height: 20),

                // Acceso rápido
                SectionTitle('Acceso rápido'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_outline,
                        label: 'Nuevo lote',
                        onTap: () => context.push('${AppRoutes.lots}/new'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.search,
                        label: 'Buscar lote',
                        onTap: () => context.go(AppRoutes.lots),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.landscape_outlined,
                        label: 'Mis fincas',
                        onTap: () => context.go(AppRoutes.farms),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Lotes recientes
                SectionTitle(
                  'Lotes recientes',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.lots),
                    child: const Text('Ver todos'),
                  ),
                ),
                const SizedBox(height: 10),
                if (lotes.isEmpty)
                  const EmptyView(
                    message: 'Aún no tienes lotes registrados.',
                    icon: Icons.inventory_2_outlined,
                  )
                else
                  ...lotes.take(5).map((lote) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LoteCard(lote: lote),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _LoteCard extends StatelessWidget {
  final dynamic lote;
  const _LoteCard({required this.lote});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.push('${AppRoutes.lots}/${lote.id}'),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.accentLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 20),
      ),
      title: Text(lote.codigoLote, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(
        '${lote.nombreVariedad ?? 'Variedad #${lote.idVariedad}'} · ${lote.cantidadKg != null ? '${lote.cantidadKg} kg' : '—'}',
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: lote.nombreEstado != null ? EstadoBadge(lote.nombreEstado!) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
  );
}
