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

  Future<void> fetchMisIncidencias(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Avisamos a la UI que estamos cargando

    try {
      _incidencias = await _apiService.getMisIncidencias(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisamos a la UI que ya hemos terminado
    }
  }

  // Si creamos una nueva incidencia, en vez de recargar todas,
  // la podemos añadir a la lista local para que sea instantáneo.
  void addIncidenciaLocal(Incidencia incidencia) {
    _incidencias.insert(0, incidencia); // La ponemos la primera
    notifyListeners();
  }

  void clear() {
    _incidencias = [];
    _error = null;
    notifyListeners();
  }
}
