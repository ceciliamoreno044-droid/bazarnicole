import 'package:bazarnicole/Presentation/Template/catalog_template.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:bazarnicole/Presentation/Widgets/catalog_card_widget.dart';
import 'package:flutter/material.dart';

/// Vista pública del catálogo — solo para web.
/// Muestra los artículos disponibles con selector de sección (Bazar / Papelería).
class WebCatalogView extends StatefulWidget {
  const WebCatalogView({super.key});

  @override
  State<WebCatalogView> createState() => _WebCatalogViewState();
}

class _WebCatalogViewState extends State<WebCatalogView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _filtered(List<String> items) {
    if (_search.isEmpty) return items;
    final q = _search.toLowerCase();
    return items.where((e) => e.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.lightWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryLogo,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.storefront_outlined, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bazar & Tienda Nicole',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Catálogo de productos',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: CatalogStore.values
              .map(
                (s) => Tab(
                  icon: Icon(
                    s == CatalogStore.bazar
                        ? Icons.shopping_bag_outlined
                        : Icons.menu_book_outlined,
                  ),
                  text: s.label,
                ),
              )
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: AppColors.primaryLogo.withOpacity(0.05),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 16,
              vertical: 12,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar artículo…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CatalogGrid(
                  store: CatalogStore.bazar,
                  items: _filtered(WebCatalog.bazarCategories),
                  isWide: isWide,
                ),
                _CatalogGrid(
                  store: CatalogStore.papeleria,
                  items: _filtered(WebCatalog.papeleriaCategories),
                  isWide: isWide,
                ),
              ],
            ),
          ),

          // Pie de página
          Container(
            color: AppColors.primaryLogo,
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            child: const Text(
              '© 2026 Bazar & Tienda Nicole — Todos los derechos reservados',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  final CatalogStore store;
  final List<String> items;
  final bool isWide;

  const _CatalogGrid({
    required this.store,
    required this.items,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.greyOverlay),
            const SizedBox(height: 8),
            const Text('No se encontraron artículos'),
          ],
        ),
      );
    }

    final crossCount = isWide ? 4 : 2;
    // Las cards son más altas para mostrar imagen + descripción
    final childAspectRatio = isWide ? 0.72 : 0.65;

    return GridView.builder(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final name = items[i];
        final info = WebCatalog.infoFor(name, store);
        return CatalogCategoryCard(
          name: name,
          store: store,
          info: info,
        );
      },
    );
  }
}

