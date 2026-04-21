import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Usuario? _usuario;
  String? _token;
  bool _isLoading = true;

  Usuario? get usuario => _usuario;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadSession();
  }

  // Comprobar si ya había una sesión iniciada al abrir la app
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(Constants.tokenKey);
    final savedUser = prefs.getString(Constants.userKey);

    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _usuario = Usuario.fromJson(jsonDecode(savedUser));
      
      final nivelActual = (_usuario!.puntos ~/ 5) + 1;
      _nivelCelebrado = prefs.getInt('ultimo_nivel_celebrado') ?? (nivelActual - 1);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Iniciar Sesión
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      _usuario = Usuario.fromJson(response['usuario']);
      _nivelCelebrado = (_usuario!.puntos ~/ 5) + 1;
      
      // Guardar en local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.tokenKey, _token!);
      await prefs.setString(Constants.userKey, jsonEncode(response['usuario']));
      
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Registro
  Future<bool> registro(String nombre, String email, String password) async {
    try {
      final response = await _apiService.registro(nombre, email, password);
      _token = response['token'];
      _usuario = Usuario.fromJson(response['usuario']);
      _nivelCelebrado = (_usuario!.puntos / 5).floor() + 1;
      
      // Guardar en local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.tokenKey, _token!);
      await prefs.setString(Constants.userKey, jsonEncode(response['usuario']));
      
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // --- GAMIFICACIÓN ---
  int _totalIncidencias = 0;
  int get totalIncidencias => _totalIncidencias;

  bool actualizarPuntos(int nuevosPuntos) {
    if (_usuario == null) return false;

    final oldLevel = (_usuario!.puntos ~/ 5) + 1;
    final newLevel = (nuevosPuntos ~/ 5) + 1;

    // Actualizamos el usuario en memoria con los nuevos puntos
    _usuario = Usuario(
      id: _usuario!.id,
      nombre: _usuario!.nombre,
      email: _usuario!.email,
      rol: _usuario!.rol,
      puntos: nuevosPuntos,
    );

    // PERSISTENCIA: Guardar el usuario actualizado en SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(Constants.userKey, jsonEncode({
        'id': _usuario!.id,
        'nombre': _usuario!.nombre,
        'email': _usuario!.email,
        'rol': _usuario!.rol,
        'puntos': _usuario!.puntos,
      }));
    });
    
    notifyListeners();

    // Devuelve true si ha subido de nivel
    return newLevel > oldLevel;
  }

  // Gestión de celebraciones
  int _nivelCelebrado = 0;
  int get nivelCelebrado => _nivelCelebrado;

  Future<void> marcarNivelComoCelebrado(int nivel) async {
    _nivelCelebrado = nivel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ultimo_nivel_celebrado', nivel);
    notifyListeners();
  }

  // Cerrar sesión
  Future<void> logout() async {
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.tokenKey);
    await prefs.remove(Constants.userKey);
    notifyListeners();
  }
}
