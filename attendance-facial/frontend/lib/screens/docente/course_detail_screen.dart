import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> curso;
  const CourseDetailScreen({super.key, required this.curso});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<dynamic> _estudiantes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getCourseStudents(widget.curso['id']);
      setState(() {
        _estudiantes = result['estudiantes'] ?? [];
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
      appBar: AppBar(title: Text(widget.curso['nombre'] ?? '')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estudiantes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: AppTheme.textSecondary),
                      const Gap(16),
                      Text('No hay estudiantes matriculados',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header info curso
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_rounded,
                                color: Colors.white, size: 32),
                            const Gap(12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estudiantes matriculados',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                                Text('${_estudiantes.length}',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.surface,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _estudiantes.length,
                        itemBuilder: (context, index) {
                          final e = _estudiantes[index]['estudiantes'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppTheme.secondary.withValues(alpha: 0.1),
                                  child: Text(
                                    (e['nombre'] as String)[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e['nombre'],
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600)),
                                      Text(e['codigo'],
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                      Text(e['email'],
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle,
                                    color: AppTheme.success, size: 20),
                              ],
                            ),
                          ).animate().fadeIn(
                              delay: Duration(milliseconds: index * 60));
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}