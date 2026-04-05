import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/common/common_widgets.dart';

class RecordFormScreen extends ConsumerStatefulWidget {
  final int idLote;
  const RecordFormScreen({required this.idLote, super.key});

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  int? _idTipoActividad;
  int? _idEstadoLote;
  DateTime _fechaHora = DateTime.now();
  bool _isLoading = false;

  // Variables dinámicas: Map<idVariable, controller>
  final Map<int, TextEditingController> _varControllers = {};
  final Map<int, TextEditingController> _varCommentControllers = {};

  @override
  void dispose() {
    _observacionCtrl.dispose();
    _ubicacionCtrl.dispose();
    for (final c in _varControllers.values) c.dispose();
    for (final c in _varCommentControllers.values) c.dispose();
    super.dispose();
  }

  void _initVariableControllers(List<VariableMonitoreo> variables) {
    for (final v in variables) {
      _varControllers.putIfAbsent(v.id, () => TextEditingController());
      _varCommentControllers.putIfAbsent(v.id, () => TextEditingController());
    }
  }

  Future<void> _submit(List<VariableMonitoreo> todasVariables) async {
    if (!_formKey.currentState!.validate()) return;
    if (_idTipoActividad == null) { showErrorSnack(context, 'Selecciona el tipo de actividad.'); return; }
    if (_idEstadoLote == null) { showErrorSnack(context, 'Selecciona el estado del lote.'); return; }

    final usuario = ref.read(usuarioActualProvider);
    if (usuario == null) { showErrorSnack(context, 'No hay sesión activa.'); return; }

    // Construir lista de variables con valor
    final variables = <({int idVariable, double valor, String? comentario})>[];
    for (final v in todasVariables) {
      final ctrl = _varControllers[v.id];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        final valor = double.tryParse(ctrl.text.trim());
        if (valor == null) { showErrorSnack(context, 'Valor inválido en "${v.nombre}".'); return; }
        variables.add((
          idVariable: v.id,
          valor: valor,
          comentario: _varCommentControllers[v.id]?.text.trim().isEmpty == true
              ? null
              : _varCommentControllers[v.id]?.text.trim(),
        ));
      }
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(crearRegistroProvider(CrearRegistroParams(
        idLote: widget.idLote,
        idUsuario: usuario.id,
        idTipoActividad: _idTipoActividad!,
        idEstadoLote: _idEstadoLote!,
        fechaHora: _fechaHora,
        observacion: _observacionCtrl.text.isEmpty ? null : _observacionCtrl.text,
        ubicacionRegistro: _ubicacionCtrl.text.isEmpty ? null : _ubicacionCtrl.text,
        variables: variables,
      )).future);
      if (mounted) {
        showSuccessSnack(context, 'Registro guardado exitosamente.');
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, extractAppError(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(tiposActividadProvider);
    final estadosAsync = ref.watch(estadosLoteProvider);
    final variablesAsync = ref.watch(variablesMonitoreoProvider);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    
    final isLoading = tiposAsync.isLoading || estadosAsync.isLoading || variablesAsync.isLoading;
    final hasError = tiposAsync.hasError || estadosAsync.hasError || variablesAsync.hasError;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar actividad')),
      body: hasError
          ? const ErrorView(message: 'Error al cargar formulario.')
          : isLoading
              ? const CenteredLoader()
              : tiposAsync.maybeWhen(
                  data: (tipos) => estadosAsync.maybeWhen(
                    data: (estados) => variablesAsync.maybeWhen(
                      data: (variables) {
                        _initVariableControllers(variables);
                        return _buildForm(context, tipos, estados, variables, fmt);
                      },
                      orElse: () => const CenteredLoader(),
                    ),
                    orElse: () => const CenteredLoader(),
                  ),
                  orElse: () => const CenteredLoader(),
                ),
      );
  }

  Widget _buildForm(
    BuildContext context,
    List<Catalogo> tipos,
    List<Catalogo> estados,
    List<VariableMonitoreo> variables,
    DateFormat fmt,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info del lote
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lote #${widget.idLote}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Tipo de actividad
          AppDropdown<int>(
            label: 'Tipo de actividad *',
            value: _idTipoActividad,
            items: tipos.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre))).toList(),
            onChanged: (v) => setState(() => _idTipoActividad = v),
            validator: (v) => v == null ? 'Selecciona un tipo de actividad' : null,
          ),
          const SizedBox(height: 14),

          // Estado del lote
          AppDropdown<int>(
            label: 'Estado del lote en este momento *',
            value: _idEstadoLote,
            items: estados.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre))).toList(),
            onChanged: (v) => setState(() => _idEstadoLote = v),
            validator: (v) => v == null ? 'Selecciona el estado del lote' : null,
          ),
          const SizedBox(height: 14),

          // Fecha y hora
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _fechaHora,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
                  child: child!,
                ),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_fechaHora),
              );
              if (time != null) {
                setState(() => _fechaHora = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Fecha y hora del evento *',
                  suffixIcon: Icon(Icons.access_time_outlined, size: 18),
                ),
                controller: TextEditingController(text: fmt.format(_fechaHora)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Variables de monitoreo
          const SectionTitle('Variables de monitoreo'),
          const SizedBox(height: 4),
          const Text(
            'Registra las variables medidas en esta actividad. Deja vacío las que no apliquen.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          ...variables.map((v) => _VariableInput(
            variable: v,
            controller: _varControllers[v.id]!,
            commentController: _varCommentControllers[v.id]!,
          )),

          const SizedBox(height: 14),

          // Ubicación
          AppTextField(
            label: 'Ubicación del registro',
            hint: 'Ej: Área de fermentación, Sección B',
            controller: _ubicacionCtrl,
          ),
          const SizedBox(height: 14),

          // Observación
          AppTextField(
            label: 'Observaciones',
            hint: 'Notas adicionales sobre esta actividad...',
            controller: _observacionCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : () => _submit(variables),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar registro'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

class _VariableInput extends StatelessWidget {
  final VariableMonitoreo variable;
  final TextEditingController controller;
  final TextEditingController commentController;

  const _VariableInput({
    required this.variable,
    required this.controller,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
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
                variable.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            if (variable.simboloUnidad != null)
              Text(
                variable.simboloUnidad!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            if (variable.requiereAlerta)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.warning_amber_outlined, size: 14, color: Colors.orange),
              ),
          ],
        ),
        if (variable.valorMinimo != null || variable.valorMaximo != null) ...[
          const SizedBox(height: 2),
          Text(
            'Rango: ${variable.valorMinimo ?? '—'} – ${variable.valorMaximo ?? '—'} ${variable.simboloUnidad ?? ''}',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Valor numérico',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
          ),
        ),
      ],
    ),
  );
}
