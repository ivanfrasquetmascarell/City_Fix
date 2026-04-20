import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/incidencia.dart';
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
  VideoPlayerController? _videoController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _initMultimedia();
  }

  void _initMultimedia() {
    final url = widget.incidencia.fotoUrl;
    if (url != null && (url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov'))) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse('${Constants.apiUrl}$url'),
      )..initialize().then((_) {
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
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
            if (inc.fotoUrl != null) ...[
              if (_videoController != null)
                Container(
                  height: 300,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_videoController!.value.isInitialized)
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      else
                        const CircularProgressIndicator(color: Colors.white),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Icon(
                            _videoController!.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                            color: Colors.white.withOpacity(0.5),
                            size: 80,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 300,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    '${Constants.apiUrl}${inc.fotoUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                )
            ] else
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
                      Text(inc.categoria?.icono ?? '📌', style: const TextStyle(fontSize: 30)),
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
