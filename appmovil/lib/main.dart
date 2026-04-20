import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/incidencia.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/crear_incidencia_screen.dart';
import 'screens/incidencia_detail_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), 
      ],
      child: const CityFixApp(),
    ),
  );
}

class CityFixApp extends StatelessWidget {
  const CityFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'City Fix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, 
      routerConfig: _router,
    );
  }
}

// Configuración de rutas (Navigation)
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/crear',
      builder: (context, state) => const CrearIncidenciaScreen(),
    ),
    GoRoute(
      path: '/incidencia/:id',
      builder: (context, state) {
        // Obtenemos el objeto de Local en HomeScreen para no tener que hacer otro GET
        final incidencia = state.extra as Incidencia;
        return IncidenciaDetailScreen(incidencia: incidencia);
      },
    ),
  ],
);

// Pantalla temporal hasta que creemos las reales
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Construyendo: $title',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
