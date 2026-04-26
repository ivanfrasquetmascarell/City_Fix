import 'categoria.dart';
import 'usuario.dart';
import 'multimedia.dart';

class Incidencia {
  final int id;
  final String titulo;
  final String descripcion;
  final List<Multimedia> multimedia;
  final double latitud;
  final double longitud;
  final String estado;
  final String? comentarioAdmin;
  final Categoria? categoria;
  final Usuario? usuario;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.multimedia,
    required this.latitud,
    required this.longitud,
    required this.estado,
    this.comentarioAdmin,
    this.categoria,
    this.usuario,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    try {
      final multimediaList = (json['multimedia'] as List?)
              ?.map((m) => Multimedia.fromJson(m))
              .toList() ??
          [];

      return Incidencia(
        id: json['id'] as int? ?? 0,
        titulo: json['titulo']?.toString() ?? 'Sin título',
        descripcion: json['descripcion']?.toString() ?? '',
        multimedia: multimediaList,
        latitud: double.tryParse(json['latitud']?.toString() ?? '0') ?? 0.0,
        longitud: double.tryParse(json['longitud']?.toString() ?? '0') ?? 0.0,
        estado: json['estado']?.toString() ?? 'pendiente',
        comentarioAdmin: json['comentarioAdmin']?.toString(),
        categoria: json['categoria'] != null 
            ? Categoria.fromJson(json['categoria']) 
            : null,
        usuario: json['usuario'] != null 
            ? Usuario.fromJson(json['usuario']) 
            : null,
      );
    } catch (e) {
      rethrow;
    }
  }
}
