import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class RegisterScreenDocente extends StatefulWidget {
  const RegisterScreenDocente({super.key});

  @override
  State<RegisterScreenDocente> createState() => _RegisterScreenDocenteState();
}

class _RegisterScreenDocenteState extends State<RegisterScreenDocente> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _confirmed = false;
  String? _error;
  String? _success;

  void _showConfirmDialog() {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() => _error = null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const Gap(8),
            Text('Confirma tus datos',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Nombre', value: _nombreController.text),
                  const Gap(8),
                  _InfoRow(label: 'Email', value: _emailController.text),
                ],
              ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                '⚠️ Una vez registrado, estos datos no podrán modificarse. Verifica que todo sea correcto.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[800]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _register();
            },
            child: Text('Confirmar ✓', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.registerDocente(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.containsKey('mensaje')) {
        setState(() => _success = result['mensaje']);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() => _error = result['detail'] ?? 'Error al registrar.');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Registro Docente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, color: AppTheme.primary, size: 48),
              ),
            ).animate().fadeIn().scale(),

            const Gap(32),

            _Label('Nombre completo'),
            const Gap(8),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                hintText: 'Ej: María García López',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const Gap(16),
            _Label('Correo electrónico'),
            const Gap(8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'correo@universidad.edu.co',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const Gap(16),
            _Label('Contraseña'),
            const Gap(8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            const Gap(8),
            Text(
              '• Mínimo 8 caracteres  • Una mayúscula  • Un número  • Un carácter especial',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),

            const Gap(16),
            _Label('Confirmar contraseña'),
            const Gap(8),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Repite la contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),

            const Gap(24),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error),
                ),
                child: Text(_error!,
                    style: GoogleFonts.poppins(
                        color: AppTheme.error, fontSize: 13)),
              ).animate().fadeIn(),

            if (_success != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success),
                ),
                child: Text(_success!,
                    style: GoogleFonts.poppins(
                        color: AppTheme.success, fontSize: 13)),
              ).animate().fadeIn(),

            const Gap(24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showConfirmDialog,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Registrarme',
                        style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      );
}