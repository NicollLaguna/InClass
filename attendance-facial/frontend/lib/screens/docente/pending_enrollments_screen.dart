import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class PendingEnrollmentsScreen extends StatefulWidget {
  const PendingEnrollmentsScreen({super.key});

  @override
  State<PendingEnrollmentsScreen> createState() =>
      _PendingEnrollmentsScreenState();
}

class _PendingEnrollmentsScreenState extends State<PendingEnrollmentsScreen> {
  List<dynamic> _cursos = [];
  Map<String, List<dynamic>> _solicitudesPorCurso = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cursosResult = await ApiService.getMyCourses();
      final cursos = cursosResult['cursos'] ?? [];
      final Map<String, List<dynamic>> solicitudes = {};

      for (final curso in cursos) {
        final result = await ApiService.getPendingEnrollments(curso['id']);
        final pending = result['solicitudes'] ?? [];
        if (pending.isNotEmpty) {
          solicitudes[curso['id']] = pending;
        }
      }

      setState(() {
        _cursos = cursos;
        _solicitudesPorCurso = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(String matriculaId) async {
    await ApiService.approveEnrollment(matriculaId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Matrícula aprobada ✓', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _reject(String matriculaId) async {
    await ApiService.rejectEnrollment(matriculaId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Matrícula rechazada', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSolicitudes =
        _solicitudesPorCurso.values.fold(0, (a, b) => a + b.length);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalSolicitudes == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: AppTheme.success),
                      const Gap(16),
                      Text('No hay solicitudes pendientes',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cursos.length,
                  itemBuilder: (context, index) {
                    final curso = _cursos[index];
                    final solicitudes =
                        _solicitudesPorCurso[curso['id']] ?? [];
                    if (solicitudes.isEmpty) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.book_rounded,
                                  color: AppTheme.secondary, size: 18),
                              const Gap(8),
                              Text(curso['nombre'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  )),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${solicitudes.length}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        ...solicitudes.map((s) {
                          final est = s['estudiantes'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.orange.withOpacity(0.1),
                                  child: Text(
                                    (est['nombre'] as String)[0].toUpperCase(),
                                    style:
                                        const TextStyle(color: Colors.orange),
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(est['nombre'],
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600)),
                                      Text(est['codigo'],
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _approve(s['id']),
                                  icon: const Icon(Icons.check_circle,
                                      color: AppTheme.success, size: 28),
                                ),
                                IconButton(
                                  onPressed: () => _reject(s['id']),
                                  icon: const Icon(Icons.cancel,
                                      color: AppTheme.error, size: 28),
                                ),
                              ],
                            ),
                          ).animate().fadeIn();
                        }),
                        const Divider(),
                      ],
                    );
                  },
                ),
    );
  }
}