import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'register_screen_docente.dart';
import 'register_screen_estudiante.dart';
import 'docente/docente_home_screen.dart';
import 'estudiante/estudiante_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  final String? prefillPassword;
  final String? prefillRole;

  const LoginScreen({
    super.key,
    this.prefillEmail,
    this.prefillPassword,
    this.prefillRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'estudiante';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
    if (widget.prefillPassword != null) {
      _passwordController.text = widget.prefillPassword!;
    }
    if (widget.prefillRole != null) {
      _selectedRole = widget.prefillRole!;
    }
  }

Future<void> _login() async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    setState(() => _error = 'Completa todos los campos.');
    return;
  }
  setState(() {
    _isLoading = true;
    _error = null;
  });
  try {
    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );
    if (result.containsKey('token')) {
      await ApiService.saveSession(result);

      // Guarda FCM token después del login
      try {
        final prefs = await SharedPreferences.getInstance();
        final fcmToken = prefs.getString('fcm_token');
        if (fcmToken != null) {
          await ApiService.saveFcmToken(fcmToken);
          print('FCM token guardado en backend ✅');
        }
      } catch (e) {
        print('Error guardando FCM token: $e');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _selectedRole == 'docente'
              ? const DocenteHomeScreen()
              : const EstudianteHomeScreen(),
        ),
      );
    } else {
      setState(() => _error = result['detail'] ?? 'Credenciales incorrectas.');
    }
  } catch (e) {
    setState(() => _error = 'Error de conexión con el servidor.');
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Gap(40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 48),
              ).animate().fadeIn(duration: 600.ms).scale(),

              const Gap(20),
              Text('InClass',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  )).animate().fadeIn(delay: 200.ms),

              Text('Control de Asistencia Facial',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  )).animate().fadeIn(delay: 300.ms),

              const Gap(40),

              // Role selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _RoleButton(
                      label: 'Estudiante',
                      icon: Icons.person,
                      selected: _selectedRole == 'estudiante',
                      onTap: () => setState(() => _selectedRole = 'estudiante'),
                    ),
                    _RoleButton(
                      label: 'Docente',
                      icon: Icons.school,
                      selected: _selectedRole == 'docente',
                      onTap: () => setState(() => _selectedRole = 'docente'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Gap(24),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 500.ms),

              const Gap(12),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const Gap(8),

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
                ).animate().fadeIn().slideY(begin: 0.2),

              const Gap(24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Iniciar Sesión',
                          style: GoogleFonts.poppins(fontSize: 16)),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const Gap(24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta? ',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _selectedRole == 'docente'
                            ? const RegisterScreenDocente()
                            : const RegisterScreenEstudiante(),
                      ),
                    ),
                    child: Text('Regístrate',
                        style: GoogleFonts.poppins(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  size: 20),
              const Gap(8),
              Text(label,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}