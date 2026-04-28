import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
      setState(() {
        _futureStats = _apiService.getStats(token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
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
                    Text('Panel de Control', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('Bienvenido al gestor central de City Fix', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ACTUALIZAR'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            FutureBuilder<Map<String, dynamic>>(
              future: _futureStats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final stats = snapshot.data ?? {};
                final List<dynamic> porCategoria = stats['porCategoria'] ?? [];
                
                return Column(
                  children: [
                    // RECUADROS SUPERIORES (KPIs)
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _buildStatCard('Total Incidencias', stats['total']?.toString() ?? '0', Icons.analytics, Colors.blue),
                        _buildStatCard('Pendientes', stats['pendientes']?.toString() ?? '0', Icons.warning_amber_rounded, Colors.orange),
                        _buildStatCard('En Curso', stats['enCurso']?.toString() ?? '0', Icons.engineering_outlined, Colors.indigo),
                        _buildStatCard('Resueltas', stats['resueltas']?.toString() ?? '0', Icons.check_circle_outline, Colors.green),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // FILA DE GRÁFICOS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GRÁFICO DE TARTA (Categorías)
                        Expanded(
                          flex: 1,
                          child: _buildChartContainer(
                            'Distribución por Categorías',
                            SizedBox(
                              height: 300,
                              child: porCategoria.isEmpty 
                                ? const Center(child: Text('Sin datos'))
                                : PieChart(
                                    PieChartData(
                                      sections: _buildPieSections(porCategoria),
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // GRÁFICO DE BARRAS (Estados)
                        Expanded(
                          flex: 1,
                          child: _buildChartContainer(
                            'Estado de la Gestión',
                            SizedBox(
                              height: 300,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (stats['total']?.toDouble() ?? 10) + 2,
                                  barGroups: [
                                    _buildBarGroup(0, stats['pendientes']?.toDouble() ?? 0, Colors.orange),
                                    _buildBarGroup(1, stats['enCurso']?.toDouble() ?? 0, Colors.indigo),
                                    _buildBarGroup(2, stats['resueltas']?.toDouble() ?? 0, Colors.green),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          if (val == 0) return const Text('PEND');
                                          if (val == 1) return const Text('CURSO');
                                          if (val == 2) return const Text('RES');
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          chart,
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<dynamic> porCategoria) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.amber];
    return List.generate(porCategoria.length, (i) {
      final item = porCategoria[i];
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: item['cantidad'].toDouble(),
        title: '${item['nombre']}\n${item['cantidad']}',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 40,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
