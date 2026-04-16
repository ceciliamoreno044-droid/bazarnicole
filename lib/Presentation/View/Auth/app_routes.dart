import 'package:flutter/material.dart';
import 'package:bazarnicole/Presentation/View/Login/Login.dart';
import 'package:bazarnicole/Presentation/View/Customers/customers_view.dart';
import 'package:bazarnicole/Presentation/View/Cash/cash_view.dart';
import 'package:bazarnicole/Presentation/View/Dashboard/dashboard_page.dart';
import 'package:bazarnicole/Presentation/View/Inventory/inventory_view.dart';
import 'package:bazarnicole/Presentation/View/POS/pos_view.dart';
import 'package:bazarnicole/Presentation/View/Product/product_management_view.dart';
import 'package:bazarnicole/Presentation/View/Reports/reports_view.dart';

class AppRoutes {
  // --- Rutas Públicas ---
  static const login = '/login';
  static const register = '/register';
  static const authenticate = '/authenticate';
  static const contracts = '/contracts';

  // --- Rutas de la aplicación ---
  static const dashboard = '/dashboard';
  static const pos = '/pos';
  static const products = '/products';
  static const inventory = '/inventory';
  static const customers = '/customers';
  static const reports = '/reports';
  static const cash = '/cash';

  /// Todas las rutas registradas
  static final routes = <String, WidgetBuilder>{
    login: (context) => const LoginPage(),
    dashboard: (context) => const DashboardPage(),
    pos: (context) => const PosView(),
    products: (context) => const ProductManagementView(),
    inventory: (context) => const InventoryView(),
    customers: (context) => const CustomersView(),
    reports: (context) => const ReportsView(),
    cash: (context) => const CashView(),
  };

  /// Map de roles con rutas permitidas
  static final Map<String, List<String>> allowedRoutesByRole = {
    'admin': [
      login,
      register,
      authenticate,
      contracts,
      dashboard,
      pos,
      products,
      inventory,
      customers,
      reports,
      cash,
    ],
    'cajero': [
      login,
      authenticate,
      dashboard,
      pos,
      customers,
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
      reports,
    ],
  };

  /// Obtiene las rutas permitidas para un rol específico
  static List<String> getRoutesForRole(String role) {
    return allowedRoutesByRole[role] ?? [login];
  }
}

