import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/common/common_widgets.dart';

class ReportScreen extends ConsumerWidget {
  final int idLote;
  const ReportScreen({required this.idLote, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reporteAsync = ref.watch(reporteProvider(idLote));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de trazabilidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
            onPressed: () => showSuccessSnack(context, 'Función de exportación próximamente.'),
          ),
        ],
      ),
      body: reporteAsync.when(
        loading: () => const CenteredLoader(),
        error: (e, _) => ErrorView(
          message: 'Error al generar el reporte.',
          onRetry: () => ref.invalidate(reporteProvider(idLote)),
        ),
        data: (reporte) => _ReporteBody(reporte: reporte),
      ),
    );
  }
}

class _ReporteBody extends StatelessWidget {
  final ReporteLote reporte;
  const _ReporteBody({required this.reporte});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtDt = DateFormat('dd/MM/yyyy HH:mm');
    final lote = reporte.lote;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Encabezado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.coffee, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  const Text('CaféTrace', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(
                    'Generado: ${fmt.format(DateTime.now())}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lote.codigoLote,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text(
                'Reporte de trazabilidad postcosecha',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info del lote
        _Section(
          title: 'Información del lote',
          child: Column(
            children: [
              _InfoRow('Código', lote.codigoLote),
              _InfoRow('Finca', lote.nombreFinca ?? '—'),
              _InfoRow('Variedad', lote.nombreVariedad ?? '—'),
              _InfoRow('Cantidad inicial', lote.cantidadKg != null ? '${lote.cantidadKg} kg' : '—'),
              _InfoRow('Fecha de registro', fmt.format(lote.fechaRegistro)),
              _InfoRow('Estado actual', lote.nombreEstado ?? '—'),
              if (reporte.rendimientoFinal != null)
                _InfoRow(
                  'Rendimiento final',
                  '${reporte.rendimientoFinal!.toStringAsFixed(1)}%',
                  highlight: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Resumen de actividades
        _Section(
          title: 'Historial de actividades (${reporte.registros.length})',
          child: reporte.registros.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin registros.', style: TextStyle(color: AppTheme.textMuted)),
                )
              : Column(
                  children: reporte.registros.map((r) => _RegistroResumen(
                    registro: r,
                    fmtDt: fmtDt,
                  )).toList(),
                ),
        ),

        if (reporte.lote.observaciones != null) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Observaciones generales',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(reporte.lote.observaciones!, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Universidad Pontificia Bolivariana · CaféTrace 2026',
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
        ),
        const Divider(height: 1),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppTheme.estadoActivo : AppTheme.primary,
          ),
        ),
      ],
    ),
  );
}

class _RegistroResumen extends StatelessWidget {
  final RegistroPostcosecha registro;
  final DateFormat fmtDt;
  const _RegistroResumen({required this.registro, required this.fmtDt});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                registro.nombreActividad ?? 'Actividad',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            if (registro.nombreEstado != null) EstadoBadge(registro.nombreEstado!),
          ],
        ),
        const SizedBox(height: 4),
        Text(fmtDt.format(registro.fechaHora), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        if (registro.variables.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: registro.variables.map((v) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${v.nombreVariable}: ${v.valor}${v.unidadSimbolo != null ? ' ${v.unidadSimbolo}' : ''}',
                style: const TextStyle(fontSize: 10, color: AppTheme.primary),
              ),
            )).toList(),
          ),
        ],
        if (registro.observacion != null) ...[
          const SizedBox(height: 6),
          Text(registro.observacion!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
        ],
      ],
    ),
  );
}
