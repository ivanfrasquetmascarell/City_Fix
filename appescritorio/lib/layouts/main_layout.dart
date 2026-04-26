import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/incidencias_screen.dart';
import '../screens/anuncios_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const IncidenciasScreen(),
    const AnunciosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR (BARRA LATERAL)
          Container(
            width: 280,
            color: AppTheme.sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.location_city, size: 50, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'CITY FIX MANAGER',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 40),
                
                // Elementos de Navegación
                _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(1, Icons.list_alt_outlined, 'Incidencias'),
                _buildNavItem(2, Icons.newspaper_outlined, 'Noticias'),
                
                const Spacer(),
                
                // Perfil y Logout
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black12,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              usuario?.nombre ?? 'Admin',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Administrador', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white60),
                        onPressed: () => context.read<AuthProvider>().logout(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ÁREA DE CONTENIDO PRINCIPAL
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      onTap: () => setState(() => _selectedIndex = index),
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
    );
  }
}
