import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'session_screen.dart';

class SelectCourseSessionScreen extends StatefulWidget {
  const SelectCourseSessionScreen({super.key});

  @override
  State<SelectCourseSessionScreen> createState() =>
      _SelectCourseSessionScreenState();
}

class _SelectCourseSessionScreenState
    extends State<SelectCourseSessionScreen> {
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
      final result = await ApiService.getMyCourses();
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
      appBar: AppBar(title: const Text('Seleccionar Curso')),
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
                      Text('No tienes cursos',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Para qué curso deseas iniciar sesión?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          )),
                      const Gap(16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _cursos.length,
                          itemBuilder: (context, index) {
                            final curso = _cursos[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.play_circle_rounded,
                                      color: AppTheme.success),
                                ),
                                title: Text(curso['nombre'] ?? '',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  curso['descripcion'] ?? '',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SessionScreen(curso: curso),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: index * 80));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}