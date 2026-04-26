import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ContactoScreen extends StatefulWidget {
  const ContactoScreen({super.key});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _futureContacto;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureContacto = _apiService.getContacto();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto Institucional'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureContacto,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final data = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ESCUDO / LOGO AYUNTAMIENTO
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                ),

                const SizedBox(height: 24),

                Text(
                  'Ayuntamiento de Gandía',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 8),

                const Text(
                  'Estamos aquí para escucharte y ayudarte a mejorar nuestra ciudad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 40),

                // TARJETAS DE CONTACTO
                _buildContactCard(
                  icon: Icons.phone_rounded,
                  title: 'Teléfono',
                  value: data['telefono'] ?? 'No disponible',
                  color: Colors.green,
                ).animate().fadeIn(delay: 600.ms).slideX(),

                const SizedBox(height: 16),

                _buildContactCard(
                  icon: Icons.email_rounded,
                  title: 'Email',
                  value: data['email'] ?? 'No disponible',
                  color: Colors.blue,
                ).animate().fadeIn(delay: 750.ms).slideX(),

                const SizedBox(height: 16),

                _buildContactCard(
                  icon: Icons.language_rounded,
                  title: 'Sitio Web',
                  value: data['web'] ?? 'www.gandia.es',
                  color: Colors.purple,
                ).animate().fadeIn(delay: 900.ms).slideX(),

                const SizedBox(height: 16),

                _buildContactCard(
                  icon: Icons.location_on_rounded,
                  title: 'Dirección',
                  value: data['direccion'] ?? 'No disponible',
                  color: Colors.redAccent,
                ).animate().fadeIn(delay: 1050.ms).slideX(),

                const SizedBox(height: 16),

                _buildContactCard(
                  icon: Icons.access_time_filled_rounded,
                  title: 'Horario de Atención',
                  value: data['horario'] ?? 'No disponible',
                  color: Colors.orange,
                ).animate().fadeIn(delay: 1200.ms).slideX(),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Error al cargar la información de contacto'),
          TextButton(onPressed: _loadData, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }
}
