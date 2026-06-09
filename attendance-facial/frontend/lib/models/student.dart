class Student {
  final String id;
  final String nombre;
  final String codigo;
  final String email;

  Student({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        codigo: json['codigo'] ?? '',
        email: json['email'] ?? '',
      );
}