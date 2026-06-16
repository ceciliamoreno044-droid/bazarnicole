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
  TabController? _tabController;
  String _search = '';

  /// Datos reales de Drive (null = aún cargando).
  CatalogDriveData? _driveData;
  bool _driveLoading = false;
  String? _driveError;

  List<CatalogSection> get _sections => _driveData?.sections ?? [];

  void _initTabController() {
    _tabController?.dispose();
    final count = _sections.isEmpty ? 1 : _sections.length;
    _tabController = TabController(length: count, vsync: this);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadDriveData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ── Carga de datos desde Drive ─────────────────────────────────────────────

  // ── Carga de datos desde Drive (pública, sin login) ─────────────────────────

  Future<void> _loadDriveData() async {
    setState(() {
      _driveLoading = true;
      _driveError = null;
    });
    try {
      final data = await DriveDataService.fetchPublic();
      if (mounted) {
        setState(() {
          _driveData = data;
          _initTabController();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _driveError = e.toString());
    } finally {
      if (mounted) setState(() => _driveLoading = false);
    }
  }

  /// Filtra categorías por búsqueda.
  List<CatalogCategory> _filtered(List<CatalogCategory> items) {
    if (_search.isEmpty) return items;
    final q = _search.toLowerCase();
    return items.where((c) => c.name.toLowerCase().contains(q)).toList();
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
                message: 'Datos en tiempo real desde Google Drive',
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
                onPressed: _loadDriveData,
                icon: const Icon(
                  Icons.refresh_outlined,
                  color: Colors.white60,
                  size: 18,
                ),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ),
        ],
        bottom: _sections.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: _sections
                    .map(
                      (s) => Tab(
                        icon: Icon(
                          s.storeId == 1
                              ? Icons.shopping_bag_outlined
                              : Icons.menu_book_outlined,
                        ),
                        text: s.storeName,
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
            child: _driveLoading && _sections.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: AppColors.greyOverlay,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No se pudo cargar el catálogo',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadDriveData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: _sections
                        .map(
                          (section) => _CatalogGrid(
                            categories: _filtered(section.categories),
                            isWide: isWide,
                          ),
                        )
                        .toList(),
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
  final List<CatalogCategory> categories;
  final bool isWide;

  const _CatalogGrid({required this.categories, required this.isWide});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
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
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final category = categories[i];
        final store =
            CatalogStore.fromId(category.storeId) ?? CatalogStore.bazar;
        return CatalogCategoryCard(
          name: category.name,
          store: store,
          info: category,
        );
      },
    );
  }
}
