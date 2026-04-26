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
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ApiService.getSessionData();
    setState(() {
      _nombre = data['nombre'] ?? '';
      _email = data['email'] ?? '';
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(8),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school,
                        color: Colors.white, size: 28),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, ${_nombre.split(' ')[0]}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            )),
                        Text('Panel Docente',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),

              const Gap(8),
              Text(_email,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )).animate().fadeIn(delay: 200.ms),

              const Gap(32),

              Text('¿Qué deseas hacer?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )).animate().fadeIn(delay: 300.ms),

              const Gap(16),

            Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _MenuCard(
                      icon: Icons.book_rounded,
                      title: 'Mis\nCursos',
                      subtitle: 'Gestionar cursos',
                      color: AppTheme.secondary,
                      delay: 400,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoursesScreen()),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.people_rounded,
                      title: 'Solicitudes\nPendientes',
                      subtitle: 'Aprobar matrículas',
                      color: AppTheme.warning,
                      delay: 500,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PendingEnrollmentsScreen()),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.play_circle_rounded,
                      title: 'Iniciar\nSesión',
                      subtitle: 'Habilitar asistencia',
                      color: AppTheme.success,
                      delay: 600,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SelectCourseSessionScreen()),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Reportes',
                      subtitle: 'Ver y descargar',
                      color: AppTheme.accent,
                      delay: 700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsDocenteScreen()),
                      ),
                    ),
                  ],
                ),
              ),  
            ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  )),
              const Gap(4),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.2);
  }
}