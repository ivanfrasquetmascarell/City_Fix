class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final int puntos;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.puntos,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      puntos: json['puntos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    'puntos': puntos,
  };
}
