import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/incidencia.dart';
import '../models/multimedia.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Incidencia>> _futureIncidencias;
  Incidencia? _selectedIncidencia;

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
        _selectedIncidencia = null; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
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
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
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
                        if (lista.isEmpty) return const Center(child: Text('No hay incidencias registradas.'));

                        return ListView.builder(
                          itemCount: lista.length,
                          itemBuilder: (context, index) => _buildIncidenciaTile(lista[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedIncidencia != null)
            _buildDetailPanel()
          else
            const Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Selecciona una incidencia para ver los detalles', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIncidenciaTile(Incidencia inc) {
    bool isSelected = _selectedIncidencia?.id == inc.id;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 2),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: _getStatusColor(inc.estado).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.report_problem_outlined, color: _getStatusColor(inc.estado)),
        ),
        title: Text(inc.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${inc.categoria?.nombre ?? "Sin categoría"} • ${inc.direccion ?? "Ubicación GPS"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(inc.estado),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => setState(() => _selectedIncidencia = inc),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final inc = _selectedIncidencia!;
    final TextEditingController commentController = TextEditingController(text: inc.comentarioAdmin);
    String currentEstado = inc.estado;

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(-5, 0))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Row(
              children: [
                IconButton(onPressed: () => setState(() => _selectedIncidencia = null), icon: const Icon(Icons.close)),
                const SizedBox(width: 12),
                const Text('Detalle de Incidencia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (inc.multimedia.isNotEmpty) ...[
                    const Text('MULTIMEDIA ADJUNTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: inc.multimedia.length,
                        itemBuilder: (context, i) {
                          final m = inc.multimedia[i];
                          final url = '${Constants.apiUrl}${m.url}';
                          
                          return GestureDetector(
                            onTap: () {
                              if (m.tipo == TipoMedia.VIDEO) {
                                _verVideo(url);
                              } else {
                                _verImagen(url);
                              }
                            },
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      m.tipo == TipoMedia.IMAGEN 
                                        ? url 
                                        : "${url.split('.')[0]}-thumb.jpg", 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          m.tipo == TipoMedia.IMAGEN ? Icons.broken_image : Icons.videocam, 
                                          color: Colors.grey
                                        ),
                                      ),
                                    ),
                                    if (m.tipo == TipoMedia.VIDEO)
                                      const Center(
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black45,
                                          child: Icon(Icons.play_arrow, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Text(inc.titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Reportado por: ${inc.usuario?.nombre ?? "Anónimo"}', style: const TextStyle(color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  Text(inc.descripcion, style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.5)),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // UBICACIÓN
                  const Text('UBICACIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inc.direccion ?? 'Dirección no disponible', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('GPS: ${inc.latitud}, ${inc.longitud}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${inc.latitud},${inc.longitud}')),
                          icon: const Icon(Icons.map, color: Colors.blue),
                          tooltip: 'Ver en Google Maps',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('GESTIÓN DEL AYUNTAMIENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  StatefulBuilder(
                    builder: (context, setLocalState) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: currentEstado,
                            decoration: const InputDecoration(labelText: 'Estado actual', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'pendiente', child: Text('PENDIENTE')),
                              DropdownMenuItem(value: 'en_curso', child: Text('EN CURSO')),
                              DropdownMenuItem(value: 'resuelto', child: Text('RESUELTO')),
                            ],
                            onChanged: (val) => setLocalState(() => currentEstado = val!),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: commentController,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Comentario para el ciudadano', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final token = context.read<AuthProvider>().token;
                                if (token != null) {
                                  await _apiService.actualizarEstadoIncidencia(token, inc.id, currentEstado, commentController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
                                  _loadData();
                                }
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: AppTheme.primaryColor),
                              child: const Text('GUARDAR GESTIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (currentEstado == 'resuelto') ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _confirmDelete(inc.id),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('ELIMINAR REPORTE', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _verImagen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR'))
          ],
        ),
      ),
    );
  }

  void _verVideo(String url) {
    showDialog(
      context: context,
      builder: (context) => _VideoPlayerDialog(url: url),
    );
  }

  void _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar reporte?'),
        content: const Text('Esta acción borrará la incidencia de forma permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        await _apiService.eliminarIncidencia(token, id);
        _loadData();
      }
    }
  }

  Widget _buildStatusBadge(String estado) {
    Color color = _getStatusColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(estado.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String estado) {
    if (estado == 'pendiente') return Colors.orange;
    if (estado == 'en_curso') return Colors.blue;
    if (estado == 'resuelto') return Colors.green;
    return Colors.grey;
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String url;
  const _VideoPlayerDialog({required this.url});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        width: 800,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: _initialized 
                ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
                : const Center(child: CircularProgressIndicator()),
            ),
            Container(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                    icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR'))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
