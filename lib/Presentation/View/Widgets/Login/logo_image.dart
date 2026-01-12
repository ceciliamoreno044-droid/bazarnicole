import 'package:flutter/material.dart';

class LogoImage extends StatelessWidget {
  const LogoImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: Offset(-10, 10),
            color: Color.fromARGB(80, 0, 0, 0),
            blurRadius: 10,
          ),
          BoxShadow(
            offset: Offset(10, -10),
            color: Color.fromARGB(150, 255, 255, 255),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.asset(
          'assets/image/logobazasr.png',
          fit: BoxFit.cover,
          height: 180,
          errorBuilder: (context, error, stackTrace) {
            // Si falla el asset local, intentar cargar desde la red
            return Image.network(
              'https://storage.googleapis.com/repogalleryautorepuesto/AutoRepoLogo.png',
              fit: BoxFit.cover,
              height: 180,
              errorBuilder: (context, networkError, networkStackTrace) {
                return const Icon(Icons.error, size: 50, color: Colors.red);
              },
            );
          },
        ),
      ),
    );
  }
}