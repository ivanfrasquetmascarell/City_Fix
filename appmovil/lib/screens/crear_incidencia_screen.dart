import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/nivel_up_dialog.dart';
import '../models/categoria.dart';
import '../theme/app_theme.dart';

class CrearIncidenciaScreen extends StatefulWidget {
  const CrearIncidenciaScreen({super.key});

  @override
  State<CrearIncidenciaScreen> createState() => _CrearIncidenciaScreenState();
}

class _CrearIncidenciaScreenState extends State<CrearIncidenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  List<Categoria> _categorias = [];
  int? _categoriaSeleccionada;
  bool _isLoading = false;
  
  // Multimedia
  final List<XFile> _imageFiles = [];
  XFile? _videoFile;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;

  // Mapa y GPS
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(38.9666, -0.1833); 
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _centrarEnMiUbicacion();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final token = context.read<AuthProvider>().token;
      final cats = await _apiService.getCategorias(token!);
      if (mounted) setState(() => _categorias = cats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar categorías')),
        );
      }
    }
  }

  Future<void> _tomarFoto() async {
    if (_imageFiles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 fotos permitidas')),
      );
      return;
    }
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        _imageFiles.add(file);
      });
    }
  }

  Future<void> _estrictamenteGrabarVideo() async {
    if (_videoFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se permite 1 vídeo por incidencia')),
      );
      return;
    }
    final XFile? file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 10),
    );
    if (file != null) {
      _videoController?.dispose();
      _videoController = kIsWeb 
          ? VideoPlayerController.networkUrl(Uri.parse(file.path))
          : VideoPlayerController.file(File(file.path));
      
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();

      setState(() {
        _videoFile = file;
      });
    }
  }

  void _eliminarFoto(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _eliminarVideo() {
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _videoFile = null;
    });
  }

  Future<void> _centrarEnMiUbicacion() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('El GPS está desactivado.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están deshabilitados permanentemente.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final myLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = myLatLng);
      _mapController.move(myLatLng, 17.0);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('No se pudo obtener GPS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 1.seconds),
            const SizedBox(height: 16),
            const Text(
              '¡Reporte Enviado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 8),
            const Text('Gracias por mejorar tu ciudad.', textAlign: TextAlign.center),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('GENIAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await _apiService.crearIncidencia(
        auth.token!,
        _tituloController.text,
        _descripcionController.text,
        _selectedLocation.latitude,
        _selectedLocation.longitude,
        _categoriaSeleccionada!,
        _imageFiles.map((f) => f.path).toList(),
        _videoFile?.path,
      );

      // Actualizar puntos históricos en el provider
      auth.actualizarPuntos((auth.usuario?.puntos ?? 0) + 1);

      if (mounted) {
        await _showSuccessDialog();
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Reporte')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo archivos al servidor...', textAlign: TextAlign.center,),
                ],
              ))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SECCIÓN DE MULTIMEDIA MEJORADA (3 FOTOS + 1 VIDEO)
                      const Text('1. Evidencia visual (Máx: 3 fotos + 1 vídeo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // Previsualización de archivos seleccionados
                      if (_imageFiles.isNotEmpty || _videoFile != null)
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Fotos
                              ..._imageFiles.asMap().entries.map((entry) {
                                int idx = entry.key;
                                XFile file = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: kIsWeb 
                                          ? Image.network(file.path, width: 120, height: 120, fit: BoxFit.cover)
                                          : Image.file(File(file.path), width: 120, height: 120, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _eliminarFoto(idx),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              // Vídeo
                              if (_videoFile != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: _eliminarVideo,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      
                      if (_imageFiles.isNotEmpty || _videoFile != null) const SizedBox(height: 16),

                      // Botones de captura
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _imageFiles.length < 3 ? _tomarFoto : null,
                              icon: const Icon(Icons.add_a_photo),
                              label: Text('Foto (${_imageFiles.length}/3)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _videoFile == null ? _estrictamenteGrabarVideo : null,
                              icon: const Icon(Icons.videocam),
                              label: Text(_videoFile == null ? 'Vídeo (0/1)' : 'Vídeo (1/1)'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // SECCIÓN DE MAPA
                      const Text('2. Ubicación del problema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation,
                                initialZoom: 16.0,
                                onPositionChanged: (position, hasGesture) {
                                  if (hasGesture && position.center != null) {
                                    setState(() => _selectedLocation = position.center!);
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                ),
                              ],
                            ),
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 40.0),
                                child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: FloatingActionButton.small(
                                backgroundColor: AppTheme.primaryColor,
                                onPressed: _obteniendoUbicacion ? null : _centrarEnMiUbicacion,
                                child: _obteniendoUbicacion 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Icon(Icons.my_location, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text('3. Detalles de la incidencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _categoriaSeleccionada,
                        hint: const Text('Selecciona una categoría...'),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text('${cat.icono} ${cat.nombre}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _categoriaSeleccionada = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título corto del problema',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descripción detallada',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton.icon(
                        onPressed: _enviar,
                        icon: const Icon(Icons.send),
                        label: const Text('ENVIAR REPORTE', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
