import 'categoria.dart';
import 'usuario.dart';
import 'multimedia.dart';

class Incidencia {
  final int id;
  final String titulo;
  final String descripcion;
  final String? direccion;
  final List<Multimedia> multimedia;
  final double latitud;
  final double longitud;
  final String estado;
  final String? comentarioAdmin;
  final Categoria? categoria;
  final Usuario? usuario;
  final DateTime createdAt;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.direccion,
    required this.multimedia,
    required this.latitud,
    required this.longitud,
    required this.estado,
    this.comentarioAdmin,
    this.categoria,
    this.usuario,
    required this.createdAt,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sin título',
      descripcion: json['descripcion'] ?? '',
      direccion: json['direccion'],
      multimedia: (json['multimedia'] as List?)
              ?.map((m) => Multimedia.fromJson(m))
              .toList() ??
          [],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      estado: json['estado'] ?? 'pendiente',
      comentarioAdmin: json['comentarioAdmin'],
      categoria: json['categoria'] != null ? Categoria.fromJson(json['categoria']) : null,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
