import 'package:bazarnicole/Presentation/View/Auth/app_routes.dart';
import 'package:bazarnicole/Presentation/View/Auth/auth_service.dart';
import 'package:bazarnicole/Presentation/View/Utils/Colors.dart';
import 'package:bazarnicole/Presentation/View/Widgets/Login/custom_app_bar.dart';
import 'package:bazarnicole/Presentation/View/Widgets/Login/email_input.dart';
import 'package:bazarnicole/Presentation/View/Widgets/Login/login_button.dart';
import 'package:bazarnicole/Presentation/View/Widgets/Login/logo_image.dart';
import 'package:bazarnicole/Presentation/View/Widgets/Login/password_input.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool loading = false;
  bool _obscurePassword = true;

  Future<void> login() async {
    // Validación básica
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Usar AuthService para autenticación
      final user = await _authService.login(email, password);

      if (user != null) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${user['email'] ?? email}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al dashboard real
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightWhite,
      appBar: const CustomLoginAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoImage(),
                const SizedBox(height: 30),
                EmailInput(controller: emailController),
                const SizedBox(height: 16),
                PasswordInput(
                  controller: passwordController,
                  obscurePassword: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 24),
                loading
                    ? const CircularProgressIndicator()
                    : LoginButton(onPressed: login),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
