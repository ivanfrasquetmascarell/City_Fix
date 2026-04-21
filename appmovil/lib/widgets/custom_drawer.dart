import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
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
          // CABECERA DEL DRAWER PERSONALIZADA (CERO OVERFLOW)
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 16, right: 16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1541443131876-44b03de101c5?q=80&w=2070&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AVATAR CON DEGRADADO
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      usuario?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // ESPACIO DE SEGURIDAD
                // NOMBRE Y NIVEL
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        usuario?.nombre ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Nivel ${((usuario?.puntos ?? 0) / 5).floor() + 1}',
                        style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // BARRA DE PROGRESO
                SizedBox(
                  width: 140,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ((usuario?.puntos ?? 0) % 5) / 5.0,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(usuario?.puntos ?? 0) % 5} de 5 para subir de nivel',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario?.email ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
          ListTile(
            leading: const Icon(Icons.newspaper_rounded, color: AppTheme.primaryColor),
            title: const Text('Noticias de la Ciudad'),
            onTap: () {
              Navigator.pop(context);
              context.push('/noticias');
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support_rounded, color: AppTheme.primaryColor),
            title: const Text('Contacto Institucional'),
            onTap: () {
              Navigator.pop(context);
              context.push('/contacto');
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
