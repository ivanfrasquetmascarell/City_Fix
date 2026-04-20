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
    final response = await http.get(
      Uri.parse('$baseUrl/incidencias'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Incidencia.fromJson(e)).toList();
    } else {
      throw Exception('Fallo al obtener tus incidencias');
    }
  }

  // Subir Incidencia con Foto o Video (Multipart Request)
  Future<Incidencia> crearIncidencia(
      String token, 
      String titulo, 
      String descripcion, 
      double latitud, 
      double longitud, 
      int categoriaId,
      String? multimediaPath) async {
        
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/incidencias'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();
    request.fields['categoriaId'] = categoriaId.toString();

    if (multimediaPath != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', multimediaPath));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Incidencia.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Fallo al crear la incidencia: ${response.body}');
    }
  }
}
