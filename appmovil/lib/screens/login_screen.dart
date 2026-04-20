import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'ivan@cityfix.es'); // Correo de prueba rellenado
  final _passwordController = TextEditingController(text: 'ciudadano1234');
  final _nombreController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true; // Si es falso, mostramos el formulario de registro

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      if (_isLogin) {
        await auth.login(_emailController.text, _passwordController.text);
      } else {
        await auth.registro(
          _nombreController.text,
          _emailController.text,
          _passwordController.text,
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.location_city, size: 80, color: AppTheme.primaryColor)
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  Text(
                    'City Fix',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Bienvenido de nuevo' : 'Únete para mejorar tu ciudad',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),

                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ).animate().slideX(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v!.contains('@') ? null : 'Correo no válido',
                  ).animate().slideX(begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms).fadeIn(),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v!.length >= 6 ? null : 'Mínimo 6 caracteres',
                  ).animate().slideX(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms).fadeIn(),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse', style: const TextStyle(fontSize: 16)),
                  ).animate().scale(delay: 400.ms),
                  
                  const SizedBox(height: 24),
                  
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        // Limpiar campos si vamos a registro
                        if (!_isLogin) {
                          _emailController.clear();
                          _passwordController.clear();
                        } else {
                          _emailController.text = 'ivan@cityfix.es';
                          _passwordController.text = 'ciudadano1234';
                        }
                      });
                    },
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate aquí'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
