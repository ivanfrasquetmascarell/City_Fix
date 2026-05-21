import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('Usuario Model Tests', () {
    test('Debe crear un Usuario correctamente a partir de un JSON válido', () {
      // 1. Arrange: Preparamos los datos simulando una respuesta del Backend
      final Map<String, dynamic> jsonResponse = {
        'id': '123-abc',
        'nombre': 'Ivan Frasquet',
        'email': 'ivan@cityfix.es',
        'rol': 'CIUDADANO',
        'puntos': 15,
        'bloqueado': false,
        'createdAt': '2026-05-21T10:00:00Z',
      };

      // 2. Act: Ejecutamos el método que queremos probar
      final usuario = Usuario.fromJson(jsonResponse);

      // 3. Assert: Comprobamos que el resultado es exactamente el esperado
      expect(usuario.id, '123-abc');
      expect(usuario.nombre, 'Ivan Frasquet');
      expect(usuario.email, 'ivan@cityfix.es');
      expect(usuario.rol, 'CIUDADANO');
      expect(usuario.puntos, 15);
      expect(usuario.bloqueado, false);
      expect(usuario.createdAt.year, 2026);
    });

    test('Debe manejar valores nulos en puntos y establecerlos en 0 por defecto', () {
      // 1. Arrange: JSON sin el campo 'puntos'
      final Map<String, dynamic> jsonResponse = {
        'id': '999-xyz',
        'nombre': 'Usuario Nuevo',
        'email': 'nuevo@cityfix.es',
        'rol': 'CIUDADANO',
        'bloqueado': true,
        'createdAt': '2026-05-21T10:00:00Z',
      };

      // 2. Act
      final usuario = Usuario.fromJson(jsonResponse);

      // 3. Assert
      expect(usuario.puntos, 0); // Comprueba el comportamiento por defecto (fail-safe)
      expect(usuario.bloqueado, true);
    });
  });
}
