import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureCategorias;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureCategorias = _apiService.getCategorias();
    });
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
                    Text('Gestión de Categorías', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('Controla las categorías que ven los ciudadanos en el móvil', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCategoria(),
                  icon: const Icon(Icons.add),
                  label: const Text('NUEVA CATEGORÍA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureCategorias,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final lista = snapshot.data ?? [];
                  
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final cat = lista[index];
                      return _buildCategoriaCard(cat);
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

  Widget _buildCategoriaCard(dynamic cat) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDialogoCategoria(categoria: cat),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(cat['icono'], style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 12),
              Text(cat['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text('${cat['_count']['incidencias']} reportes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCategoria({dynamic categoria}) {
    final TextEditingController nombreController = TextEditingController(text: categoria?['nombre'] ?? '');
    final TextEditingController iconoController = TextEditingController(text: categoria?['icono'] ?? '📍');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre de la categoría', hintText: 'Ej: Limpieza, Parques...'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: iconoController,
              decoration: const InputDecoration(labelText: 'Emoji o Icono', hintText: 'Ej: 🌳, 💡, 🧹'),
            ),
            const SizedBox(height: 10),
            const Text('Usa un emoji para que se vea bien en el móvil', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          if (categoria != null)
            TextButton(
              onPressed: () => _confirmarEliminar(categoria['id'], categoria['nombre']),
              child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              final token = context.read<AuthProvider>().token;
              if (categoria == null) {
                await _apiService.crearCategoria(token!, nombreController.text, iconoController.text);
              } else {
                await _apiService.actualizarCategoria(token!, categoria['id'], nombreController.text, iconoController.text);
              }
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(int id, String nombre) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text('¿Seguro que quieres borrar la categoría "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final token = context.read<AuthProvider>().token;
        await _apiService.eliminarCategoria(token!, id);
        Navigator.pop(context); // Cerrar el diálogo de edición
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
