import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureUsuarios;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      setState(() {
        _futureUsuarios = _apiService.getUsuarios(token);
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
                    Text('Directorio de Ciudadanos', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('Gestiona el ranking y el comportamiento de los vecinos', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ACTUALIZAR'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // BUSCADOR Y PESTAÑAS
            Row(
              children: [
                // Pestañas
                Container(
                  width: 450,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'TODOS'),
                      Tab(text: 'ACTIVOS'),
                      Tab(text: 'BLOQUEADOS'),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Barra de búsqueda
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o email...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureUsuarios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allUsers = snapshot.data ?? [];
                  if (allUsers.isEmpty) return const Center(child: Text('No hay ciudadanos registrados.'));

                  // Filtrar por pestaña Y por búsqueda
                  List<dynamic> filteredUsers = allUsers.where((u) {
                    final bool matchesTab = (_tabController.index == 0) || 
                                          (_tabController.index == 1 && u['bloqueado'] != true) || 
                                          (_tabController.index == 2 && u['bloqueado'] == true);
                    
                    final bool matchesSearch = u['nombre'].toString().toLowerCase().contains(_searchQuery) || 
                                             u['email'].toString().toLowerCase().contains(_searchQuery);
                    
                    return matchesTab && matchesSearch;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No se encontraron usuarios', style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    );
                  }

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                          columns: const [
                            DataColumn(label: Text('RANKING', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('CIUDADANO', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('PUNTOS', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('REPORTES', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: List.generate(filteredUsers.length, (index) {
                            final user = filteredUsers[index];
                            final bool isBlocked = user['bloqueado'] ?? false;
                            
                            return DataRow(
                              color: isBlocked ? MaterialStateProperty.all(Colors.red.shade50) : null,
                              cells: [
                                DataCell(_buildRankingBadge(index + 1)),
                                DataCell(Text(user['nombre'], style: TextStyle(fontWeight: FontWeight.bold, color: isBlocked ? Colors.red : null))),
                                DataCell(Text(user['email'])),
                                DataCell(_buildStatusBadge(isBlocked)),
                                DataCell(Text('${user['puntos']}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
                                DataCell(Text('${user['_count']['incidencias']}')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
                                        onPressed: () => _confirmReset(user['id'], user['nombre']),
                                        tooltip: 'Resetear puntos a 0',
                                      ),
                                      IconButton(
                                        icon: Icon(isBlocked ? Icons.lock_open_outlined : Icons.block_outlined, color: Colors.red),
                                        onPressed: () => _confirmBlock(user['id'], user['nombre'], !isBlocked),
                                        tooltip: isBlocked ? 'Desbloquear usuario' : 'Bloquear usuario',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingBadge(int pos) {
    if (pos == 1) return const Icon(Icons.workspace_premium, color: Colors.amber);
    if (pos == 2) return const Icon(Icons.workspace_premium, color: Colors.grey);
    if (pos == 3) return const Icon(Icons.workspace_premium, color: Colors.brown);
    return CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade100, child: Text('$pos', style: const TextStyle(fontSize: 10, color: Colors.grey)));
  }

  Widget _buildStatusBadge(bool blocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: blocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blocked ? Colors.red : Colors.green),
      ),
      child: Text(
        blocked ? 'BLOQUEADO' : 'ACTIVO',
        style: TextStyle(color: blocked ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _confirmReset(int id, String nombre) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Resetear puntos?'),
        content: Text('Esto pondrá los puntos de $nombre a 0. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('RESETEAR', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthProvider>().token;
      await _apiService.resetearPuntos(token!, id);
      _loadData();
    }
  }

  Future<void> _confirmBlock(int id, String nombre, bool block) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(block ? '¿Bloquear usuario?' : '¿Desbloquear usuario?'),
        content: Text('¿Seguro que quieres ${block ? 'bloquear' : 'desbloquear'} a $nombre?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(block ? 'BLOQUEAR' : 'DESBLOQUEAR', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthProvider>().token;
      await _apiService.cambiarEstadoBloqueo(token!, id, block);
      _loadData();
    }
  }
}
