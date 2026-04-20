import 'categoria.dart';
import 'usuario.dart';

class Incidencia {
  final int id;
  final String titulo;
  final String descripcion;
  final String? fotoUrl;
  final double latitud;
  final double longitud;
  final String estado;
  final String? comentarioAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Categoria? categoria;
  final Usuario? usuario;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.fotoUrl,
    required this.latitud,
    required this.longitud,
    required this.estado,
    this.comentarioAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.categoria,
    this.usuario,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fotoUrl: json['fotoUrl'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      estado: json['estado'],
      comentarioAdmin: json['comentarioAdmin'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      categoria: json['categoria'] != null ? Categoria.fromJson(json['categoria']) : null,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
    );
  }
}
