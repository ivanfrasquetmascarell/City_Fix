import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';
import '../services/api_service.dart';

class IncidenciaProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Incidencia> _incidencias = [];
  bool _isLoading = false;
  String? _error;

  List<Incidencia> get incidencias => _incidencias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // El Manager necesita TODAS las incidencias, no solo las de un usuario
  Future<void> fetchTodasLasIncidencias(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); 

    try {
      _incidencias = await _apiService.getTodasLasIncidencias(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  void clear() {
    _incidencias = [];
    _error = null;
    notifyListeners();
  }
}
