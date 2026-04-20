import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_drawer.dart';

class PortadaPuebloScreen extends StatelessWidget {
  const PortadaPuebloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor, size: 28),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // Fondo con degradado suave o imagen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // LOGO / ESCUDO (Placeholder con Icono Premium para Gandía)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Hero(
                      tag: 'town-logo',
                      child: Icon(
                        Icons.account_balance, // Icono institucional
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 40),
                  
                  // TÍTULO
                  Text(
                    '¡Bienvenidos a Gandía!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 20),
                  
                  // DESCRIPCIÓN
                  Text(
                    'Gandía es una ciudad comprometida con sus ciudadanos. A través de City Fix, trabajamos juntos para mantener nuestras calles, parques e infraestructuras en perfecto estado. Gracias por ayudarnos a mejorar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                  
                  const Spacer(),
                  
                  // BOTÓN DE ACCIÓN
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/incidencias'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.list_alt, color: Colors.white),
                      label: const Text(
                        'CONSULTAR MIS INCIDENCIAS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).moveY(begin: 30, end: 0),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
