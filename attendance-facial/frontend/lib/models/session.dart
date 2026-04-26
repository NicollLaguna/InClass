class CourseModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String codigoAcceso;
  final bool activo;

  CourseModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.codigoAcceso,
    required this.activo,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'] ?? '',
        codigoAcceso: json['codigo_acceso'] ?? '',
        activo: json['activo'] ?? true,
      );
}

class SessionModel {
  final String id;
  final String cursoId;
  final String fecha;
  final bool activa;
  final int ventanaMinutos;
  final String? horaInicio;

  SessionModel({
    required this.id,
    required this.cursoId,
    required this.fecha,
    required this.activa,
    required this.ventanaMinutos,
    this.horaInicio,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] ?? '',
        cursoId: json['curso_id'] ?? '',
        fecha: json['fecha'] ?? '',
        activa: json['activa'] ?? false,
        ventanaMinutos: json['ventana_minutos'] ?? 15,
        horaInicio: json['hora_inicio'],
      );
}

class EnrollmentModel {
  final String id;
  final String estado;
  final Map<String, dynamic>? estudiante;
  final Map<String, dynamic>? curso;

  EnrollmentModel({
    required this.id,
    required this.estado,
    this.estudiante,
    this.curso,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) => EnrollmentModel(
        id: json['id'] ?? '',
        estado: json['estado'] ?? '',
        estudiante: json['estudiantes'],
        curso: json['cursos'],
      );
}