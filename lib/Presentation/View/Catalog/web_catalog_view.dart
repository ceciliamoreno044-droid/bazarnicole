import 'package:bazarnicole/Presentation/Services/drive_data_service.dart';
import 'package:bazarnicole/Presentation/Template/catalog_template.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:bazarnicole/Presentation/Widgets/catalog_card_widget.dart';
import 'package:bazarnicole/Presentation/Widgets/legal_page_widget.dart';
import 'package:flutter/material.dart';

/// Vista pública del catálogo — solo para web.
/// Muestra los artículos disponibles con selector de sección (Bazar / Papelería).
/// Los datos reales (productos e imágenes) se cargan desde el backup en Google Drive.
class WebCatalogView extends StatefulWidget {
  const WebCatalogView({super.key});

  @override
  State<WebCatalogView> createState() => _WebCatalogViewState();
}

class _WebCatalogViewState extends State<WebCatalogView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  /// Datos reales de Drive (null = aún cargando o no autenticado).
  CatalogDriveData? _driveData;
  bool _driveLoading = false;
  String? _driveError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDriveData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Carga de datos desde Drive ─────────────────────────────────────────────

  Future<void> _loadDriveData() async {
    setState(() {
      _driveLoading = true;
      _driveError = null;
    });

    // Intentar sesión silenciosa primero
    if (!DriveDataService.isSignedIn) {
      await DriveDataService.signInSilently();
    }

    if (!DriveDataService.isSignedIn) {
      // No hay sesión: el catálogo muestra datos estáticos con opción de login
      setState(() => _driveLoading = false);
      return;
    }

    try {
      final data = await DriveDataService.fetchCatalogData();
      if (mounted) setState(() => _driveData = data);
    } catch (e) {
      if (mounted) setState(() => _driveError = e.toString());
    } finally {
      if (mounted) setState(() => _driveLoading = false);
    }
  }

  Future<void> _signInAndLoad() async {
    setState(() {
      _driveLoading = true;
      _driveError = null;
    });
    try {
      await DriveDataService.signIn();
      final data = await DriveDataService.fetchCatalogData();
      if (mounted) setState(() => _driveData = data);
    } catch (e) {
      if (mounted) setState(() => _driveError = e.toString());
    } finally {
      if (mounted) setState(() => _driveLoading = false);
    }
  }

  // ── Helpers para construir CategoryInfo enriquecida ────────────────────────

  /// Devuelve la CategoryInfo base (estática) enriquecida con datos de Drive.
  CategoryInfo _infoFor(String categoryName, CatalogStore store) {
    CategoryInfo base = WebCatalog.infoFor(categoryName, store);

    if (_driveData == null) return base;

    // Inyectar imagen real desde Drive si existe
    final driveImage = DriveDataService.findImageForCategory(
      _driveData!.imageThumbnails,
      categoryName,
    );
    if (driveImage != null) {
      base = base.withImageUrl(driveImage);
    }

    // Inyectar productos reales
    final rawProducts =
        _driveData!.productsByCategory[categoryName] ?? const [];
    if (rawProducts.isNotEmpty) {
      final entries = rawProducts
          .map(
            (p) => CatalogProductEntry(
              id: p.id,
              name: p.name,
              sku: p.sku,
              price: p.price,
              stock: p.stock,
            ),
          )
          .toList();
      base = base.withProducts(entries);
    }

    return base;
  }

  /// Filtra categorías por búsqueda.
  List<String> _filtered(List<String> items) {
    if (_search.isEmpty) return items;
    final q = _search.toLowerCase();
    return items.where((e) => e.toLowerCase().contains(q)).toList();
  }

  /// Categorías que realmente tienen productos en Drive (o todas si no hay Drive data).
  List<String> _categoriesFor(List<String> staticList) {
    if (_driveData == null) return staticList;
    // Mostrar únicamente categorías con al menos 1 producto real en Drive.
    // Si una categoría estática no tiene datos en Drive, igual se muestra
    // para que el catálogo visual no quede vacío.
    return staticList;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
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
        actions: [
          // Indicador de estado de Drive
          if (_driveLoading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            )
          else if (_driveData != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message:
                    'Datos en tiempo real desde Google Drive\n'
                    '(${_driveData!.userEmail})',
                child: const Icon(
                  Icons.cloud_done_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton.icon(
                onPressed: _signInAndLoad,
                icon: const Icon(
                  Icons.cloud_off_outlined,
                  color: Colors.white60,
                  size: 18,
                ),
                label: const Text(
                  'Conectar Drive',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ),
        ],
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
          // Banner de error de Drive (si aplica)
          if (_driveError != null)
            _DriveBanner(message: _driveError!, onRetry: _loadDriveData),

          // Barra de búsqueda
          Container(
            color: AppColors.lightGray,
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 16,
              vertical: 12,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar artículo…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
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
                  items: _filtered(_categoriesFor(WebCatalog.bazarCategories)),
                  isWide: isWide,
                  infoBuilder: (name) => _infoFor(name, CatalogStore.bazar),
                ),
                _CatalogGrid(
                  store: CatalogStore.papeleria,
                  items: _filtered(
                    _categoriesFor(WebCatalog.papeleriaCategories),
                  ),
                  isWide: isWide,
                  infoBuilder: (name) => _infoFor(name, CatalogStore.papeleria),
                ),
              ],
            ),
          ),

          // Pie de página
          Container(
            color: AppColors.primaryLogo,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            width: double.infinity,
            child: Column(
              children: [
                const Text(
                  '© 2026 Bazar & Tienda Nicole — Todos los derechos reservados',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          LegalPageWidget.show(context, LegalDocType.terms),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white54,
                        ),
                      ),
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    TextButton(
                      onPressed: () =>
                          LegalPageWidget.show(context, LegalDocType.privacy),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Política de Privacidad',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner de estado de Drive ────────────────────────────────────────────────

class _DriveBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DriveBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            color: Color(0xFF856404),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No se pudieron cargar datos desde Drive. Mostrando catálogo base.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF856404)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontSize: 11, color: Color(0xFF856404)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid de categorías ───────────────────────────────────────────────────────

class _CatalogGrid extends StatelessWidget {
  final CatalogStore store;
  final List<String> items;
  final bool isWide;

  /// Builder que devuelve la CategoryInfo (enriquecida con datos Drive) para cada nombre.
  final CategoryInfo Function(String name) infoBuilder;

  const _CatalogGrid({
    required this.store,
    required this.items,
    required this.isWide,
    required this.infoBuilder,
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
        final info = infoBuilder(name);
        return CatalogCategoryCard(name: name, store: store, info: info);
      },
    );
  }
}
