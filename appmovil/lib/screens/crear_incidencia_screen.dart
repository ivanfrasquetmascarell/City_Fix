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

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
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
  XFile? _multimediaFile;
  bool _esVideo = false;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;

  // Mapa y GPS
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(38.9666, -0.1833); // Centro por defecto (Gandía/Valencia por ejemplo)
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _centrarEnMiUbicacion(); // Intenta centrar el mapa en la ubicación real al abrir
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

  // REQUERIMIENTO: Solo desde cámara. 
  // NOTA: En Chrome/Web saldrá el explorador de archivos por limitación del navegador, pero en Android abre la cámara nativa obligatoriamente.
  Future<void> _tomarFoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      _videoController?.dispose();
      _videoController = null;
      setState(() {
        _multimediaFile = file;
        _esVideo = false;
      });
    }
  }

  Future<void> _estrictamenteGrabarVideo() async {
    final XFile? file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 10), // Limitado a 10s
    );
    if (file != null) {
      _videoController?.dispose();
      if (kIsWeb) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        _videoController = VideoPlayerController.file(File(file.path));
      }
      
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();

      setState(() {
        _multimediaFile = file;
        _esVideo = true;
      });
    }
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

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría')),
      );
      return;
    }
    // LA MULTIMEDIA AHORA ES OPCIONAL
    // Eliminado el check de _multimediaFile == null

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      await _apiService.crearIncidencia(
        token!,
        _tituloController.text,
        _descripcionController.text,
        _selectedLocation.latitude,
        _selectedLocation.longitude,
        _categoriaSeleccionada!,
        _multimediaFile?.path, // Puede ser null
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Incidencia enviada correctamente'), backgroundColor: AppTheme.secondaryColor),
        );
        context.pop(); // Vuelve al listado de inicio
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
                  Text('Subiendo archivos al servidor... \nEsto puede tardar unos segundos.', textAlign: TextAlign.center,),
                ],
              ))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SECCIÓN DE MULTIMEDIA (OPCIONAL)
                      const Text('1. Evidencia visual (Opcional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_multimediaFile == null)
                              Center(
                                child: Text('No hay archivo\n(Puedes enviarlo sin foto)', 
                                  textAlign: TextAlign.center, 
                                  style: TextStyle(color: Colors.grey.shade400)
                                ),
                              )
                            else if (_esVideo && _videoController != null && _videoController!.value.isInitialized)
                              AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            else if (!_esVideo)
                               kIsWeb 
                               ? Image.network(_multimediaFile!.path, fit: BoxFit.cover)
                               : Image.file(File(_multimediaFile!.path), fit: BoxFit.cover)
                            else
                              const Center(child: CircularProgressIndicator(color: Colors.white)), // Cargando video

                            // Botones inferiores flotantes sobre el área negra
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _tomarFoto,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Foto'),
                                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48), foregroundColor: Colors.black, backgroundColor: Colors.white),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _estrictamenteGrabarVideo,
                                    icon: const Icon(Icons.videocam),
                                    label: const Text('Vídeo 10s'),
                                    style: ElevatedButton.styleFrom(minimumSize: const Size(130, 48), backgroundColor: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),

                            // Botón de eliminar arriba a la derecha si hay archivo
                            if (_multimediaFile != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white),
                                  style: IconButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    _videoController?.dispose();
                                    _videoController = null;
                                    setState(() => _multimediaFile = null);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SECCIÓN DE MAPA INTERACTIVO
                      const Text('2. Ubicación del problema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Arrastra el mapa para situar exactamente el marcador', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'es.ivanfrasquet.cityfix.app',
                                ),
                              ],
                            ),
                            // Marcador Fijo en el centro de la pantalla
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 40.0), // Elevarlo por la punta del icono
                                child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
                              ),
                            ),
                            // Botón flotante para ubicar
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

                      // FORMULARIO DATA
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
