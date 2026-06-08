import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/docente/docente_home_screen.dart';
import 'screens/estudiante/estudiante_home_screen.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const InClassApp());
}

class InClassApp extends StatelessWidget {
  const InClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InClass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM Token: $fcmToken');
        if (fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', fcmToken);
          final userToken = prefs.getString('token');
          if (userToken != null) {
            await ApiService.saveFcmToken(fcmToken);
          }
        }
      } catch (e) {
        print('FCM token error: $e');
      }

      // Notificaciones con app abierta
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.data['title'] ?? 'InClass';
        final body = message.data['body'] ?? '';
        if (title.isNotEmpty) {
          _showInAppBanner(title, body);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notificación abierta: ${message.data}');
      });
    } catch (e) {
      print('Firebase error: $e');
    }

    await Future.delayed(const Duration(seconds: 1));
    _checkSession();
  }

  void _showInAppBanner(String title, String body) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            Text(body,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role  = prefs.getString('role');
    final email = prefs.getString('email');

    if (token != null && role != null) {
      final valid = await ApiService.validateToken();
      if (!mounted) return;
      if (valid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'docente'
                ? const DocenteHomeScreen()
                : const EstudianteHomeScreen(),
          ),
        );
        return;
      }
      await ApiService.clearSession();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(prefillEmail: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowBlue,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.face_retouching_natural,
                          color: Colors.white, size: 52),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('InClass',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 6),
              Text('Reconocimiento Facial con IA',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}