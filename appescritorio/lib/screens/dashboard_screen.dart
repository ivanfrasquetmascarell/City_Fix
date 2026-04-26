import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _futureStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      _futureStats = _apiService.getStats(token);
    }
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
            const Text(
              'Panel de Control',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text('Bienvenido al gestor central de City Fix', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            
            FutureBuilder<Map<String, dynamic>>(
              future: _futureStats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final stats = snapshot.data ?? {};
                
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildStatCard('Total Incidencias', stats['total']?.toString() ?? '0', Icons.analytics, Colors.blue),
                    _buildStatCard('Pendientes', stats['pendientes']?.toString() ?? '0', Icons.warning_amber_rounded, Colors.orange),
                    _buildStatCard('En Curso', stats['en_curso']?.toString() ?? '0', Icons.engineering_outlined, Colors.indigo),
                    _buildStatCard('Resueltas', stats['resueltos']?.toString() ?? '0', Icons.check_circle_outline, Colors.green),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
