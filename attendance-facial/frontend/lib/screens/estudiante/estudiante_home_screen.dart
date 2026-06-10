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
    final screenW = MediaQuery.of(context).size.width;
    final cardAspectRatio = ((screenW - 48 - 14) / 2) / 158;
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
                            child: const Icon(Icons.person_rounded,
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

                Text('¿Qué deseas hacer?',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    )).animate().fadeIn(delay: 200.ms),

                const Gap(14),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: cardAspectRatio,
                  children: [
                    _MenuCard(
                      icon: Icons.book_rounded,
                      imagePath: 'assets/icons/ic_cursos.png',
                      title: 'Mis Cursos',
                      subtitle: 'Ver mis materias',
                      color: AppTheme.secondary,
                      delay: 250,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => MyCoursesScreen())),
                    ),
                    _MenuCard(
                      icon: Icons.add_circle_rounded,
                      imagePath: 'assets/icons/ic_unirse.png',
                      title: 'Unirse a Curso',
                      subtitle: 'Ingresar código',
                      color: AppTheme.primary,
                      delay: 330,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const JoinCourseScreen())),
                    ),
                    _MenuCard(
                      icon: Icons.face_retouching_natural,
                      imagePath: 'assets/icons/ic_asistencia.png',
                      title: 'Registrar Asistencia',
                      subtitle: 'Sesión activa',
                      color: AppTheme.success,
                      delay: 410,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                    ),
                    _MenuCard(
                      icon: Icons.history_rounded,
                      imagePath: 'assets/icons/ic_historial.png',
                      title: 'Mi Historial',
                      subtitle: 'Ver asistencias',
                      color: AppTheme.warning,
                      delay: 490,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    ),
                  ],
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
    final screenW = MediaQuery.of(context).size.width;
    final isSmall = screenW < 370;
    final iconSize = isSmall ? 44.0 : 54.0;
    final titleSize = isSmall ? 11.5 : 13.0;
    final subtitleSize = isSmall ? 10.0 : 11.0;
    final vGap = isSmall ? 6.0 : 9.0;

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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: isSmall ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            imagePath != null
                ? Image.asset(
                    imagePath!,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) =>
                        Icon(icon, color: color, size: iconSize - 10),
                  )
                : Icon(icon, color: color, size: iconSize - 10),
            Gap(vGap),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                )),
            const Gap(2),
            Text(subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: subtitleSize,
                  color: AppTheme.textSecondary,
                )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.15);
  }
}
