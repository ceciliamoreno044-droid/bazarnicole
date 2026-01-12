import 'package:bazarnicole/Presentation/Controller/dashboard_controller.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  final DashboardController controller = DashboardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Ventas del día:'),
            // Aquí puedes agregar widgets para mostrar datos
            ElevatedButton(
              onPressed: () {
                controller.fetchSalesData();
              },
              child: Text('Actualizar Ventas'),
            ),
          ],
        ),
      ),
    );
  }
}