import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'layouts/main_layout.dart';

void main() {
  runApp(const CityFixManagerApp());
}

class CityFixManagerApp extends StatelessWidget {
  const CityFixManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'City Fix Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.desktopTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // Si no está autenticado, mostramos Login.
    // Si lo está, mostramos el Layout Principal.
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    
    return const MainLayout();
  }
}
