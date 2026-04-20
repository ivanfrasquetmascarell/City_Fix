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
