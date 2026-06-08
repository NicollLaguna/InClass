import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'my_courses_screen.dart';
import 'join_course_screen.dart';
import 'attendance_screen.dart';
import 'history_screen.dart';

class EstudianteHomeScreen extends StatefulWidget {
  const EstudianteHomeScreen({super.key});

  @override
  State<EstudianteHomeScreen> createState() => _EstudianteHomeScreenState();
}

class _EstudianteHomeScreenState extends State<EstudianteHomeScreen> {
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
    final firstName = _nombre.isNotEmpty ? _nombre.split(' ')[0] : 'Estudiante';
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

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.glowBlue,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 24),
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
                          Text('Panel Estudiante',
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

                // AI banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glowCardDecoration,
                  child: Row(
                    children: [
                      const Icon(Icons.face_retouching_natural,
                          color: AppTheme.secondary, size: 20),
                      const Gap(10),
                      Text('Asistencia por reconocimiento facial',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const Gap(24),

                Text('¿Qué deseas hacer?',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    )).animate().fadeIn(delay: 250.ms),

                const Gap(14),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      _MenuCard(
                        icon: Icons.book_rounded,
                        title: 'Mis Cursos',
                        subtitle: 'Ver mis materias',
                        color: AppTheme.secondary,
                        delay: 300,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => MyCoursesScreen())),
                      ),
                      _MenuCard(
                        icon: Icons.add_circle_rounded,
                        title: 'Unirse a Curso',
                        subtitle: 'Ingresar código',
                        color: AppTheme.primary,
                        delay: 380,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const JoinCourseScreen())),
                      ),
                      _MenuCard(
                        icon: Icons.face_retouching_natural,
                        title: 'Registrar Asistencia',
                        subtitle: 'Sesión activa',
                        color: AppTheme.success,
                        delay: 460,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                      ),
                      _MenuCard(
                        icon: Icons.history_rounded,
                        title: 'Mi Historial',
                        subtitle: 'Ver asistencias',
                        color: AppTheme.warning,
                        delay: 540,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen())),
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
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
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
