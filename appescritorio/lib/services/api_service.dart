import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../utils/constants.dart';
import '../models/incidencia.dart';
import '../models/categoria.dart';

class ApiService {
  final String baseUrl = Constants.apiUrl;

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- AUTH ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error ?? 'Error en login');
    }
  }

  // --- INCIDENCIAS (ADMIN) ---
  Future<List<Incidencia>> getTodasLasIncidencias(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/incidencias'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Incidencia.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener incidencias');
    }
  }

  Future<Map<String, dynamic>> getStats(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/incidencias/stats'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener estadísticas');
    }
  }

  Future<void> actualizarEstadoIncidencia(String token, int id, String estado, String? comentario) async {
    final response = await http.put(
      Uri.parse('$baseUrl/incidencias/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'estado': estado,
        'comentarioAdmin': comentario,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar incidencia');
    }
  }

  Future<void> eliminarIncidencia(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/incidencias/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar incidencia');
    }
  }

  // --- ANUNCIOS (ADMIN) ---
  Future<void> crearAnuncio({
    required String token,
    required String titulo,
    required String descripcion,
    required String? portadaPath,
    required List<String> multimediaPaths,
    required List<dynamic> links,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/anuncios'));
    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['links'] = jsonEncode(links);

    if (portadaPath != null) {
      request.files.add(await http.MultipartFile.fromPath('portada', portadaPath));
    }

    for (var path in multimediaPaths) {
      request.files.add(await http.MultipartFile.fromPath('multimedia', path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Error al crear anuncio: ${response.body}');
    }
  }

  Future<void> crearAnuncioWeb({
    required String token,
    required String titulo,
    required String descripcion,
    required Uint8List? portadaBytes,
    required String? portadaName,
    required List<dynamic> extraFiles, // List<PlatformFile>
    required List<dynamic> links,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/anuncios'));
    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['links'] = jsonEncode(links);

    if (portadaBytes != null && portadaName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'portada',
        portadaBytes,
        filename: portadaName,
      ));
    }

    for (var file in extraFiles) {
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'multimedia',
          file.bytes!,
          filename: file.name,
        ));
      }
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Error al crear anuncio: ${response.body}');
    }
  }

  Future<List<dynamic>> getAnuncios() async {
    final response = await http.get(Uri.parse('$baseUrl/anuncios'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener anuncios');
    }
  }

  Future<void> eliminarAnuncio(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/anuncios/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar noticia');
    }
  }

  Future<void> actualizarAnuncioWeb({
    required int id,
    required String token,
    required String titulo,
    required String descripcion,
    required Uint8List? portadaBytes,
    required String? portadaName,
    required List<dynamic> extraFiles,
    required List<dynamic> links,
    List<int> multimediaIdsToDelete = const [],
  }) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/anuncios/$id'));
    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['links'] = jsonEncode(links);
    request.fields['multimediaIdsToDelete'] = jsonEncode(multimediaIdsToDelete);

    if (portadaBytes != null && portadaName != null) {
      request.files.add(http.MultipartFile.fromBytes('portada', portadaBytes, filename: portadaName));
    }

    for (var file in extraFiles) {
      if (file is PlatformFile && file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('multimedia', file.bytes!, filename: file.name));
      }
    }

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception('Error al actualizar anuncio');
    }
  }

  Future<List<dynamic>> getUsuarios(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/usuarios'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  Future<List<dynamic>> getCategorias() async {
    final response = await http.get(Uri.parse('$baseUrl/categorias'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener categorías');
    }
  }

  Future<void> resetearPuntos(String token, int userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/usuarios/$userId/reset-puntos'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Error al resetear puntos');
  }

  Future<void> cambiarEstadoBloqueo(String token, int userId, bool bloqueado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/usuarios/$userId/bloqueo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bloqueado': bloqueado}),
    );
    if (response.statusCode != 200) throw Exception('Error al cambiar bloqueo');
  }

  Future<void> crearCategoria(String token, String nombre, String icono) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categorias'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nombre': nombre, 'icono': icono}),
    );
    if (response.statusCode != 201) throw Exception('Error al crear categoría');
  }

  Future<void> actualizarCategoria(String token, int id, String nombre, String icono) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categorias/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nombre': nombre, 'icono': icono}),
    );
    if (response.statusCode != 200) throw Exception('Error al actualizar categoría');
  }

  Future<void> eliminarCategoria(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categorias/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Error al eliminar categoría');
    }
  }

  Future<Map<String, dynamic>> getContacto() async {
    final response = await http.get(Uri.parse('$baseUrl/contacto'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener contacto');
    }
  }

  Future<void> actualizarContacto(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/contacto'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Error al actualizar contacto');
  }
}
