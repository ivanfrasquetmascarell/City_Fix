class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final int puntos;
  final bool bloqueado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.puntos,
    this.bloqueado = false,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre']?.toString() ?? 'Usuario Anónimo',
      email: json['email']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'CIUDADANO',
      puntos: json['puntos'] as int? ?? 0,
      bloqueado: json['bloqueado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    'puntos': puntos,
    'bloqueado': bloqueado,
  };
}
