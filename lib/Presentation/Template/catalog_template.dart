/// Modelo que representa un ítem del catálogo público (web)
class CatalogItem {
  final String name;
  final String category;
  final double price;
  final String store; // 'Bazar' | 'Papelería'
  final String description;
  final String imageUrl;
  final List<String> tags;
  final bool available;

  const CatalogItem({
    required this.name,
    required this.category,
    required this.price,
    required this.store,
    this.description = '',
    this.imageUrl = '',
    this.tags = const [],
    this.available = true,
  });
}

/// Tipo de sección del catálogo
enum CatalogStore {
  bazar('Bazar', 'Artículos de bazar, regalos y accesorios'),
  papeleria('Papelería', 'Útiles escolares, oficina y manualidades');

  final String label;
  final String description;
  const CatalogStore(this.label, this.description);
}

/// Catálogo estático para la vista web pública.
/// Muestra los artículos disponibles organizados por sección.
class WebCatalog {
  static const List<String> bazarCategories = [
    'Peluches',
    'Carteras y Bolsos',
    'Juguetes',
    'Portarretratos',
    'Accesorios de cocina',
    'Lámparas dormitorio',
    'Fundas de regalo',
    'Pelotas',
    'Mochilas y Loncheras',
    'Accesorios para fiestas',
    'Lazos y Vinchas',
    'Joyería y Accesorios',
    'Perfumes',
    'Esmaltes y Labiales',
    'Accesorios navideños',
    'Audífonos y Bluetooth',
    'Billeteras',
    'Velas aromáticas',
    'Cajas para obsequios',
    'Espejos',
    'Uñas postizas',
    'Rizador',
    'Pestañas postizas',
    'Llaveros',
    'Brochas para maquillaje',
    'Desodorantes',
    'Gel y fijación para pelo',
    'Tinte de cabello',
    'Corta uñas y Limas',
    'Pinza para cejas',
    'Alcancías',
    'Casino y entretenimiento',
  ];

  static const List<String> papeleriaCategories = [
    'Cuadernos',
    'Hojas A4 y Bond',
    'Papel crepé y Fomix',
    'Cartón prensado',
    'Agendas y Diccionarios',
    'Pinturas y Acuarelas',
    'Lápices de colores',
    'Resaltadores',
    'Esferos y Lapiceros',
    'Marcadores',
    'Borrador y Sacapuntas',
    'Silicona y Pegamento',
    'Reglas y Tijeras',
    'Lana e Hilos',
    'Cintas',
    'Adornos en fomix',
    'Pintura acrílica',
    'Slime',
    'Paletas de colores',
    'Calculadoras',
    'Estilete',
    'Perforadora',
    'Tape dispenser',
    'Grapadora',
    'Pilas',
    'Papel higiénico',
    'Peinillas',
  ];
}
