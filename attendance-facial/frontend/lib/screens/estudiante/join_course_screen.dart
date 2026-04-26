import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class JoinCourseScreen extends StatefulWidget {
  const JoinCourseScreen({super.key});

  @override
  State<JoinCourseScreen> createState() => _JoinCourseScreenState();
}

class _JoinCourseScreenState extends State<JoinCourseScreen> {
  final _codigoController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _joinCourse() async {
    if (_codigoController.text.isEmpty) {
      setState(() => _error = 'Ingresa el código de acceso.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      final result = await ApiService.joinCourse(
        codigoAcceso: _codigoController.text.trim().toUpperCase(),
      );
      if (result.containsKey('mensaje')) {
        setState(() => _success = result['mensaje']);
        _codigoController.clear();
      } else {
        setState(() => _error = result['detail'] ?? 'Error al unirse.');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Unirse a Curso')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_circle_rounded,
                    color: AppTheme.primary, size: 56),
              ),
            ).animate().fadeIn().scale(),
            const Gap(32),
            Text('Código de acceso',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                )),
            const Gap(8),
            Text(
              'Solicita el código a tu docente para unirte al curso.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
            const Gap(16),
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(
                hintText: 'Ej: ABC12345',
                prefixIcon: Icon(Icons.key_rounded),
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  letterSpacing: 4, fontWeight: FontWeight.w700),
            ),
            const Gap(24),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error),
                ),
                child: Text(_error!,
                    style: GoogleFonts.poppins(
                        color: AppTheme.error, fontSize: 13)),
              ).animate().fadeIn(),
            if (_success != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success),
                ),
                child: Text(_success!,
                    style: GoogleFonts.poppins(
                        color: AppTheme.success, fontSize: 13)),
              ).animate().fadeIn(),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinCourse,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Solicitar Matrícula',
                        style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }
}