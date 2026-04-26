import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class NivelUpDialog extends StatelessWidget {
  final int nuevoNivel;

  const NivelUpDialog({super.key, required this.nuevoNivel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de Trofeo Animado
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: Colors.amber,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.5))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .shake(delay: 1.seconds, hz: 4),
            
            const SizedBox(height: 24),
            
            Text(
              '¡ENHORABUENA!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),

            const SizedBox(height: 8),

            Text(
              'Has alcanzado el',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'NIVEL $nuevoNivel',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ).animate().scale(delay: 700.ms, curve: Curves.bounceOut),

            const SizedBox(height: 20),

            Text(
              'Tu compromiso con Gandía es ejemplar. ¡Gracias por ayudarnos a mejorar!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '¡A POR MÁS!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ).animate().scale(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
