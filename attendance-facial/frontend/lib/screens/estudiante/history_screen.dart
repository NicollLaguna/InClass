import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _registros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getAttendanceHistory();
      setState(() {
        _registros = result['registros'] ?? [];
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
        title: const Text('Mi Historial'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
                      const Gap(16),
                      Text('No tienes registros de asistencia',
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 40),
                            const Gap(16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total asistencias',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 13)),
                                Text('${_registros.length}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _registros.length,
                        itemBuilder: (context, index) {
                          final r = _registros[index];
                          final sesion = r['sesiones'];
                          final curso = sesion?['cursos'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.success.withOpacity(0.1),
                                child: const Icon(Icons.check,
                                    color: AppTheme.success),
                              ),
                              title: Text(
                                curso?['nombre'] ?? 'Curso',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Fecha: ${r['fecha']}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(r['hora'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      )),
                                  Text(
                                    '${((r['confianza'] ?? 0) * 100).toInt()}% conf.',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(
                              delay: Duration(milliseconds: index * 50));
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}