import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/incidencia.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/nivel_up_dialog.dart';

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

  String? _filtroEstado; // null = Todos, o 'pendiente', 'en_curso', 'resuelto'

  @override
  Widget build(BuildContext context) {
    // VIGILANCIA ACTIVA: Escuchamos cambios al instante
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    // CELEBRACIÓN DE NIVEL PRIORITARIA (Lo primero que comprueba la App)
    if (usuario != null) {
      final nivelActual = (usuario.puntos ~/ 5) + 1;
      if (nivelActual > auth.nivelCelebrado) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            // Marcamos como celebrado y lanzamos el trofeo
            auth.marcarNivelComoCelebrado(nivelActual).then((_) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => NivelUpDialog(nuevoNivel: nivelActual),
                );
              }
            });
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Incidencias'),
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: FutureBuilder<List<Incidencia>>(
                future: _futureIncidencias,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeleton();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final allItems = snapshot.data ?? [];
                  final filteredList = allItems.where((inc) {
                    if (_filtroEstado == null) return true;
                    return inc.estado == _filtroEstado;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return _buildEmptyState(allItems.isEmpty);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final inc = filteredList[index];
                      return _buildIncidenciaCard(inc, index);
                    },
                  );
                },
              ),
            ),
          ),
        ],
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

  Widget _buildFilters() {
    final estados = [
      {'id': null, 'label': 'Todos', 'icon': Icons.list},
      {'id': 'pendiente', 'label': 'Pendientes', 'icon': Icons.hourglass_empty},
      {'id': 'en_curso', 'label': 'En Curso', 'icon': Icons.engineering},
      {'id': 'resuelto', 'label': 'Resueltos', 'icon': Icons.check_circle_outline},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: estados.length,
        itemBuilder: (context, index) {
          final est = estados[index];
          final isSelected = _filtroEstado == est['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                est['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
              label: Text(est['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroEstado = est['id'] as String?;
                });
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: isSelected ? 4 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncidenciaCard(Incidencia inc, int index) {
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
                  child: Hero(
                    tag: 'cat_${inc.id}',
                    child: Text(
                      inc.categoria?.icono ?? '📌',
                      style: const TextStyle(fontSize: 24, decoration: TextDecoration.none),
                    ),
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
  }

  Widget _buildErrorState() {
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

  Widget _buildEmptyState(bool noDataTotal) {
    return Stack(
      children: [
        ListView(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                noDataTotal ? Icons.check_circle_outline : Icons.filter_list_off,
                size: 80,
                color: Colors.grey.shade400,
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                noDataTotal ? '¡Tu ciudad está impecable!' : 'Sin resultados para este filtro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                noDataTotal ? 'No tienes incidencias reportadas.' : 'Prueba a cambiar el estado seleccionado.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
