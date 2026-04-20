import 'package:flutter/material.dart';
import '../models/incidencia.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class IncidenciaDetailScreen extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Incidencia')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FOTO / MULTIMEDIA
            if (incidencia.fotoUrl != null) ...[
              if (incidencia.fotoUrl!.toLowerCase().endsWith('.mp4') || incidencia.fotoUrl!.toLowerCase().endsWith('.mov'))
                Container(
                  height: 250,
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 50, color: Colors.white),
                        SizedBox(height: 8),
                        Text('Vídeo adjunto\n(Visualizado en Web/Escritorio de Admin)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    '${Constants.apiUrl}${incidencia.fotoUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                    },
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
                  // TÍTULO Y CATEGORÍA
                  Row(
                    children: [
                      Text(incidencia.categoria?.icono ?? '📌', style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incidencia.titulo,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              incidencia.categoria?.nombre ?? 'General',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ESTADO (Badge grande)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(incidencia.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getStatusColor(incidencia.estado).withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text('ESTADO ACTUAL', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          incidencia.estado.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(incidencia.estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DESCRIPCION
                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(incidencia.descripcion, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),

                  // RESPUESTA AYUNTAMIENTO
                  if (incidencia.comentarioAdmin != null && incidencia.comentarioAdmin!.isNotEmpty) ...[
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
                        incidencia.comentarioAdmin!,
                        style: TextStyle(color: Colors.blue.shade900, fontStyle: FontStyle.italic),
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
