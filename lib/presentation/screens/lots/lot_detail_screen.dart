import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/common/common_widgets.dart';

class LotDetailScreen extends ConsumerWidget {
  final int idLote;
  const LotDetailScreen({required this.idLote, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loteAsync = ref.watch(loteDetalleProvider(idLote));
    final registrosAsync = ref.watch(registrosProvider(idLote));

    return Scaffold(
      appBar: AppBar(
        title: loteAsync.when(
          data: (l) => Text(l.codigoLote),
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Detalle lote'),
        ),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Ver reporte',
            onPressed: () => context.push('${AppRoutes.lots}/$idLote/report'),
          ),
          loteAsync.when(
            data: (l) => PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar lote')),
              ],
              onSelected: (v) {
                if (v == 'edit') context.push('${AppRoutes.lots}/$idLote/edit');
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: loteAsync.when(
        loading: () => const CenteredLoader(),
        error: (e, _) => ErrorView(
          message: 'Error al cargar el lote.',
          onRetry: () => ref.invalidate(loteDetalleProvider(idLote)),
        ),
        data: (lote) => _LoteDetailBody(
          lote: lote,
          registrosAsync: registrosAsync,
          idLote: idLote,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.lots}/$idLote/records/new'),
        icon: const Icon(Icons.add),
        label: const Text('Agregar registro'),
      ),
    );
  }
}

class _LoteDetailBody extends ConsumerWidget {
  final Lote lote;
  final AsyncValue<List<RegistroPostcosecha>> registrosAsync;
  final int idLote;

  const _LoteDetailBody({
    required this.lote,
    required this.registrosAsync,
    required this.idLote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        ref.invalidate(loteDetalleProvider(idLote));
        ref.invalidate(registrosProvider(idLote));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ficha del lote
          _LoteFicha(lote: lote),
          const SizedBox(height: 20),

          // Timeline de registros
          Row(
            children: [
              const SectionTitle('Historial de actividades'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('${AppRoutes.lots}/$idLote/records/new'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Registrar'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          registrosAsync.when(
            loading: () => const CenteredLoader(),
            error: (e, _) => ErrorView(
              message: 'Error al cargar registros.',
              onRetry: () => ref.invalidate(registrosProvider(idLote)),
            ),
            data: (registros) {
              if (registros.isEmpty) {
                return const EmptyView(
                  message: 'Aún no hay registros postcosecha para este lote.',
                  icon: Icons.timeline_outlined,
                );
              }
              return Column(
                children: registros
                    .asMap()
                    .entries
                    .map((e) => _TimelineItem(
                          registro: e.value,
                          isLast: e.key == registros.length - 1,
                          idLote: idLote,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoteFicha extends StatelessWidget {
  final Lote lote;
  const _LoteFicha({required this.lote});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                lote.codigoLote,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              const Spacer(),
              if (lote.nombreEstado != null) EstadoBadge(lote.nombreEstado!),
            ],
          ),
          const SizedBox(height: 12),
          _FichaRow(icon: Icons.landscape_outlined, label: 'Finca', value: lote.nombreFinca ?? '—'),
          _FichaRow(icon: Icons.eco_outlined, label: 'Variedad', value: lote.nombreVariedad ?? '—'),
          _FichaRow(
            icon: Icons.scale_outlined,
            label: 'Cantidad',
            value: lote.cantidadKg != null ? '${lote.cantidadKg} kg' : '—',
          ),
          _FichaRow(
            icon: Icons.calendar_today_outlined,
            label: 'Registro',
            value: fmt.format(lote.fechaRegistro),
          ),
          if (lote.observaciones != null && lote.observaciones!.isNotEmpty)
            _FichaRow(icon: Icons.notes_outlined, label: 'Notas', value: lote.observaciones!),
        ],
      ),
    );
  }
}

class _FichaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FichaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
      ],
    ),
  );
}

class _TimelineItem extends ConsumerWidget {
  final RegistroPostcosecha registro;
  final bool isLast;
  final int idLote;

  const _TimelineItem({required this.registro, required this.isLast, required this.idLote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea vertical + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppTheme.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            registro.nombreActividad ?? 'Actividad #${registro.idTipoActividad}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        if (registro.nombreEstado != null)
                          EstadoBadge(registro.nombreEstado!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(registro.fechaHora),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    if (registro.nombreUsuario != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Por: ${registro.nombreUsuario}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                    if (registro.variables.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: registro.variables.map((v) => _VariableChip(v: v)).toList(),
                      ),
                    ],
                    if (registro.observacion != null && registro.observacion!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        registro.observacion!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                    // Opciones
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: 'Eliminar registro',
                              message: '¿Eliminar este registro? Esta acción no se puede deshacer.',
                              confirmLabel: 'Eliminar',
                              isDestructive: true,
                            );
                            if (ok) {
                              await ref.read(eliminarRegistroProvider((idLote: idLote, idRegistro: registro.id)).future);
                              if (context.mounted) showSuccessSnack(context, 'Registro eliminado.');
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Eliminar', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  final dynamic v;
  const _VariableChip({required this.v});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '${v.nombreVariable ?? 'Variable'}: ${v.valor}${v.unidadSimbolo != null ? ' ${v.unidadSimbolo}' : ''}',
      style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
    ),
  );
}
