import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String? cursoId;
  final String? cursoNombre;

  const AttendanceScreen({super.key, this.cursoId, this.cursoNombre});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _cursos = [];
  String? _selectedCursoId;
  String? _selectedCursoNombre;
  bool _isLoading = true;
  bool _procesando = false;
  Map<String, dynamic>? _sesionActiva;
  String? _resultado;
  bool _resultadoExito = false;
  int _segundosRestantes = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.cursoId != null) {
      _selectedCursoId = widget.cursoId;
      _selectedCursoNombre = widget.cursoNombre;
      _checkSession();
    } else {
      _loadCourses();
    }
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

  Future<void> _checkSession() async {
    if (_selectedCursoId == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getActiveSession(_selectedCursoId!);
      setState(() {
        _sesionActiva = result['activa'] == true ? result : null;
        _isLoading = false;
      });
      if (_sesionActiva != null && _sesionActiva!['ventana_abierta'] == true) {
        _startCountdown(_sesionActiva!['minutos_restantes'] ?? 15);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startCountdown(int minutos) {
    _countdownTimer?.cancel();
    _segundosRestantes = minutos * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        _countdownTimer?.cancel();
        _checkSession();
      }
    });
  }

  String get _tiempoRestante {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  Future<void> _captureAndRecognize() async {
    if (_sesionActiva == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 640,
    );
    if (picked == null) return;

    setState(() {
      _procesando = true;
      _resultado = null;
    });

    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Frame = base64Encode(bytes);

      final result = await ApiService.recognizeFrame(
        sesionId: _sesionActiva!['sesion_id'],
        base64Frame: base64Frame,
      );

      if (result.containsKey('mensaje')) {
        setState(() {
          _resultado = '✅ ${result['mensaje']}\n'
              'Curso: ${result['curso']}\n'
              'Hora: ${result['hora']}\n'
              'Confianza: ${result['confianza']}';
          _resultadoExito = true;
        });
        _countdownTimer?.cancel();
        _checkSession();
      } else {
        setState(() {
          _resultado = result['detail'] ?? 'Error en el reconocimiento.';
          _resultadoExito = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultado = 'Error de conexión con el servidor.';
        _resultadoExito = false;
      });
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_selectedCursoNombre ?? 'Registrar Asistencia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedCursoId == null
              ? _buildCourseSelector()
              : _buildAttendanceView(),
    );
  }

  Widget _buildCourseSelector() {
    if (_cursos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: AppTheme.textSecondary),
            const Gap(16),
            Text('No tienes cursos activos',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona tu curso',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              )),
          const Gap(16),
          Expanded(
            child: ListView.builder(
              itemCount: _cursos.length,
              itemBuilder: (context, index) {
                final matricula = _cursos[index];
                final curso = matricula['cursos'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.book_rounded, color: AppTheme.success),
                    ),
                    title: Text(curso['nombre'] ?? '',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      setState(() {
                        _selectedCursoId = curso['id'];
                        _selectedCursoNombre = curso['nombre'];
                      });
                      _checkSession();
                    },
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 80));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Sin sesión activa
          if (_sesionActiva == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.orange, size: 48),
                  const Gap(12),
                  Text('Sin sesión activa',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                        fontSize: 18,
                      )),
                  const Gap(8),
                  Text(
                    'El docente aún no ha iniciado la sesión para este curso.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const Gap(16),
                  ElevatedButton.icon(
                    onPressed: _checkSession,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text('Verificar',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              ),
            ).animate().fadeIn(),

          // Sesión activa
          if (_sesionActiva != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _sesionActiva!['ventana_abierta'] == true
                    ? AppTheme.success.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _sesionActiva!['ventana_abierta'] == true
                      ? AppTheme.success
                      : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _sesionActiva!['ventana_abierta'] == true
                        ? Icons.radio_button_checked
                        : Icons.timer_off_rounded,
                    color: _sesionActiva!['ventana_abierta'] == true
                        ? AppTheme.success
                        : Colors.orange,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sesionActiva!['ventana_abierta'] == true
                              ? 'Sesión activa'
                              : 'Ventana cerrada',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: _sesionActiva!['ventana_abierta'] == true
                                ? AppTheme.success
                                : Colors.orange,
                          ),
                        ),
                        Text(
                          _sesionActiva!['ya_registro'] == true
                              ? '✅ Ya registraste asistencia'
                              : _sesionActiva!['ventana_abierta'] == true
                                  ? '⏱ Tiempo restante: $_tiempoRestante'
                                  : 'Ventana de 15 min cerrada',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _segundosRestantes < 60
                                ? AppTheme.error
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const Gap(24),

            // Ya registrado
            if (_sesionActiva!['ya_registro'] == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 56),
                    const Gap(12),
                    Text('¡Asistencia registrada!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                          fontSize: 18,
                        )),
                    const Gap(8),
                    Text('Ya registraste tu asistencia en esta sesión.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ).animate().fadeIn(),

            // Botón capturar
            if (_sesionActiva!['ya_registro'] != true &&
                _sesionActiva!['ventana_abierta'] == true) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.face_retouching_natural,
                        size: 64,
                        color: AppTheme.secondary.withOpacity(0.5)),
                    const Gap(16),
                    Text(
                      'Apunta la cámara a tu rostro para registrar tu asistencia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _procesando ? null : _captureAndRecognize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _procesando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 28),
                  label: Text(
                    _procesando ? 'Procesando...' : 'Capturar Rostro',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ],

          // Resultado
          if (_resultado != null) ...[
            const Gap(16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _resultadoExito
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _resultadoExito ? AppTheme.success : AppTheme.error,
                ),
              ),
              child: Text(
                _resultado!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _resultadoExito ? AppTheme.success : AppTheme.error,
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ],
      ),
    );
  }
}