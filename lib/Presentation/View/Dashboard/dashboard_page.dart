import 'package:bazarnicole/Presentation/Services/auth_service.dart';
import 'package:bazarnicole/Presentation/View/Auth/app_routes.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 0;
  final bool _hayCajaAbierta = false;

  final Map<String, String> _cardRoutes = {
    'POS': AppRoutes.pos,
    'Inventario': AppRoutes.inventory,
    'Productos': AppRoutes.products,
    'Clientes': AppRoutes.customers,
    'Caja': AppRoutes.cash,
    'Reportes': AppRoutes.reports,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn || user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  List<Widget> _buildCardsForRole(String role) {
    final allowed = AppRoutes.allowedRoutesByRole[role] ?? [AppRoutes.login];
    final List<Widget> cards = [];

    _cardRoutes.forEach((title, route) {
      if (allowed.contains(route)) {
        cards.add(
          _DashboardCard(
            title: title,
            icon: _getIconForTitle(title),
            onTap: () => Navigator.pushNamed(context, route),
          ),
        );
      }
    });

    if (cards.isEmpty) {
      cards.add(
        Center(child: Text('No tienes accesos asignados para tu rol ($role)')),
      );
    }

    return cards;
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: AppBar(
          title: Column(
            children: [
              const Text(
                'Panel de Control',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.threeColor,
                  fontSize: 18,
                ),
              ),
              if (_currentUser != null)
                Text(
                  'Bienvenido, ${_currentUser!['name'] ?? _currentUser!['nombreCompleto'] ?? 'Usuario'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.threeColor,
                  ),
                ),
            ],
          ),
          iconTheme: const IconThemeData(color: AppColors.threeColor),
          backgroundColor: AppColors.primaryLogo,
          elevation: 4,
          centerTitle: true,
          actions: [
            // Indicador de estado de caja
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _hayCajaAbierta ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _hayCajaAbierta ? Icons.check_circle : Icons.lock,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _hayCajaAbierta ? 'Caja Abierta' : 'Caja Cerrada',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?['name'] ?? 'Usuario'),
            accountEmail: Text(_currentUser?['email'] ?? 'email@correo.com'),
            decoration: BoxDecoration(color: AppColors.primaryLogo),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Panel de Control'),
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _currentUser?['role'] ?? 'user';
    final cards = _buildCardsForRole(role);

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) => cards[index],
            ),
          ),
          // Perfil: placeholder hasta que exista la pantalla real
          Center(child: Text('Perfil: ${_currentUser?['name'] ?? ''}')),
        ],
      ),
      floatingActionButton: role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              icon: const Icon(Icons.person_add),
              label: const Text('Registrar'),
            )
          : null,
    );
  }

  IconData _getIconForTitle(String titulo) {
    switch (titulo) {
      case 'POS':
        return Icons.point_of_sale;
      case 'Productos':
        return Icons.inventory_2_outlined;
      case 'Inventario':
        return Icons.storefront_outlined;
      case 'Clientes':
        return Icons.groups_2_outlined;
      case 'Caja':
        return Icons.account_balance_wallet_outlined;
      case 'Reportes':
        return Icons.bar_chart_outlined;
      default:
        return Icons.help_outline;
    }
  }

}


class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppColors.primaryLogo),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
