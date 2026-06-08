import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'attendance_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<dynamic> _cursos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getMyEnrollments();
      setState(() {
        _cursos = result['cursos'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCourses),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cursos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined,
                          size: 64, color: AppTheme.textSecondary),
                      const Gap(16),
                      Text('No estás matriculado en ningún curso',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                      const Gap(8),
                      Text('Usa el código de acceso para unirte',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cursos.length,
                  itemBuilder: (context, index) {
                    final matricula = _cursos[index];
                    final curso = matricula['cursos'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.book_rounded,
                              color: AppTheme.secondary),
                        ),
                        title: Text(curso['nombre'] ?? '',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          curso['descripcion'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceScreen(
                                cursoId: curso['id'],
                                cursoNombre: curso['nombre'],
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Asistir',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    ).animate().fadeIn(
                        delay: Duration(milliseconds: index * 80));
                  },
                ),
    );
  }
}