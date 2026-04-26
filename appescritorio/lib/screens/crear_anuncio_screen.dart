import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CrearAnuncioScreen extends StatefulWidget {
  final dynamic anuncio;
  const CrearAnuncioScreen({super.key, this.anuncio});

  @override
  State<CrearAnuncioScreen> createState() => _CrearAnuncioScreenState();
}

class _CrearAnuncioScreenState extends State<CrearAnuncioScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  
  Uint8List? _portadaBytes;
  String? _portadaName;
  
  final List<PlatformFile> _newExtraFiles = [];
  final List<dynamic> _existingMultimedia = [];
  final List<int> _multimediaIdsToDelete = [];
  
  final List<Map<String, TextEditingController>> _linkControllers = [];
  bool _isSaving = false;

  bool get isEditing => widget.anuncio != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _tituloController.text = widget.anuncio['titulo'] ?? '';
      _descController.text = widget.anuncio['descripcion'] ?? '';
      _existingMultimedia.addAll(widget.anuncio['multimedia'] ?? []);
      
      final List links = widget.anuncio['links'] ?? [];
      for (var l in links) {
        _linkControllers.add({
          'texto': TextEditingController(text: l['texto']),
          'url': TextEditingController(text: l['url']),
        });
      }
    }
    if (_linkControllers.isEmpty) _addLinkField();
  }

  void _addLinkField() {
    setState(() {
      _linkControllers.add({
        'texto': TextEditingController(),
        'url': TextEditingController(),
      });
    });
  }

  Future<void> _pickPortada() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _portadaBytes = bytes;
        _portadaName = image.name;
      });
    }
  }

  Future<void> _pickMedia() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, 
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi', 'webm'],
      );
      if (result != null) {
        setState(() => _newExtraFiles.addAll(result.files));
      }
    } catch (e) {
      print('ERROR: $e');
    }
  }

  Future<void> _save() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pon un título')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token;
      final links = _linkControllers
          .where((c) => c['url']!.text.isNotEmpty)
          .map((c) => {
                'texto': c['texto']!.text.isEmpty ? c['url']!.text : c['texto']!.text,
                'url': c['url']!.text,
              })
          .toList();

      if (isEditing) {
        await _apiService.actualizarAnuncioWeb(
          id: widget.anuncio['id'],
          token: token!,
          titulo: _tituloController.text,
          descripcion: _descController.text,
          portadaBytes: _portadaBytes,
          portadaName: _portadaName,
          extraFiles: _newExtraFiles,
          links: links,
          multimediaIdsToDelete: _multimediaIdsToDelete,
        );
      } else {
        await _apiService.crearAnuncioWeb(
          token: token!,
          titulo: _tituloController.text,
          descripcion: _descController.text,
          portadaBytes: _portadaBytes,
          portadaName: _portadaName,
          extraFiles: _newExtraFiles,
          links: links,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Noticia' : 'Nueva Noticia'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPortadaSection(),
                const SizedBox(height: 40),
                TextField(controller: _tituloController, decoration: const InputDecoration(labelText: 'TÍTULO', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                TextField(controller: _descController, maxLines: 6, decoration: const InputDecoration(labelText: 'DESCRIPCIÓN', border: OutlineInputBorder())),
                const SizedBox(height: 40),
                _buildMediaSection(),
                const SizedBox(height: 40),
                _buildLinksSection(),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR NOTICIA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortadaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('IMAGEN DE PORTADA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickPortada,
          child: Container(
            height: 250, width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              image: _portadaBytes != null 
                ? DecorationImage(image: MemoryImage(_portadaBytes!), fit: BoxFit.cover)
                : (isEditing && widget.anuncio['imageUrl'] != null ? DecorationImage(image: NetworkImage(widget.anuncio['imageUrl']), fit: BoxFit.cover) : null),
            ),
            child: _portadaBytes == null && (!isEditing || widget.anuncio['imageUrl'] == null)
                ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MULTIMEDIA ADJUNTA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ElevatedButton.icon(onPressed: _pickMedia, icon: const Icon(Icons.add), label: const Text('SUBIR ARCHIVOS')),
          ],
        ),
        const SizedBox(height: 16),
        if (_existingMultimedia.isNotEmpty || _newExtraFiles.isNotEmpty)
          SizedBox(
            height: 170,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingMultimedia.map((m) => _buildMediaThumb(url: m['url'], tipo: m['tipo'], onRemove: () => setState(() { _multimediaIdsToDelete.add(m['id']); _existingMultimedia.remove(m); }), isNew: false)),
                ..._newExtraFiles.map((f) => _buildMediaThumb(bytes: f.bytes, name: f.name, onRemove: () => setState(() => _newExtraFiles.remove(f)), isNew: true)),
              ],
            ),
          )
        else
          Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Sin multimedia adicionales', style: TextStyle(color: Colors.grey)))),
      ],
    );
  }

  Widget _buildMediaThumb({String? url, Uint8List? bytes, String? name, String? tipo, required VoidCallback onRemove, required bool isNew}) {
    final bool isVideo = tipo == 'VIDEO' || (name != null && (name.toLowerCase().endsWith('.mp4') || name.toLowerCase().endsWith('.mov') || name.toLowerCase().endsWith('.webm')));

    return Container(
      width: 140, margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: isVideo && url != null ? () => _openPreviewPlayer(url) : null,
                    child: Container(
                      width: 140, height: 140,
                      color: Colors.grey.shade100,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!isVideo && bytes != null)
                            Image.memory(bytes, fit: BoxFit.cover)
                          else if (!isVideo && url != null)
                            Image.network(url, fit: BoxFit.cover)
                          else if (isVideo && url != null)
                            Image.network(
                              url.replaceFirst(RegExp(r'\.[^/.]+$'), '-thumb.jpg'),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900])),
                                child: const Center(child: Icon(Icons.videocam_rounded, size: 45, color: Colors.white70)),
                              ),
                            )
                          else if (isVideo && url == null)
                            Container(
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900])),
                              child: const Center(child: Icon(Icons.videocam_rounded, size: 45, color: Colors.white70)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Indicador de tipo
                  if (isVideo) Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.play_arrow, size: 12, color: Colors.white))),
                  // Botón eliminar
                  Positioned(
                    top: 5, right: 5,
                    child: IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.red, radius: 11, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      onPressed: onRemove,
                    ),
                  ),
                  if (isNew) Positioned(top: 0, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: const BoxDecoration(color: Colors.green, borderRadius: BorderRadius.only(bottomRight: Radius.circular(8))), child: const Text('NUEVO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name ?? (isVideo ? 'Archivo de Vídeo' : 'Imagen'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _openPreviewPlayer(String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.9),
      pageBuilder: (context, anim1, anim2) => _PremiumPlayer(url: url),
    );
  }

  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ENLACES RELACIONADOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 16),
        ..._linkControllers.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(flex: 2, child: TextField(controller: e.value['texto'], decoration: const InputDecoration(hintText: 'Etiqueta', border: OutlineInputBorder()))),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: TextField(controller: e.value['url'], decoration: const InputDecoration(hintText: 'URL', border: OutlineInputBorder()))),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() => _linkControllers.removeAt(e.key))),
            ],
          ),
        )),
        TextButton.icon(onPressed: _addLinkField, icon: const Icon(Icons.add), label: const Text('AÑADIR ENLACE')),
      ],
    );
  }
}

class _VideoThumb extends StatefulWidget {
  final String url;
  const _VideoThumb({required this.url});
  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    
    // IMPORTANTE PARA WEB: Mute forzado para que el navegador permita la precarga
    _controller.setVolume(0);
    
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((err) {
      if (mounted) setState(() => _error = err.toString());
      print('VIDEO ERROR: $err');
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.red.shade50,
        child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
      );
    }
    return _ready 
      ? VideoPlayer(_controller) 
      : const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _PremiumPlayer extends StatefulWidget {
  final String url;
  const _PremiumPlayer({required this.url});
  @override
  State<_PremiumPlayer> createState() => _PremiumPlayerState();
}

class _PremiumPlayerState extends State<_PremiumPlayer> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) { setState(() {}); _controller.play(); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black87)),
          if (_controller.value.isInitialized) AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)) else const CircularProgressIndicator(),
          Positioned(top: 20, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 40), onPressed: () => Navigator.pop(context))),
          IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 80), onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play())),
        ],
      ),
    );
  }
}
