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
    if (widget.prefillEmail != null)
      _emailController.text = widget.prefillEmail!;
    if (widget.prefillPassword != null)
      _passwordController.text = widget.prefillPassword!;
    if (widget.prefillRole != null) _selectedRole = widget.prefillRole!;
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
        try {
          final prefs = await SharedPreferences.getInstance();
          final fcmToken = prefs.getString('fcm_token');
          if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
        } catch (_) {}
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
        setState(
          () => _error = result['detail'] ?? 'Credenciales incorrectas.',
        );
      }
    } catch (_) {
      setState(() => _error = 'Error de conexión con el servidor.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Gap(48),

                // Logo
                Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.glowBlue,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.face_retouching_natural,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),

                const Gap(20),

                Text(
                  'InClass',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                Text(
                  'Control de Asistencia con IA',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const Gap(36),

                // Role selector
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _RoleBtn(
                        label: 'Estudiante',
                        icon: Icons.person_rounded,
                        selected: _selectedRole == 'estudiante',
                        onTap: () =>
                            setState(() => _selectedRole = 'estudiante'),
                      ),
                      _RoleBtn(
                        label: 'Docente',
                        icon: Icons.school_rounded,
                        selected: _selectedRole == 'docente',
                        onTap: () => setState(() => _selectedRole = 'docente'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const Gap(20),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const Gap(12),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                if (_error != null) ...[
                  const Gap(12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 16,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                ],

                const Gap(24),

                GradientButton(
                  label: 'Iniciar Sesión',
                  icon: Icons.login_rounded,
                  onPressed: _login,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 700.ms),

                const Gap(28),

                // Register link
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _selectedRole == 'docente'
                                  ? const RegisterScreenDocente()
                                  : const RegisterScreenEstudiante(),
                            ),
                          ),
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.poppins(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms),

                const Gap(32),
              ],
            ),
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

class _RoleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleBtn({
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? AppTheme.glowBlue : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppTheme.textSecondary,
                size: 18,
              ),
              const Gap(6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
