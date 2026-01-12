import 'package:bazarnicole/Presentation/Controller/inventory_controller.dart';
import 'package:flutter/material.dart';

class InventoryView extends StatelessWidget {
  final InventoryController controller = InventoryController();

  InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Lista de Productos'),
            // Aquí puedes agregar widgets para mostrar el inventario
          ],
        ),
      ),
    );
  }
}