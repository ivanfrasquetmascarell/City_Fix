import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Usuario? _usuario;
  final ApiService _apiService = ApiService();

  String? get token => _token;
  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(Constants.tokenKey);
    final userJson = prefs.getString(Constants.userKey);
    if (userJson != null) {
      _usuario = Usuario.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      
      // Verificamos que sea admin
      if (response['usuario']['rol'] != 'admin') {
        throw Exception('Acceso denegado: Se requiere rol de administrador');
      }

      _token = response['token'];
      _usuario = Usuario.fromJson(response['usuario']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.tokenKey, _token!);
      await prefs.setString(Constants.userKey, jsonEncode(_usuario!.toJson()));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.tokenKey);
    await prefs.remove(Constants.userKey);
    notifyListeners();
  }
}
