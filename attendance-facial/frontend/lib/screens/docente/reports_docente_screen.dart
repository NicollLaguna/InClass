import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:open_file/open_file.dart';

class ReportsDocenteScreen extends StatefulWidget {
  const ReportsDocenteScreen({super.key});

  @override
  State<ReportsDocenteScreen> createState() => _ReportsDocenteScreenState();
}

class _ReportsDocenteScreenState extends State<ReportsDocenteScreen> {
  List<dynamic> _cursos = [];
  Map<String, List<dynamic>> _sesionesPorCurso = {};
  bool _isLoading = true;
  String? _downloading;

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
      final Map<String, List<dynamic>> sesiones = {};

      for (final curso in cursos) {
        final result = await ApiService.getCourseSessions(curso['id']);
        final s = result['sesiones'] ?? [];
        if (s.isNotEmpty) sesiones[curso['id']] = s;
      }

      setState(() {
        _cursos = cursos;
        _sesionesPorCurso = sesiones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReport(
    String sesionId, String cursoNombre, String fecha) async {
  setState(() => _downloading = sesionId);
  try {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/reports/generate/$sesionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      _showSnack('No hay asistencia en esta sesión.', isError: true);
      return;
    }

    // Guarda en directorio temporal primero
    final dir = await getTemporaryDirectory();
    final filename =
        'asistencia_${cursoNombre}_$fecha.xlsx'.replaceAll(' ', '_');
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(response.bodyBytes);

    // Abre el archivo directamente
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      _showSnack('No se encontró app para abrir Excel. Archivo guardado en: ${file.path}', isError: true);
    }

  } catch (e) {
    _showSnack('Error: $e', isError: true);
  } finally {
    setState(() => _downloading = null);
  }
}

  Future<int> _getAndroidVersion() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sesionesPorCurso.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 64, color: AppTheme.textSecondary),
                      const Gap(16),
                      Text('No hay sesiones registradas',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cursos.length,
                  itemBuilder: (context, courseIndex) {
                    final curso = _cursos[courseIndex];
                    final sesiones = _sesionesPorCurso[curso['id']] ?? [];
                    if (sesiones.isEmpty) return const SizedBox();

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
                                    fontSize: 15,
                                  )),
                            ],
                          ),
                        ),
                        ...sesiones.map((s) {
                          final activa = s['activa'] ?? false;
                          final isDownloading = _downloading == s['id'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: activa
                                        ? AppTheme.success.withOpacity(0.1)
                                        : AppTheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    activa
                                        ? Icons.radio_button_checked
                                        : Icons.history,
                                    color: activa
                                        ? AppTheme.success
                                        : AppTheme.secondary,
                                    size: 20,
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s['fecha'] ?? '',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                        activa
                                            ? '🟢 Activa'
                                            : '⚫ Finalizada',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: activa
                                              ? AppTheme.success
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!activa)
                                  isDownloading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : IconButton(
                                          onPressed: () => _downloadReport(
                                            s['id'],
                                            curso['nombre'],
                                            s['fecha'],
                                          ),
                                          icon: const Icon(
                                              Icons.download_rounded,
                                              color: AppTheme.secondary),
                                          tooltip: 'Descargar Excel',
                                        ),
                                if (activa)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('En curso',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.orange,
                                        )),
                                  ),
                              ],
                            ),
                          ).animate().fadeIn(
                              delay: Duration(
                                  milliseconds: courseIndex * 60));
                        }),
                        const Divider(),
                      ],
                    );
                  },
                ),
    );
  }
}