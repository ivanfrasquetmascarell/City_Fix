class Categoria {
  final int id;
  final String nombre;
  final String icono;

  Categoria({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      icono: json['icono'],
    );
  }
}
