import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String? cursoId;
  final String? cursoNombre;

  const AttendanceScreen({super.key, this.cursoId, this.cursoNombre});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  List<dynamic> _cursos = [];
  String? _selectedCursoId;
  String? _selectedCursoNombre;
  bool _isLoading = true;
  bool _procesando = false;
  String _statusMsg = 'Apunta tu rostro al óvalo';
  Map<String, dynamic>? _sesionActiva;
  String? _resultado;
  bool _resultadoExito = false;
  int _segundosRestantes = 0;
  Timer? _countdownTimer;

  // Camera
  CameraController? _cameraController;
  bool _cameraReady = false;
  Timer? _captureTimer;
  bool _registrado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cursoId != null) {
      _selectedCursoId = widget.cursoId;
      _selectedCursoNombre = widget.cursoNombre;
      _checkSession();
    } else {
      _loadCourses();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
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
      final sesion = result['activa'] == true ? result : null;
      setState(() {
        _sesionActiva = sesion;
        _isLoading = false;
        _registrado = sesion?['ya_registro'] == true;
      });
      if (_sesionActiva != null &&
          _sesionActiva!['ventana_abierta'] == true &&
          !_registrado) {
        _startCountdown(_sesionActiva!['minutos_restantes'] ?? 15);
        await _initCamera();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Prefer front camera
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
      _startAutoCapture();
    } catch (_) {
      // Camera unavailable — fall back silently
    }
  }

  void _startAutoCapture() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!_procesando && !_registrado && mounted) {
        _autoCapture();
      }
    });
  }

  Future<void> _autoCapture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _sesionActiva == null ||
        _procesando ||
        _registrado) {
      return;
    }

    setState(() {
      _procesando = true;
      _statusMsg = 'Capturando imagen...';
    });

    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await File(file.path).readAsBytes();
      final base64Frame = base64Encode(bytes);

      if (mounted) setState(() => _statusMsg = 'Analizando rostro...');

      if (mounted) setState(() => _statusMsg = 'Verificando identidad...');

      final result = await ApiService.recognizeFrame(
        sesionId: _sesionActiva!['sesion_id'],
        base64Frame: base64Frame,
      );

      if (!mounted) return;

      if (result.containsKey('mensaje')) {
        setState(() {
          _resultado = '${result['mensaje']}\n'
              'Curso: ${result['curso']}\n'
              'Hora: ${result['hora']}\n'
              'Confianza: ${result['confianza']}';
          _resultadoExito = true;
          _registrado = true;
        });
        _captureTimer?.cancel();
        _countdownTimer?.cancel();
        _disposeCamera();
        _checkSession();
      } else {
        setState(() {
          _resultado = result['detail'] ?? 'No se pudo reconocer el rostro.';
          _resultadoExito = false;
          _statusMsg = 'Apunta tu rostro al óvalo';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resultado = 'Error de conexión con el servidor.';
          _resultadoExito = false;
          _statusMsg = 'Apunta tu rostro al óvalo';
        });
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _disposeCamera() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _cameraController?.dispose();
    _cameraController = null;
    if (mounted) setState(() => _cameraReady = false);
  }

  void _startCountdown(int minutos) {
    _countdownTimer?.cancel();
    _segundosRestantes = minutos * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        _countdownTimer?.cancel();
        _disposeCamera();
        _checkSession();
      }
    });
  }

  String get _tiempoRestante {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _captureTimer?.cancel();
    _cameraController?.dispose();
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
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
                color: Colors.orange.withValues(alpha: 0.1),
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
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
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
                          _registrado
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
            if (_registrado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
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

            // Visor de cámara con auto-captura
            if (!_registrado && _sesionActiva!['ventana_abierta'] == true) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera preview
                    if (_cameraReady && _cameraController != null)
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CameraPreview(_cameraController!),
                      )
                    else
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          color: Colors.black87,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                  color: Colors.white),
                              const Gap(12),
                              Text('Iniciando cámara...',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),

                    // Overlay: face guide oval
                    Positioned.fill(
                      child: CustomPaint(painter: _FaceOvalPainter()),
                    ),

                    // Scanning indicator
                    Positioned(
                      bottom: 16,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _procesando
                              ? Colors.blue.withValues(alpha: 0.85)
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_procesando)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.face_retouching_natural,
                                  color: Colors.white, size: 16),
                            const Gap(8),
                            Text(
                              _statusMsg,
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),
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
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
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

class _FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final rx = size.width * 0.36;
    final ry = size.height * 0.30;

    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2), paint);

    // Dim overlay outside oval
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final ovalPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    final outerPath = Path.combine(
        PathOperation.difference, Path()..addRect(fullRect), ovalPath);
    canvas.drawPath(outerPath, dimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
