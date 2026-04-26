import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreenEstudiante extends StatefulWidget {
  const RegisterScreenEstudiante({super.key});

  @override
  State<RegisterScreenEstudiante> createState() =>
      _RegisterScreenEstudianteState();
}

class _RegisterScreenEstudianteState extends State<RegisterScreenEstudiante> {
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _success;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _error = null;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Foto facial',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const Gap(8),
            Text(
              'Usa una foto clara de frente con buena iluminación.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.secondary),
              ),
              title: Text('Tomar foto', style: GoogleFonts.poppins()),
              subtitle: Text('Recomendado',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.success)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: AppTheme.primary),
              ),
              title: Text('Galería', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog() {
    if (_nombreController.text.isEmpty ||
        _codigoController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }
    if (_selectedImage == null) {
      setState(() => _error = 'Selecciona una foto facial.');
      return;
    }
    if (_codigoController.text.length != 12 ||
        !RegExp(r'^\d+$').hasMatch(_codigoController.text)) {
      setState(() => _error = 'El código debe tener exactamente 12 dígitos.');
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
                  _InfoRow(label: 'Código', value: _codigoController.text),
                  const Gap(8),
                  _InfoRow(label: 'Email', value: _emailController.text),
                  const Gap(8),
                  Row(
                    children: [
                      Text('Foto: ',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Icon(Icons.check_circle,
                          color: AppTheme.success, size: 18),
                      Text(' Seleccionada',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppTheme.success)),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                '⚠️ Una vez registrado, tus datos y foto facial no podrán modificarse. Verifica que todo sea correcto.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.orange[800]),
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
      final authResult = await ApiService.registerEstudiante(
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!authResult.containsKey('mensaje')) {
        setState(() => _error = authResult['detail'] ?? 'Error al registrar.');
        return;
      }

      final fotoResult = await ApiService.registerStudent(
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim(),
        foto: _selectedImage!,
      );

      if (fotoResult.containsKey('mensaje')) {
        if (!mounted) return;
        // Muestra éxito y navega al login con campos llenos
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 64),
                const Gap(16),
                Text('¡Registro exitoso!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.success,
                    )),
                const Gap(8),
                Text('Revisa tu email para confirmar tu cuenta.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13)),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // cierra dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          prefillEmail: _emailController.text.trim(),
                          prefillPassword: _passwordController.text,
                          prefillRole: 'estudiante',
                        ),
                      ),
                    );
                  },
                  child: Text('Iniciar Sesión',
                      style: GoogleFonts.poppins()),
                ),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = fotoResult['detail'] ?? 'Error al registrar foto.');
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
      appBar: AppBar(title: const Text('Registro Estudiante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Center(
              child: GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.secondary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withOpacity(0.2),
                        blurRadius: 16,
                      ),
                    ],
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                size: 36, color: AppTheme.secondary),
                            const Gap(4),
                            Text('Foto facial',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppTheme.secondary)),
                          ],
                        )
                      : null,
                ),
              ),
            ).animate().fadeIn().scale(),

            const Gap(8),
            Center(
              child: Text('Toca para seleccionar foto de frente',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ),

            const Gap(24),

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
            _Label('Código estudiantil (12 dígitos)'),
            const Gap(8),
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(
                hintText: 'Ej: 085400412023',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
            ),

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
                  color: AppTheme.error.withOpacity(0.1),
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
                  color: AppTheme.success.withOpacity(0.1),
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

            const Gap(24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
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
            child:
                Text(value, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      );
}