import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/incidencia.dart';
import '../models/categoria.dart';

class ApiService {
  final String baseUrl = Constants.apiUrl;

  // Lógica común de headers
  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // { token, usuario }
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error ?? 'Error en login');
    }
  }

  // Auth: Registro
  Future<Map<String, dynamic>> registro(String nombre, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro'),
      headers: _headers(null),
      body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error ?? 'Error en registro');
    }
  }

  // Categorías
  Future<List<Categoria>> getCategorias(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categorias'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Categoria.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al obtener las categorías');
    }
  }

  // Incidencias (Ciudadano ve las suyas)
  Future<List<Incidencia>> getMisIncidencias(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/incidencias'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        print('DEBUG: Respuesta recibida del servidor: ${response.body}');
        final List list = jsonDecode(response.body);
        return list.map((e) => Incidencia.fromJson(e)).toList();
      } else {
        print('DEBUG: Error del servidor (${response.statusCode}): ${response.body}');
        throw Exception('Fallo al obtener tus incidencias');
      }
    } catch (e) {
      print('DEBUG: Error en getMisIncidencias: $e');
      rethrow;
    }
  }

  // Subir Incidencia con múltiples Fotos y 1 Video (Multipart Request)
  Future<Incidencia> crearIncidencia(
      String token, 
      String titulo, 
      String descripcion, 
      double latitud, 
      double longitud, 
      int categoriaId,
      List<String> imagenesPaths,
      String? videoPath) async {
        
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/incidencias'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();
    request.fields['categoriaId'] = categoriaId.toString();

    // Añadir imágenes (hasta 3)
    for (var path in imagenesPaths) {
      request.files.add(await http.MultipartFile.fromPath('imagenes', path));
    }

    // Añadir vídeo (máximo 1)
    if (videoPath != null) {
      request.files.add(await http.MultipartFile.fromPath('video', videoPath));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Incidencia.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Fallo al crear la incidencia: ${response.body}');
    }
  }

  // Eliminar incidencia (Propia o Admin)
  Future<void> eliminarIncidencia(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/incidencias/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Error al eliminar';
      throw Exception(error);
    }
  }

  // --- NOTICIAS / ANUNCIOS ---
  Future<List<dynamic>> getAnuncios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/anuncios'));
      if (response.statusCode == 200) {
        List<dynamic> list = json.decode(response.body);
        // Corregir URLs de localhost para que se vean en el móvil
        return list.map((a) => _fixAnuncioUrls(a)).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener anuncios: $e');
      return [];
    }
  }

  // Corrige las URLs de un anuncio y su multimedia
  dynamic _fixAnuncioUrls(dynamic a) {
    if (a['imageUrl'] != null) {
      a['imageUrl'] = _fixUrl(a['imageUrl']);
    }
    if (a['multimedia'] != null) {
      for (var m in a['multimedia']) {
        m['url'] = _fixUrl(m['url']);
      }
    }
    return a;
  }

  // Reemplaza localhost/127.0.0.1 por la IP real del servidor
  String _fixUrl(String url) {
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final serverIp = Uri.parse(baseUrl).host;
      return url.replaceAll('localhost', serverIp).replaceAll('127.0.0.1', serverIp);
    }
    return url;
  }

  // --- CONTACTO INSTITUCIONAL ---
  Future<Map<String, dynamic>> getContacto() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/contacto'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error al obtener contacto: $e');
      return {};
    }
  }
}
