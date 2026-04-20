import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/incidencia.dart';
import '../models/multimedia.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class IncidenciaDetailScreen extends StatefulWidget {
  final Incidencia incidencia;

  const IncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  State<IncidenciaDetailScreen> createState() => _IncidenciaDetailScreenState();
}

class _IncidenciaDetailScreenState extends State<IncidenciaDetailScreen> {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Mapa de controladores de video por índice
  final Map<int, VideoPlayerController> _videoControllers = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  void _initVideos() {
    for (int i = 0; i < widget.incidencia.multimedia.length; i++) {
      final media = widget.incidencia.multimedia[i];
      if (media.tipo == TipoMedia.VIDEO) {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse('${Constants.apiUrl}${media.url}'),
        )..initialize().then((_) {
            if (mounted) setState(() {});
          });
        _videoControllers[i] = controller;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmarBorrado() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar reporte?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _ejecutarBorrado();
    }
  }

  Future<void> _ejecutarBorrado() async {
    setState(() => _isDeleting = true);
    try {
      final token = context.read<AuthProvider>().token;
      await _apiService.eliminarIncidencia(token!, widget.incidencia.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidencia eliminada con éxito')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inc = widget.incidencia;
    final sePuedeBorrar = inc.estado == 'pendiente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Incidencia'),
        actions: [
          if (sePuedeBorrar && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _confirmarBorrado,
              tooltip: 'Eliminar reporte',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CARRUSEL MULTIMEDIA
            if (inc.multimedia.isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    height: 350,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      itemCount: inc.multimedia.length,
                      itemBuilder: (context, index) {
                        final media = inc.multimedia[index];
                        if (media.tipo == TipoMedia.VIDEO) {
                          final controller = _videoControllers[index];
                          return Container(
                            color: Colors.black,
                            child: Center(
                              child: controller != null && controller.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: controller.value.aspectRatio,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          VideoPlayer(controller),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                controller.value.isPlaying ? controller.pause() : controller.play();
                                              });
                                            },
                                            child: Icon(
                                              controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                              color: Colors.white.withOpacity(0.7),
                                              size: 70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const CircularProgressIndicator(color: Colors.white),
                            ),
                          );
                        } else {
                          return Image.network(
                            '${Constants.apiUrl}${media.url}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                          );
                        }
                      },
                    ),
                  ),
                  // Indicador de página
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${inc.multimedia.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'cat_${inc.id}',
                        child: Text(inc.categoria?.icono ?? '📌', style: const TextStyle(fontSize: 30, decoration: TextDecoration.none)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.titulo,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              inc.categoria?.nombre ?? 'General',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inc.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getStatusColor(inc.estado).withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text('ESTADO ACTUAL', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          inc.estado.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(inc.estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(inc.descripcion, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),
                  if (inc.comentarioAdmin != null && inc.comentarioAdmin!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.mark_email_read, color: AppTheme.secondaryColor),
                        const SizedBox(width: 8),
                        Text('Respuesta del Ayuntamiento:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        inc.comentarioAdmin!,
                        style: TextStyle(color: Colors.blue.shade900, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (sePuedeBorrar) ...[
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Todavía puedes eliminar este reporte si cometiste un error.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    if (estado == 'pendiente') return Colors.orangeAccent;
    if (estado == 'en_curso') return Colors.blueAccent;
    if (estado == 'resuelto') return AppTheme.secondaryColor;
    return Colors.grey;
  }
}
