import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';
import 'estudiante/estudiante_home_screen.dart';

class RegisterScreenEstudiante extends StatefulWidget {
  const RegisterScreenEstudiante({super.key});

  @override
  State<RegisterScreenEstudiante> createState() =>
      _RegisterScreenEstudianteState();
}

class _RegisterScreenEstudianteState extends State<RegisterScreenEstudiante> {
  final _nombreController   = TextEditingController();
  final _codigoController   = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  final List<File> _fotos = [];
  static const int _totalFotos = 5;

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  String? _error;
  String _loadingMsg    = '';

  // ── Cámara ─────────────────────────────────────────────
  CameraController? _cameraController;
  bool _cameraReady    = false;
  bool _capturando     = false;
  int _cuenta          = 0; // countdown antes de cada foto

  static const List<String> _instrucciones = [
    'Mira directo a la cámara',
    'Gira levemente a la izquierda',
    'Gira levemente a la derecha',
    'Inclina la cabeza hacia arriba',
    'Inclina la cabeza hacia abajo',
  ];

  Future<void> _abrirCamara() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } catch (_) {}
  }

  void _cerrarCamara() {
    _cameraController?.dispose();
    _cameraController = null;
    if (mounted) setState(() => _cameraReady = false);
  }

  Future<void> _capturarSiguiente() async {
    if (_capturando || _fotos.length >= _totalFotos) return;
    setState(() => _capturando = true);

    // Cuenta regresiva 3-2-1
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _cuenta = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() => _cuenta = 0);

    try {
      final XFile file = await _cameraController!.takePicture();
      if (!mounted) return;
      setState(() {
        _fotos.add(File(file.path));
        _error = null;
      });

      if (_fotos.length >= _totalFotos) {
        _cerrarCamara();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al tomar la foto.');
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  void _eliminarFoto(int index) {
    setState(() => _fotos.removeAt(index));
  }

  // ── Validación ─────────────────────────────────────────

  String? _checkPassword(String pw) {
    if (pw.length < 8)                             return 'Mínimo 8 caracteres.';
    if (!pw.contains(RegExp(r'[A-Z]')))            return 'Debe incluir al menos una mayúscula.';
    if (!pw.contains(RegExp(r'[a-z]')))            return 'Debe incluir al menos una minúscula.';
    if (!pw.contains(RegExp(r'[0-9]')))            return 'Debe incluir al menos un número.';
    if (!pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Debe incluir al menos un símbolo (!@#\$%...).';
    }
    return null;
  }

  void _validarYConfirmar() {
    if (_nombreController.text.trim().isEmpty ||
        _codigoController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }
    if (_codigoController.text.length != 12 ||
        !RegExp(r'^\d+$').hasMatch(_codigoController.text)) {
      setState(() => _error = 'El código debe tener exactamente 12 dígitos.');
      return;
    }
    final pwError = _checkPassword(_passwordController.text);
    if (pwError != null) {
      setState(() => _error = pwError);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    if (_fotos.length < _totalFotos) {
      setState(() => _error = 'Toma las $_totalFotos fotos faciales antes de continuar.');
      return;
    }
    setState(() => _error = null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const Gap(8),
          Text('Confirma tus datos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Nombre', value: _nombreController.text),
                  const Gap(6),
                  _InfoRow(label: 'Código', value: _codigoController.text),
                  const Gap(6),
                  _InfoRow(label: 'Email', value: _emailController.text),
                  const Gap(6),
                  _InfoRow(label: 'Fotos', value: '${_fotos.length} de $_totalFotos'),
                ],
              ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                'Una vez registrado, tus datos no podrán modificarse. Verifica que todo sea correcto.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[800]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _register(); },
            child: Text('Confirmar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // ── Registro ───────────────────────────────────────────

  Future<void> _register() async {
    setState(() { _isLoading = true; _loadingMsg = 'Creando cuenta...'; });
    try {
      final authResult = await ApiService.registerEstudiante(
        nombre:   _nombreController.text.trim(),
        codigo:   _codigoController.text.trim(),
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!authResult.containsKey('mensaje')) {
        setState(() => _error = authResult['detail'] ?? 'Error al registrar.');
        return;
      }

      setState(() => _loadingMsg = 'Procesando fotos faciales...\n(la primera vez puede tardar 1-2 min)');

      final fotoResult = await ApiService.registerStudent(
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim(),
        fotos:  _fotos,
      );

      final fotoOk = fotoResult.containsKey('mensaje') ||
          (fotoResult['detail']?.toString().toLowerCase().contains('registrado') == true);

      if (fotoOk) {
        if (!mounted) return;
        final loginResult = await ApiService.login(
          email:    _emailController.text.trim(),
          password: _passwordController.text,
          role:     'estudiante',
        );
        if (!mounted) return;
        if (loginResult.containsKey('token')) {
          await ApiService.saveSession(loginResult);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const EstudianteHomeScreen()),
            (_) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                prefillEmail:    _emailController.text.trim(),
                prefillPassword: _passwordController.text,
                prefillRole:     'estudiante',
              ),
            ),
          );
        }
      } else {
        setState(() => _error = fotoResult['detail'] ?? 'Error al registrar fotos.');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Registro Estudiante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFotosSection(),

            if (!_cameraReady) ...[
              const Gap(24),

              _Label('Nombre completo'),
              const Gap(8),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  hintText: 'Ej: María García López',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const Gap(16),
              _Label('Código estudiantil (12 dígitos)'),
              const Gap(8),
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  hintText: 'Ej: 085400412023',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
                maxLength: 12,
              ),

              _Label('Correo electrónico'),
              const Gap(8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'correo@universidad.edu.co',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const Gap(16),
              _Label('Contraseña'),
              const Gap(8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Mínimo 8 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const Gap(6),
              Text(
                '• Mín. 8 caracteres  • Una mayúscula  • Un número  • Un carácter especial',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
              ),

              const Gap(16),
              _Label('Confirmar contraseña'),
              const Gap(8),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Repite la contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),

              const Gap(24),
            ],

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error),
                ),
                child: Text(_error!,
                    style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 13)),
              ).animate().fadeIn(),

            const Gap(16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validarYConfirmar,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(_loadingMsg,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.white),
                                textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : Text('Registrarme',
                        style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ),

            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildFotosSection() {
    final tomadas = _fotos.length;
    final completo = tomadas >= _totalFotos;
    final instruccion = tomadas < _instrucciones.length
        ? _instrucciones[tomadas]
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completo ? AppTheme.success : AppTheme.secondary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.face_retouching_natural,
                  color: completo ? AppTheme.success : AppTheme.secondary),
              const Gap(8),
              Expanded(
                child: Text(
                  completo
                      ? '¡Fotos completas! Mejor precisión garantizada.'
                      : 'Registra $_totalFotos fotos de tu rostro ($tomadas/$_totalFotos)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: completo ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const Gap(8),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tomadas / _totalFotos,
              backgroundColor: AppTheme.border,
              color: completo ? AppTheme.success : AppTheme.secondary,
              minHeight: 6,
            ),
          ),

          const Gap(12),

          // Vista de cámara en vivo
          if (_cameraReady && _cameraController != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: CameraPreview(_cameraController!),
                  ),
                  // Countdown overlay
                  if (_cuenta > 0)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withValues(alpha: 0.4),
                      alignment: Alignment.center,
                      child: Text(
                        '$_cuenta',
                        style: GoogleFonts.poppins(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                  // Instrucción y botón
                  if (_cuenta == 0)
                    Positioned(
                      bottom: 10,
                      left: 8,
                      right: 8,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              instruccion,
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Gap(6),
                          ElevatedButton.icon(
                            onPressed: _capturando ? null : _capturarSiguiente,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 18),
                            label: Text(
                              _capturando
                                  ? 'Procesando...'
                                  : 'Tomar foto ${tomadas + 1}/$_totalFotos',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Gap(12),
          ],

          // Miniaturas de fotos tomadas
          if (tomadas > 0) ...[
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tomadas,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_fotos[i],
                          width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _eliminarFoto(i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(12),
          ],

          // Recomendaciones antes de abrir la cámara
          if (!_cameraReady && !completo) ...[
            _buildRecomendaciones(),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _abrirCamara,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.secondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(Icons.camera_alt_outlined, color: AppTheme.secondary),
                label: Text(
                  'Abrir cámara para tomar fotos',
                  style: GoogleFonts.poppins(color: AppTheme.secondary),
                ),
              ),
            ),
          ],

          if (!completo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tip: frente, izq., der., arriba, abajo — varía el ángulo',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildRecomendaciones() {
    const items = [
      (Icons.wb_sunny_outlined,       'Busca un lugar bien iluminado',          Colors.amber),
      (Icons.face_outlined,            'Mira directo a la cámara, sin inclinar', Colors.blue),
      (Icons.do_not_disturb_on_outlined, 'Retira gafas, gorra o mascarilla',    Colors.red),
      (Icons.crop_free_rounded,        'Encuadra solo tu rostro en la pantalla', Colors.teal),
      (Icons.accessibility_new_rounded,'Mantén el celular a la altura de tus ojos', Colors.purple),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: Colors.blue, size: 16),
              const Gap(6),
              Text(
                'Recomendaciones para mejor precisión',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const Gap(8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(item.$1, size: 16, color: item.$3),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
              child: Text(value, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      );
}
