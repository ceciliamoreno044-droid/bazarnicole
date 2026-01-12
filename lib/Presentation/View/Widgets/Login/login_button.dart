import 'package:bazarnicole/Presentation/View/Utils/Colors.dart';
import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primaryLogo,
      ),
      child: const Text(
        'Iniciar sesión',
        style: TextStyle(fontSize: 16, color: Color(0xfff4f4f4)),
      ),
    );
  }
}
