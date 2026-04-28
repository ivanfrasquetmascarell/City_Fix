import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dirController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  final TextEditingController _webController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _apiService.getContacto();
      _telController.text = data['telefono'] ?? '';
      _emailController.text = data['email'] ?? '';
      _dirController.text = data['direccion'] ?? '';
      _horarioController.text = data['horario'] ?? '';
      _webController.text = data['web'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar datos')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token;
      await _apiService.actualizarContacto(token!, {
        'telefono': _telController.text,
        'email': _emailController.text,
        'direccion': _dirController.text,
        'horario': _horarioController.text,
        'web': _webController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada correctamente')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar cambios')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuración del Ayuntamiento', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('Estos datos se mostrarán en la sección de Contacto de la App Móvil', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INFORMACIÓN DE CONTACTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(child: _buildField('Teléfono de atención', _telController, Icons.phone)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildField('Email oficial', _emailController, Icons.email)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildField('Dirección física', _dirController, Icons.location_on),
                          const SizedBox(height: 20),
                          _buildField('Horario de atención', _horarioController, Icons.access_time),
                          const SizedBox(height: 20),
                          _buildField('Página Web oficial', _webController, Icons.language),
                          
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 200,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Este campo es obligatorio' : null,
    );
  }
}
