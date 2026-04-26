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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person,
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
                        Text('Panel Estudiante',
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
                      subtitle: 'Ver mis materias',
                      color: AppTheme.secondary,
                      delay: 400,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MyCoursesScreen()),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.add_circle_rounded,
                      title: 'Unirse a\nCurso',
                      subtitle: 'Ingresar código',
                      color: AppTheme.primary,
                      delay: 500,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const JoinCourseScreen()),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.face_retouching_natural,
                      title: 'Registrar\nAsistencia',
                      subtitle: 'Sesión activa',
                      color: AppTheme.success,
                      delay: 600,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendanceScreen()),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.history_rounded,
                      title: 'Mi\nHistorial',
                      subtitle: 'Ver asistencias',
                      color: AppTheme.warning,
                      delay: 700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
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