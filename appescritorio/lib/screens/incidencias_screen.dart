import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/incidencia.dart';
import '../theme/app_theme.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Incidencia>> _futureIncidencias;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      setState(() {
        _futureIncidencias = _apiService.getTodasLasIncidencias(token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestión de Incidencias', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('Revisa y gestiona los reportes de los ciudadanos', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ACTUALIZAR'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: FutureBuilder<List<Incidencia>>(
                future: _futureIncidencias,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final lista = snapshot.data ?? [];
                  
                  if (lista.isEmpty) {
                    return const Center(child: Text('No hay incidencias registradas.'));
                  }

                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final inc = lista[index];
                      return _buildIncidenciaTile(inc);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenciaTile(Incidencia inc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.report_problem_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(inc.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${inc.categoria?.nombre ?? "Sin categoría"} • Por ${inc.usuario?.nombre ?? "Anónimo"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(inc.estado),
            const SizedBox(width: 20),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // TODO: Abrir detalle/edición
        },
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    Color color = Colors.grey;
    if (estado == 'pendiente') color = Colors.orange;
    if (estado == 'en_curso') color = Colors.blue;
    if (estado == 'resuelto') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
