import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        backgroundColor: const Color(0xFF1F3864),
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
    final role = prefs.getString('role');
    if (!mounted) return;
    if (token != null && role != null) {
      if (role == 'docente') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DocenteHomeScreen()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const EstudianteHomeScreen()));
      }
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F3864),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, color: Colors.white, size: 80),
            const SizedBox(height: 16),
            const Text('InClass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            const Text('Control de Asistencia Facial',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}