import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'dart:async';

class SessionScreen extends StatefulWidget {
  final Map<String, dynamic> curso;
  const SessionScreen({super.key, required this.curso});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool _sessionActive = false;
  bool _isLoading = false;
  String? _sesionId;
  String? _horaInicio;
  String? _ventanaCierre;
  int _minutosRestantes = 15;
  List<dynamic> _asistentes = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    try {
      final sessions = await ApiService.getCourseSessions(widget.curso['id']);
      final sesiones = sessions['sesiones'] ?? [];
      final activa = sesiones.where((s) => s['activa'] == true).toList();
      if (activa.isNotEmpty) {
        setState(() {
          _sessionActive = true;
          _sesionId = activa[0]['id'];
        });
        _startTimer();
      }
    } catch (e) {}
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.startSession(widget.curso['id']);
      if (result.containsKey('sesion_id')) {
        setState(() {
          _sessionActive = true;
          _sesionId = result['sesion_id'];
          _horaInicio = result['hora_inicio'];
          _ventanaCierre = result['ventana_cierre'];
          _minutosRestantes = result['minutos_disponibles'] ?? 15;
        });
        _startTimer();
        _showSnack('Sesión iniciada ✓ — Ventana de 15 minutos abierta');
      } else {
        _showSnack(result['detail'] ?? 'Error al iniciar sesión.', isError: true);
      }
    } catch (e) {
      _showSnack('Error de conexión.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _endSession() async {
    if (_sesionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Finalizar sesión',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          '¿Estás seguro de finalizar la sesión? Se enviará el resumen por email.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Finalizar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.endSession(_sesionId!);
      _timer?.cancel();
      setState(() {
        _sessionActive = false;
        _sesionId = null;
        _asistentes = [];
        _minutosRestantes = 15;
      });
      _showSnack(
          'Sesión finalizada — ${result['total_asistentes']} asistentes. Revisa tu email.');
    } catch (e) {
      _showSnack('Error al finalizar sesión.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_sesionId == null) return;
      try {
        // Refresca asistentes cada 30 segundos
        final sessions =
            await ApiService.getCourseSessions(widget.curso['id']);
        final sesiones = sessions['sesiones'] ?? [];
        final activa =
            sesiones.where((s) => s['id'] == _sesionId).toList();
        if (activa.isNotEmpty && mounted) {
          setState(() {
            if (_minutosRestantes > 0) _minutosRestantes--;
          });
        }
      } catch (e) {}
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.curso['nombre'] ?? ''),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del curso
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.curso['nombre'] ?? '',
                      style: GoogleFonts.poppins(
                        color: AppTheme.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                  if (widget.curso['descripcion'] != null &&
                      widget.curso['descripcion'].isNotEmpty)
                    Text(widget.curso['descripcion'],
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13)),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Código: ${widget.curso['codigo_acceso']}',
                      style: GoogleFonts.poppins(
                          color: AppTheme.surface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const Gap(24),

            // Estado sesión
            if (_sessionActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.success),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        color: AppTheme.success),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sesión Activa',
                              style: GoogleFonts.poppins(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700,
                              )),
                          if (_horaInicio != null)
                            Text('Inicio: $_horaInicio  |  Cierre: $_ventanaCierre',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _minutosRestantes > 5
                            ? AppTheme.success
                            : AppTheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⏱ $_minutosRestantes min',
                        style: GoogleFonts.poppins(
                            color: AppTheme.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const Gap(16),
            ],

            // Botones
            if (!_sessionActive)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                  label: Text(
                    _isLoading ? 'Iniciando...' : 'Iniciar Sesión',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ).animate().fadeIn(),

            if (_sessionActive)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.stop_rounded,
                      color: Colors.white, size: 28),
                  label: Text(
                    'Finalizar Sesión',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ).animate().fadeIn(),

            const Gap(24),

            // Info ventana
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ℹ️ Información',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700)),
                  const Gap(8),
                  Text(
                    '• Al iniciar la sesión, los estudiantes tendrán 15 minutos para registrar su asistencia.\n'
                    '• Solo estudiantes matriculados en este curso pueden registrar asistencia.\n'
                    '• Al finalizar recibirás un resumen por email.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}