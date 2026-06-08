import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'courses_screen.dart';
import 'pending_enrollments_screen.dart';
import 'select_course_session_screen.dart';
import 'reports_docente_screen.dart';

class DocenteHomeScreen extends StatefulWidget {
  const DocenteHomeScreen({super.key});

  @override
  State<DocenteHomeScreen> createState() => _DocenteHomeScreenState();
}

class _DocenteHomeScreenState extends State<DocenteHomeScreen> {
  String _nombre = '';
  String _email  = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ApiService.getSessionData();
    setState(() {
      _nombre = data['nombre'] ?? '';
      _email  = data['email']  ?? '';
    });
  }

  Future<void> _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _nombre.isNotEmpty ? _nombre.split(' ')[0] : 'Docente';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(20),

                // Header con ícono real de la app
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.glowBlue,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hola, $firstName',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              )),
                          Text('Panel Docente',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.secondary,
                              )),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppTheme.textSecondary, size: 22),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),

                const Gap(4),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Text(_email,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ).animate().fadeIn(delay: 150.ms),

                const Gap(28),

                Text('¿Qué deseas hacer?',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    )).animate().fadeIn(delay: 200.ms),

                const Gap(14),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      _MenuCard(
                        icon: Icons.book_rounded,
                        imagePath: 'assets/icons/ic_cursos.png',
                        title: 'Mis Cursos',
                        subtitle: 'Gestionar cursos',
                        color: AppTheme.primary,
                        delay: 250,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CoursesScreen())),
                      ),
                      _MenuCard(
                        icon: Icons.people_rounded,
                        imagePath: 'assets/icons/ic_solicitudes.png',
                        title: 'Solicitudes',
                        subtitle: 'Aprobar matrículas',
                        color: AppTheme.warning,
                        delay: 330,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PendingEnrollmentsScreen())),
                      ),
                      _MenuCard(
                        icon: Icons.play_circle_rounded,
                        imagePath: 'assets/icons/ic_sesion.png',
                        title: 'Iniciar Sesión',
                        subtitle: 'Habilitar asistencia',
                        color: AppTheme.success,
                        delay: 410,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SelectCourseSessionScreen())),
                      ),
                      _MenuCard(
                        icon: Icons.bar_chart_rounded,
                        imagePath: 'assets/icons/ic_reportes.png',
                        title: 'Reportes',
                        subtitle: 'Ver y descargar',
                        color: AppTheme.secondary,
                        delay: 490,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ReportsDocenteScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              padding: imagePath != null ? EdgeInsets.zero : const EdgeInsets.all(10),
              decoration: imagePath != null
                  ? null
                  : BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: 52,
                      height: 52,
                      errorBuilder: (ctx, err, st) => Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                    )
                  : Icon(icon, color: color, size: 26),
            ),
            const Spacer(),
            Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                )),
            const Gap(3),
            Text(subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.15);
  }
}
