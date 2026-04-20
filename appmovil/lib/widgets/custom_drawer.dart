import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;

    return Drawer(
      child: Column(
        children: [
          // CABECERA DEL DRAWER
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1541443131876-44b03de101c5?q=80&w=2070&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                usuario?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            accountName: Text(
              usuario?.nombre ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(usuario?.email ?? ''),
          ),

          // OPCIONES DE NAVEGACIÓN
          ListTile(
            leading: const Icon(Icons.home_outlined, color: AppTheme.primaryColor),
            title: const Text('Inicio / Portada'),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_rounded, color: AppTheme.primaryColor),
            title: const Text('Mis Incidencias'),
            onTap: () {
              Navigator.pop(context);
              context.go('/incidencias');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            title: const Text('Nuevo Reporte'),
            onTap: () {
              Navigator.pop(context);
              context.push('/crear');
            },
          ),
          
          const Divider(),
          
          const Spacer(),

          // BOTÓN DE CERRAR SESIÓN
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // Confirmar cierre de sesión
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('Tendrás que volver a introducir tus credenciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(ctx); // Cerrar dialog
                        authProvider.logout();
                        context.go('/login');
                      },
                      child: const Text('SALIR', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
