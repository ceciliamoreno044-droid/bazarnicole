import 'package:flutter/material.dart';
import 'package:bazarnicole/Presentation/Template/catalog_template.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Bottom sheet de detalle de una categoría del catálogo.
/// Muestra imagen grande, descripción completa, tags y galería de placeholder.
class CatalogDetailWidget extends StatelessWidget {
  final String name;
  final CatalogStore store;
  final CategoryInfo info;

  const CatalogDetailWidget({
    super.key,
    required this.name,
    required this.store,
    required this.info,
  });

  Color get _accent => store == CatalogStore.bazar
      ? AppColors.blackOverlay
      : const Color(0xFF2E7D32);

  String get _storeLabel =>
      store == CatalogStore.bazar ? 'Bazar Nicole' : 'Papelería Nicole';

  IconData get _storeIcon => store == CatalogStore.bazar
      ? Icons.shopping_bag_outlined
      : Icons.menu_book_outlined;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = MediaQuery.of(context).size.width > 700;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyOverlay,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Contenido scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Imagen hero ────────────────────────────────
                    _HeroImage(
                      imageUrl: info.imageUrl,
                      accentColor: _accent,
                      height: isWide ? screenHeight * 0.3 : screenHeight * 0.26,
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 40 : 20,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Tienda badge ───────────────────────
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _storeIcon,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _storeLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Disponibilidad
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF43A047),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Disponible',
                                    style: TextStyle(
                                      color: AppColors.mediumGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Nombre ─────────────────────────────
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: isWide ? 26 : 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkGray,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Descripción completa ───────────────
                          Text(
                            info.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mediumGray,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Tags ───────────────────────────────
                          if (info.tags.isNotEmpty) ...[
                            Text(
                              'Etiquetas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: info.tags
                                  .map(
                                    (t) => _DetailTag(label: t, color: _accent),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Productos reales (si vienen de Drive) ───
                          if (info.products.isNotEmpty) ...[
                            Text(
                              'Productos disponibles (${info.products.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ProductList(
                              products: info.products,
                              accentColor: _accent,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Galería de imágenes ─────────────────
                          Text(
                            'Vista de productos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProductGallery(
                            imageUrl: info.imageUrl,
                            accentColor: _accent,
                          ),

                          const SizedBox(height: 24),

                          // ── Código QR de la categoría ───────────
                          _CategoryQr(
                            categoryName: name,
                            accentColor: _accent,
                          ),

                          const SizedBox(height: 24),

                          // ── Llamado a la acción ─────────────────
                          _ContactCTA(accentColor: _accent),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Imagen hero en la parte superior del detalle.
class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final Color accentColor;
  final double height;

  const _HeroImage({
    required this.imageUrl,
    required this.accentColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                color: Colors.white38,
                size: 64,
              ),
            ),
          ),
          // Gradiente inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Galería de miniaturas con variaciones de la imagen principal.
class _ProductGallery extends StatelessWidget {
  final String imageUrl;
  final Color accentColor;

  // Variantes de seed para simular distintas fotos del mismo artículo
  static const List<String> _seeds = ['200', '210', '220', '230'];

  const _ProductGallery({required this.imageUrl, required this.accentColor});

  String _variantUrl(String seed) {
    // Usa el parámetro ?w= para ligeras variaciones de encuadre
    final base = imageUrl.contains('?') ? imageUrl.split('?').first : imageUrl;
    return '$base?w=300&q=70&fit=crop&crop=entropy&s=$seed';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _seeds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 90,
              height: 90,
              child: Image.network(
                _variantUrl(_seeds[i]),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: accentColor.withOpacity(0.12),
                  child: Icon(
                    Icons.image_outlined,
                    color: accentColor.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Chip de tag con borde y color de acento.
class _DetailTag extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Sección con código QR que apunta al catálogo web filtrado por categoría.
class _CategoryQr extends StatelessWidget {
  final String categoryName;
  final Color accentColor;

  const _CategoryQr({required this.categoryName, required this.accentColor});

  String get _qrUrl =>
      'https://ceciliamoreno044-droid.github.io/catalogobazartienda/#/catalog?categoria=${Uri.encodeComponent(categoryName)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Código QR de esta categoría',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: QrImageView(
              data: _qrUrl,
              version: QrVersions.auto,
              size: 180,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: accentColor,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _qrUrl,
            style: TextStyle(fontSize: 10, color: accentColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Sección de llamado a la acción al final del detalle.
class _ContactCTA extends StatelessWidget {
  final Color accentColor;

  const _ContactCTA({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Te interesa este artículo?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Visítanos en tienda o contáctanos para más información.',
                  style: TextStyle(fontSize: 11, color: AppColors.mediumGray),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: accentColor, size: 22),
        ],
      ),
    );
  }
}

// ── Lista de productos reales de Drive ────────────────────────────────────────

/// Lista compacta de productos reales de la categoría, con nombre, SKU y precio.
class _ProductList extends StatelessWidget {
  final List<CatalogProductEntry> products;
  final Color accentColor;

  const _ProductList({required this.products, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products
          .map((p) => _ProductRow(product: p, color: accentColor))
          .toList(),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final CatalogProductEntry product;
  final Color color;

  const _ProductRow({required this.product, required this.color});

  String get _qrUrl =>
      'https://ceciliamoreno044-droid.github.io/catalogobazartienda/#/catalog?sku=${Uri.encodeComponent(product.sku.isNotEmpty ? product.sku : product.id.toString())}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícono de producto
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          // Nombre y SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.sku.isNotEmpty)
                  Text(
                    'SKU: ${product.sku}',
                    style: TextStyle(fontSize: 10, color: AppColors.mediumGray),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Precio y stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (product.stock > 0)
                Text(
                  '${product.stock} en stock',
                  style: TextStyle(fontSize: 10, color: AppColors.mediumGray),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Código QR del producto — toca para ampliar
          GestureDetector(
            onTap: () => _showQrDialog(context),
            child: QrImageView(
              data: _qrUrl,
              version: QrVersions.auto,
              size: 52,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.sku.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.sku}',
                  style: TextStyle(fontSize: 11, color: AppColors.mediumGray),
                ),
              ],
              const SizedBox(height: 16),
              QrImageView(
                data: _qrUrl,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _qrUrl,
                style: TextStyle(fontSize: 10, color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
