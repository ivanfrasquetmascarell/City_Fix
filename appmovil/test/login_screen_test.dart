import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:city_fix_app/screens/login_screen.dart';
import 'package:city_fix_app/providers/auth_provider.dart';
import 'package:shared_models/shared_models.dart';

// Creamos un Mock sencillo del AuthProvider para que el test no haga llamadas reales a internet
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  Usuario? get usuario => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLoading => false;

  @override
  String? get token => null;

  @override
  int get nivelCelebrado => 0;

  @override
  int get totalIncidencias => 0;

  @override
  Future<bool> login(String email, String password) async { return true; }

  @override
  Future<bool> registro(String nombre, String email, String password) async { return true; }

  @override
  Future<void> logout() async {}

  @override
  bool actualizarPuntos(int nuevosPuntos) { return false; }

  @override
  String? checkBannedError(dynamic e) { return null; }

  @override
  Future<void> marcarNivelComoCelebrado(int nivel) async {}
}

void main() {
  testWidgets('LoginScreen muestra errores de validación si los campos están vacíos', (WidgetTester tester) async {
    // 1. Arrange: Construimos la pantalla envuelta en los Providers y MaterialApp necesarios
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Como LoginScreen tiene texto por defecto en los controladores (ivan@cityfix.es),
    // primero tenemos que borrarlos para probar la validación de campos vacíos.
    
    // Encontramos los campos de texto
    final emailField = find.byType(TextFormField).at(0);
    final passwordField = find.byType(TextFormField).at(1);
    
    // Borramos el texto
    await tester.enterText(emailField, '');
    await tester.enterText(passwordField, '');
    await tester.pump(); // Refrescar pantalla

    // 2. Act: Encontramos el botón de "Iniciar Sesión" y hacemos "tap" en él
    final loginButton = find.text('Iniciar Sesión');
    await tester.tap(loginButton);
    
    // Esperamos a que terminen las animaciones
    await tester.pumpAndSettle();

    // 3. Assert: Comprobamos que aparecen los textos de error de validación
    expect(find.text('Correo no válido'), findsOneWidget);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
  });
}
