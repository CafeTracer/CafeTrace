import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/common/common_widgets.dart';

class FarmFormScreen extends ConsumerStatefulWidget {
  const FarmFormScreen({super.key});

  @override
  ConsumerState<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends ConsumerState<FarmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _propietarioCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  int? _idDepartamento;
  int? _idMunicipio;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _propietarioCtrl.dispose();
    _direccionCtrl.dispose();
    _areaCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idMunicipio == null) { showErrorSnack(context, 'Selecciona un municipio.'); return; }

    setState(() => _isLoading = true);
    try {
      await ref.read(fincaRepoProvider).crearFinca(
        idMunicipio: _idMunicipio!,
        nombre: _nombreCtrl.text.trim(),
        propietario: _propietarioCtrl.text.trim(),
        direccion: _direccionCtrl.text.isEmpty ? null : _direccionCtrl.text,
        areaHectareas: double.tryParse(_areaCtrl.text),
        descripcion: _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
      );
      ref.invalidate(fincasProvider);
      if (mounted) {
        showSuccessSnack(context, 'Finca registrada exitosamente.');
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
    final deptosAsync = ref.watch(departamentosProvider);
    final municipiosAsync = _idDepartamento != null
        ? ref.watch(municipiosProvider(_idDepartamento!))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar finca')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: 'Nombre de la finca *',
              hint: 'Ej: Finca El Cedro',
              controller: _nombreCtrl,
              validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Propietario *',
              hint: 'Nombre del propietario',
              controller: _propietarioCtrl,
              validator: (v) => v == null || v.trim().isEmpty ? 'El propietario es requerido' : null,
            ),
            const SizedBox(height: 14),

            // Departamento
            deptosAsync.when(
              loading: () => const CenteredLoader(),
              error: (_, __) => const Text('Error al cargar departamentos'),
              data: (deptos) => AppDropdown<int>(
                label: 'Departamento *',
                value: _idDepartamento,
                items: deptos.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre))).toList(),
                onChanged: (v) => setState(() {
                  _idDepartamento = v;
                  _idMunicipio = null;
                }),
              ),
            ),
            const SizedBox(height: 14),

            // Municipio (dependiente del departamento)
            if (_idDepartamento != null)
              municipiosAsync!.when(
                loading: () => const CenteredLoader(),
                error: (_, __) => const Text('Error al cargar municipios'),
                data: (muns) => AppDropdown<int>(
                  label: 'Municipio *',
                  value: _idMunicipio,
                  items: muns.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
                  onChanged: (v) => setState(() => _idMunicipio = v),
                ),
              )
            else
              AbsorbPointer(
                child: AppDropdown<int>(
                  label: 'Municipio *',
                  value: null,
                  items: const [],
                  onChanged: (_) {},
                ),
              ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Dirección / Vereda',
              hint: 'Ej: Vereda La Pradera, km 5',
              controller: _direccionCtrl,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Área (hectáreas)',
              hint: 'Ej: 12.5',
              controller: _areaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Ingresa un número válido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Descripción',
              hint: 'Información general de la finca...',
              controller: _descripcionCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Registrar finca'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}
