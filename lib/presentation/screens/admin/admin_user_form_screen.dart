import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class AdminUserFormScreen extends ConsumerStatefulWidget {
  const AdminUserFormScreen({super.key});

  @override
  ConsumerState<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends ConsumerState<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  int _idRol = 2; // 2 = Productor por defecto
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(usuariosProvider.notifier).crearUsuario(
        idRol: _idRol,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.isEmpty ? null : _telefonoCtrl.text.trim(),
      );
      if (mounted) {
        showSuccessSnack(context, 'Usuario creado exitosamente.');
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.admin,
        title: const Text('Nuevo usuario'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rol
            const SectionTitle('Rol del usuario'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _RolCard(
                  label: 'Productor',
                  icon: Icons.person_outline,
                  selected: _idRol == 2,
                  color: AppTheme.primary,
                  onTap: () => setState(() => _idRol = 2),
                )),
                const SizedBox(width: 10),
                Expanded(child: _RolCard(
                  label: 'Administrador',
                  icon: Icons.admin_panel_settings_outlined,
                  selected: _idRol == 1,
                  color: AppTheme.admin,
                  onTap: () => setState(() => _idRol = 1),
                )),
              ],
            ),
            const SizedBox(height: 20),

            const SectionTitle('Datos personales'),
            const SizedBox(height: 10),

            AppTextField(
              label: 'Nombre *',
              controller: _nombreCtrl,
              validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Apellido *',
              controller: _apellidoCtrl,
              validator: (v) => v == null || v.trim().isEmpty ? 'El apellido es requerido' : null,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Correo electrónico *',
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'El correo es requerido';
                if (!v.contains('@')) return 'Formato de correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Teléfono',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Contraseña *',
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'La contraseña es requerida';
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.admin),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear usuario'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}

class _RolCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RolCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color : AppTheme.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: selected ? color : AppTheme.textMuted, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? color : AppTheme.textMuted)),
        ],
      ),
    ),
  );
}
