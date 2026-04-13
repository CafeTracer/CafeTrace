import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class LotsListScreen extends ConsumerWidget {
  const LotsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesProvider);
    final lotesFiltrados = ref.watch(lotesFiltradosProvider);
    final filtro = ref.watch(loteFiltroProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Lotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo lote',
            onPressed: () => context.push('${AppRoutes.lots}/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => ref.read(loteBusquedaProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Buscar por código, finca o variedad...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ),

          // Chips de filtro
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _FiltroChip(label: 'Todos', value: 'todos', selected: filtro == 'todos', ref: ref),
                const SizedBox(width: 8),
                _FiltroChip(label: 'Activos', value: 'activos', selected: filtro == 'activos', ref: ref),
                const SizedBox(width: 8),
                _FiltroChip(label: 'Inactivos', value: 'inactivos', selected: filtro == 'inactivos', ref: ref),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista
          Expanded(
            child: lotesAsync.when(
              loading: () => const CenteredLoader(),
              error: (e, _) => ErrorView(
                message: 'Error al cargar lotes.',
                onRetry: () => ref.read(lotesProvider.notifier).refresh(),
              ),
              data: (_) {
                if (lotesFiltrados.isEmpty) {
                  return EmptyView(
                    message: 'No se encontraron lotes.',
                    icon: Icons.inventory_2_outlined,
                    actionLabel: 'Nuevo lote',
                    onAction: () => context.push('${AppRoutes.lots}/new'),
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => ref.read(lotesProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: lotesFiltrados.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _LoteListTile(lote: lotesFiltrados[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.lots}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo lote'),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final WidgetRef ref;

  const _FiltroChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => ref.read(loteFiltroProvider.notifier).state = value,
    selectedColor: AppTheme.accentLight,
    checkmarkColor: AppTheme.primary,
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      color: selected ? AppTheme.primary : AppTheme.textMuted,
    ),
    side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border, width: selected ? 1.5 : 1),
    backgroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _LoteListTile extends StatelessWidget {
  final dynamic lote;
  const _LoteListTile({required this.lote});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => context.push('${AppRoutes.lots}/${lote.id}'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: lote.activo ? AppTheme.accentLight : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: lote.activo ? AppTheme.primary : AppTheme.textMuted,
        size: 22,
      ),
    ),
    title: Text(
      lote.codigoLote,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          '${lote.nombreFinca ?? 'Finca'} · ${lote.nombreVariedad ?? 'Variedad'}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        if (lote.cantidadKg != null) ...[
          const SizedBox(height: 2),
          Text(
            '${lote.cantidadKg} kg',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ],
    ),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (lote.nombreEstado != null) EstadoBadge(lote.nombreEstado!),
        const SizedBox(height: 4),
        const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
      ],
    ),
    isThreeLine: true,
  );
}
