import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

// ── LISTA DE FINCAS ───────────────────────────────────────────────────────────
class FarmsScreen extends ConsumerWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fincasAsync = ref.watch(fincasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Fincas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('${AppRoutes.farms}/new'),
          ),
        ],
      ),
      body: fincasAsync.when(
        loading: () => const CenteredLoader(),
        error: (e, _) => ErrorView(
          message: 'Error al cargar fincas.',
          onRetry: () => ref.invalidate(fincasProvider),
        ),
        data: (fincas) {
          if (fincas.isEmpty) {
            return EmptyView(
              message: 'Aún no tienes fincas registradas.',
              icon: Icons.landscape_outlined,
              actionLabel: 'Registrar finca',
              onAction: () => context.push('${AppRoutes.farms}/new'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: fincas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final f = fincas[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.landscape_outlined, color: AppTheme.primary, size: 22),
                  ),
                  title: Text(f.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text('Propietario: ${f.propietario}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      if (f.areaHectareas != null)
                        Text('${f.areaHectareas} ha', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      if (f.direccion != null)
                        Text(f.direccion!, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.farms}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva finca'),
      ),
    );
  }
}
