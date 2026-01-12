import 'package:bazarnicole/Presentation/Controller/product_management_controller.dart';
import 'package:flutter/material.dart';

class ProductManagementView extends StatelessWidget {
  final ProductManagementController controller = ProductManagementController();

  ProductManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Productos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Crear / Editar Producto'),
            // Aquí puedes agregar formularios para crear o editar productos
          ],
        ),
      ),
    );
  }
}