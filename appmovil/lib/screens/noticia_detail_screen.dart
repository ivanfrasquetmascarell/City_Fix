import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class NoticiaDetailScreen extends StatelessWidget {
  final dynamic noticia;
  const NoticiaDetailScreen({super.key, required this.noticia});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = noticia['titulo'] ?? 'Sin título';
    final String desc = noticia['descripcion'] ?? '';
    final String? img = noticia['imageUrl'];
    final List<dynamic> multimedia = noticia['multimedia'] ?? [];
    final List<dynamic> links = noticia['links'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: img != null ? Image.network(ApiService.fixUrl(img), fit: BoxFit.cover) : Container(color: AppTheme.primaryColor),
            ),
            leading: IconButton(
              icon: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.arrow_back, color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 24),
                  
                  // CARROUSEL MULTIMEDIA PREMIUM
                  if (multimedia.isNotEmpty) ...[
                    const Text('CONTENIDO ADJUNTO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: multimedia.length,
                        itemBuilder: (context, index) {
                          final item = multimedia[index];
                          final String url = item['url'] ?? '';
                          final isVideo = item['tipo'] == 'VIDEO' || url.toLowerCase().endsWith('.mp4');
                          
                          return Container(
                            width: 300,
                            margin: const EdgeInsets.only(right: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  if (isVideo)
                                    _VideoThumbnail(url: ApiService.fixUrl(url))
                                  else
                                    Image.network(ApiService.fixUrl(url), fit: BoxFit.cover, width: 300, height: 220),
                                  
                                  // Overlay elegante para vídeo
                                  if (isVideo)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onTap: () => _openPremiumPlayer(context, url),
                                        child: Container(
                                          color: Colors.black26,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.9), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                                              child: const Icon(Icons.play_arrow_rounded, size: 40, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Text(desc, style: TextStyle(fontSize: 17, color: Colors.grey.shade800, height: 1.6)),
                  const SizedBox(height: 40),

                  if (links.isNotEmpty) ...[
                    const Text('ENLACES DE INTERÉS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const SizedBox(height: 16),
                    ...links.map((link) => _buildLinkTile(link)),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(dynamic linkData) {
    final label = linkData is Map ? (linkData['texto'] ?? 'Ver más') : linkData.toString();
    final url = linkData is Map ? (linkData['url'] ?? '') : linkData.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.link, color: Colors.blue),
        title: Text(label, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
        onTap: () => _launchURL(url),
      ),
    );
  }

  void _openPremiumPlayer(BuildContext context, String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.9),
      pageBuilder: (context, anim1, anim2) => _PremiumVideoPlayer(url: ApiService.fixUrl(url)),
    );
  }
}

// WIDGET PARA CARGAR UNA MINIATURA DEL VÍDEO
class _VideoThumbnail extends StatefulWidget {
  final String url;
  const _VideoThumbnail({required this.url});
  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() => _ready = true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ready 
      ? VideoPlayer(_controller) 
      : Container(color: Colors.grey.shade300, child: const Center(child: CircularProgressIndicator()));
  }
}

// REPRODUCTOR PREMIUM CON UI DE ALTA CALIDAD
class _PremiumVideoPlayer extends StatefulWidget {
  final String url;
  const _PremiumVideoPlayer({required this.url});
  @override
  State<_PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<_PremiumVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fondo con desenfoque
            BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black54)),
            
            // El vídeo
            if (_controller.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoPlayer(_controller)),
                ),
              )
            else
              const CircularProgressIndicator(color: Colors.white),

            // CONTROLES (Overlay)
            if (_showControls)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54])),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Barra superior
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                              const Text('Reproduciendo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 48), // Spacer
                            ],
                          ),
                        ),
                      ),

                      // Centro (Play/Pause)
                      IconButton(
                        icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 80),
                        onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                      ),

                      // Barra inferior (Progreso)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            children: [
                              VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: AppTheme.primaryColor, bufferedColor: Colors.white24, backgroundColor: Colors.white12)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(_controller.value.position), style: const TextStyle(color: Colors.white70)),
                                  Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}
