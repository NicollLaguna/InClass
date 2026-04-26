import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.18.155:8000';

  // ── Token management ───────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('role', data['role']);
    await prefs.setString('nombre', data['nombre']);
    await prefs.setString('email', data['email']);
    await prefs.setString('id', data['id']);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('token') ?? '',
      'role': prefs.getString('role') ?? '',
      'nombre': prefs.getString('nombre') ?? '',
      'email': prefs.getString('email') ?? '',
      'id': prefs.getString('id') ?? '',
    };
  }

  // ── Auth ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> registerDocente({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/docente/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> registerEstudiante({
    required String nombre,
    required String codigo,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/estudiante/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'codigo': codigo,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // ── Cursos ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMyCourses() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/courses/my-courses'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createCourse({
    required String nombre,
    required String descripcion,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/courses/create'),
      headers: headers,
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> joinCourse({
    required String codigoAcceso,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/courses/join'),
      headers: headers,
      body: jsonEncode({'codigo_acceso': codigoAcceso}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMyEnrollments() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/courses/my-enrollments'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCourseStudents(String cursoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/courses/$cursoId/students'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ── Matrículas ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getPendingEnrollments(String cursoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/enrollments/pending/$cursoId'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveEnrollment(String matriculaId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/enrollments/approve/$matriculaId'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> rejectEnrollment(String matriculaId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/enrollments/reject/$matriculaId'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ── Sesiones ───────────────────────────────────────────

  static Future<Map<String, dynamic>> startSession(String cursoId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/start'),
      headers: headers,
      body: jsonEncode({'curso_id': cursoId}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> endSession(String sesionId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/end/$sesionId'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getActiveSession(String cursoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/active/$cursoId'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCourseSessions(String cursoId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/course/$cursoId'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ── Asistencia ─────────────────────────────────────────

  static Future<Map<String, dynamic>> recognizeFrame({
    required String sesionId,
    required String base64Frame,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/recognize/$sesionId'),
      headers: headers,
      body: jsonEncode({'frame': base64Frame}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAttendanceHistory() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/history'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ── Registro facial ────────────────────────────────────

  static Future<Map<String, dynamic>> registerStudent({
    required String nombre,
    required String codigo,
    required File foto,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/students/register');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['nombre'] = nombre;
    request.fields['codigo'] = codigo;
    request.files.add(await http.MultipartFile.fromPath(
      'foto',
      foto.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }
  // ── Reportes ───────────────────────────────────────────

  static Future<Map<String, dynamic>> generateReport(String sesionId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/generate/$sesionId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return {'success': true};
    }
    return jsonDecode(response.body);
  }

  static Future<void> saveFcmToken(String fcmToken) async {
    final headers = await getHeaders();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? '';
    
    await http.post(
      Uri.parse('$baseUrl/auth/fcm-token'),
      headers: headers,
      body: jsonEncode({'fcm_token': fcmToken, 'role': role}),
    );
  }

}