import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class LotFormScreen extends ConsumerStatefulWidget {
  final int? idLote; // null = crear, int = editar
  const LotFormScreen({this.idLote, super.key});

  @override
  ConsumerState<LotFormScreen> createState() => _LotFormScreenState();
}

class _LotFormScreenState extends ConsumerState<LotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  int? _idFinca;
  int? _idVariedad;
  int? _idEstado;
  DateTime _fechaRegistro = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.idLote != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadLote();
  }

  Future<void> _loadLote() async {
    try {
      final lote = await ref.read(loteDetalleProvider(widget.idLote!).future);
      if (!mounted) return;
      setState(() {
        _codigoCtrl.text = lote.codigoLote;
        _cantidadCtrl.text = lote.cantidadKg?.toString() ?? '';
        _observacionesCtrl.text = lote.observaciones ?? '';
        _idFinca = lote.idFinca;
        _idVariedad = lote.idVariedad;
        _idEstado = lote.idEstadoLoteActual;
        _fechaRegistro = lote.fechaRegistro;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, extractAppError(e).message);
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _cantidadCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idFinca == null) { showErrorSnack(context, 'Selecciona una finca.'); return; }
    if (_idVariedad == null) { showErrorSnack(context, 'Selecciona una variedad.'); return; }
    if (_idEstado == null) { showErrorSnack(context, 'Selecciona un estado.'); return; }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await ref.read(lotesProvider.notifier).editarLote(
          idLote: widget.idLote!,
          idEstadoLoteActual: _idEstado,
          cantidadKg: double.tryParse(_cantidadCtrl.text),
          observaciones: _observacionesCtrl.text.isEmpty ? null : _observacionesCtrl.text,
        );
        if (mounted) { showSuccessSnack(context, 'Lote actualizado.'); context.pop(); }
      } else {
        await ref.read(lotesProvider.notifier).crearLote(
          idFinca: _idFinca!,
          idVariedad: _idVariedad!,
          idEstadoLoteActual: _idEstado!,
          codigoLote: _codigoCtrl.text.trim(),
          fechaRegistro: _fechaRegistro,
          cantidadKg: double.tryParse(_cantidadCtrl.text),
          observaciones: _observacionesCtrl.text.isEmpty ? null : _observacionesCtrl.text,
        );
        if (mounted) { showSuccessSnack(context, 'Lote creado exitosamente.'); context.pop(); }
      }
    } catch (e) {
      if (!mounted) return;
      final err = extractAppError(e);
      showErrorSnack(context, err.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fincasAsync = ref.watch(fincasProvider);
    final variedadesAsync = ref.watch(variedadesProvider);
    final estadosAsync = ref.watch(estadosLoteProvider);
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar lote' : 'Nuevo lote')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Código del lote (solo en creación)
            if (!_isEditing) ...[
              AppTextField(
                label: 'Código del lote *',
                hint: 'Ej: LOT-2026-010',
                controller: _codigoCtrl,
                validator: (v) => v == null || v.trim().isEmpty ? 'El código es requerido' : null,
              ),
              const SizedBox(height: 14),
            ],

            // Finca
            fincasAsync.when(
              loading: () => const CenteredLoader(),
              error: (_, __) => const Text('Error al cargar fincas'),
              data: (fincas) => AppDropdown<int>(
                label: 'Finca *',
                value: _idFinca,
                items: fincas.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nombre))).toList(),
                onChanged: (v) => setState(() => _idFinca = v),
                validator: (v) => v == null ? 'Selecciona una finca' : null,
              ),
            ),
            const SizedBox(height: 14),

            // Variedad
            variedadesAsync.when(
              loading: () => const CenteredLoader(),
              error: (_, __) => const Text('Error al cargar variedades'),
              data: (variedades) => AppDropdown<int>(
                label: 'Variedad de café *',
                value: _idVariedad,
                items: variedades.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nombre))).toList(),
                onChanged: (v) => setState(() => _idVariedad = v),
                validator: (v) => v == null ? 'Selecciona una variedad' : null,
              ),
            ),
            const SizedBox(height: 14),

            // Estado del lote
            estadosAsync.when(
              loading: () => const CenteredLoader(),
              error: (_, __) => const Text('Error al cargar estados'),
              data: (estados) => AppDropdown<int>(
                label: 'Estado actual *',
                value: _idEstado,
                items: estados.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre))).toList(),
                onChanged: (v) => setState(() => _idEstado = v),
                validator: (v) => v == null ? 'Selecciona un estado' : null,
              ),
            ),
            const SizedBox(height: 14),

            // Cantidad
            AppTextField(
              label: 'Cantidad (kg)',
              hint: 'Ej: 180.50',
              controller: _cantidadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Ingresa un número válido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Fecha de registro
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaRegistro,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _fechaRegistro = picked);
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Fecha de registro *',
                    hintText: fmt.format(_fechaRegistro),
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  controller: TextEditingController(text: fmt.format(_fechaRegistro)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Observaciones
            AppTextField(
              label: 'Observaciones',
              hint: 'Notas sobre el lote...',
              controller: _observacionesCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isEditing ? 'Guardar cambios' : 'Crear lote'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}
