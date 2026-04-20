import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/incidencia.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        _futureIncidencias = _apiService.getMisIncidencias(token);
      });
    }
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orangeAccent;
      case 'en_curso':
        return Colors.blueAccent;
      case 'resuelto':
        return AppTheme.secondaryColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_curso':
        return 'En Curso';
      case 'resuelto':
        return 'Resuelto';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Incidencias'),
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<Incidencia>>(
          future: _futureIncidencias,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error al cargar datos', style: Theme.of(context).textTheme.titleLarge),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) {
              return Stack(
                children: [
                  ListView(), // Necesario para que el RefreshIndicator funcione en una lista vacía
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400)
                            .animate()
                            .scale(duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 16),
                        Text(
                          '¡Tu ciudad está impecable!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tienes incidencias reportadas.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final inc = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      context.push('/incidencia/${inc.id}', extra: inc).then((_) => _loadData());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                inc.categoria?.icono ?? '📌',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inc.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inc.categoria?.nombre ?? 'General',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(inc.estado).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(inc.estado).withOpacity(0.5)),
                            ),
                            child: Text(
                              _getStatusText(inc.estado),
                              style: TextStyle(
                                color: _getStatusColor(inc.estado),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/crear').then((_) => _loadData()); // Refrescar al volver
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Reportar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms),
    );
  }
}
