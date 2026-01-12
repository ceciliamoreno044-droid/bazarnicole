import 'package:flutter/material.dart';
import 'package:bazarnicole/Presentation/View/Auth/Login.dart';
import 'package:bazarnicole/Presentation/View/dashboard_view.dart';
import 'package:bazarnicole/Presentation/View/product_management_view.dart';
import 'package:bazarnicole/Presentation/View/inventory_view.dart';

class AppRoutes {
  // --- Rutas Públicas ---
  static const login = '/login';
  static const register = '/register';
  static const authenticate = '/authenticate';
  static const contracts = '/contracts';

  // --- Rutas de la aplicación ---
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const inventory = '/inventory';

  /// Todas las rutas registradas
  static final routes = <String, WidgetBuilder>{
    login: (context) => const LoginPage(),
    dashboard: (context) => DashboardView(),
    products: (context) => ProductManagementView(),
    inventory: (context) => InventoryView(),
  };

  /// Map de roles con rutas permitidas
  static final Map<String, List<String>> allowedRoutesByRole = {
    'admin': [
      login,
      register,
      authenticate,
      contracts,
      dashboard,
      products,
      inventory,
    ],
    'cajero': [
      login,
      authenticate,
      dashboard,
      // cajero no puede acceder a productos ni configuraciones sensibles
    ],
    'Inventario': [
      login,
      authenticate,
      dashboard,
      products,
      inventory,
    ],
    'Reportes': [
      login,
      authenticate,
      dashboard,
    ],
  };

  /// Obtiene las rutas permitidas para un rol específico
  static List<String> getRoutesForRole(String role) {
    return allowedRoutesByRole[role] ?? [login];
  }
}

