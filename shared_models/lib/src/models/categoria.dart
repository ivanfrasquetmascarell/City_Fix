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
      id: json['id'] as int? ?? 0,
      nombre: json['nombre']?.toString() ?? 'Sin categoría',
      icono: json['icono']?.toString() ?? '📍',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'icono': icono,
  };
}
