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

/// Información de categoría: descripción, imagen de portada y etiquetas.
class CategoryInfo {
  final String description;
  final String imageUrl;
  final List<String> tags;

  const CategoryInfo({
    required this.description,
    required this.imageUrl,
    this.tags = const [],
  });
}

/// Catálogo estático para la vista web pública.
/// Muestra los artículos disponibles organizados por sección.
class WebCatalog {
  /// Devuelve la info extra de una categoría (descripción, imagen, tags).
  static CategoryInfo infoFor(String category, CatalogStore store) {
    return _categoryInfo[category] ??
        CategoryInfo(
          description: store == CatalogStore.bazar
              ? 'Artículo de bazar disponible en tienda.'
              : 'Artículo de papelería disponible en tienda.',
          imageUrl: store == CatalogStore.bazar
              ? 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=600'
              : 'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=600',
          tags: const [],
        );
  }

  static const Map<String, CategoryInfo> _categoryInfo = {
    // ── BAZAR ────────────────────────────────────────────────────────
    'Peluches': CategoryInfo(
      description:
          'Tiernos peluches de todo tipo: osos, unicornios, animales y personajes. Perfectos como regalo para niños y adultos.',
      imageUrl:
          'https://images.unsplash.com/photo-1559181567-c3190ca9d222?w=600',
      tags: ['Regalo', 'Niños', 'Suave'],
    ),
    'Carteras y Bolsos': CategoryInfo(
      description:
          'Amplia variedad de carteras y bolsos para mujer, en diferentes colores, tamaños y estilos: casual, elegante y deportivo.',
      imageUrl:
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
      tags: ['Moda', 'Mujer', 'Accesorio'],
    ),
    'Juguetes': CategoryInfo(
      description:
          'Juguetes educativos y de entretenimiento para niños de todas las edades. Fomentamos la creatividad y el aprendizaje.',
      imageUrl:
          'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=600',
      tags: ['Niños', 'Educativo', 'Diversión'],
    ),
    'Portarretratos': CategoryInfo(
      description:
          'Portarretratos de madera, metal y plástico en distintos formatos para decorar tu hogar con los mejores recuerdos.',
      imageUrl:
          'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=600',
      tags: ['Decoración', 'Hogar', 'Regalo'],
    ),
    'Accesorios de cocina': CategoryInfo(
      description:
          'Accesorios prácticos para tu cocina: recipientes, utensilios, organizadores y más. Calidad y funcionalidad en un solo lugar.',
      imageUrl:
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600',
      tags: ['Hogar', 'Cocina', 'Funcional'],
    ),
    'Lámparas dormitorio': CategoryInfo(
      description:
          'Lámparas de mesa y veladores para habitación. Diseños modernos y acogedores para crear el ambiente ideal en tu cuarto.',
      imageUrl:
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=600',
      tags: ['Decoración', 'Luz', 'Hogar'],
    ),
    'Fundas de regalo': CategoryInfo(
      description:
          'Fundas y bolsas de regalo en papel y tela, con diseños festivos para cumpleaños, navidad, baby shower y más ocasiones.',
      imageUrl:
          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=600',
      tags: ['Regalo', 'Fiesta', 'Envoltorio'],
    ),
    'Pelotas': CategoryInfo(
      description:
          'Pelotas de fútbol, básquet, playa y más. Para jugar al aire libre y practicar deporte con amigos y familia.',
      imageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=600',
      tags: ['Deporte', 'Niños', 'Juego'],
    ),
    'Mochilas y Loncheras': CategoryInfo(
      description:
          'Mochilas escolares y loncheras con diseños de personajes y colores vibrantes. Resistentes y con amplio espacio de almacenamiento.',
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
      tags: ['Escolar', 'Niños', 'Organizador'],
    ),
    'Accesorios para fiestas': CategoryInfo(
      description:
          'Todo para decorar tu fiesta: globos, serpentinas, cotillones, guirnaldas y más. Celebra cada momento con estilo.',
      imageUrl:
          'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?w=600',
      tags: ['Fiesta', 'Decoración', 'Celebración'],
    ),
    'Lazos y Vinchas': CategoryInfo(
      description:
          'Lazos, vinchas y accesorios para el cabello en una gran variedad de colores, telas y estilos para niñas y mujeres.',
      imageUrl:
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600',
      tags: ['Cabello', 'Niñas', 'Moda'],
    ),
    'Joyería y Accesorios': CategoryInfo(
      description:
          'Aretes, collares, pulseras y anillos de moda. Bisutería fina y elegante para complementar cualquier look.',
      imageUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600',
      tags: ['Joyería', 'Moda', 'Mujer'],
    ),
    'Perfumes': CategoryInfo(
      description:
          'Fragancias para hombre y mujer: perfumes, colonias y splash corporales de aromas florales, frescos y amaderados.',
      imageUrl:
          'https://images.unsplash.com/photo-1541643600914-78b084683702?w=600',
      tags: ['Belleza', 'Fragancia', 'Regalo'],
    ),
    'Esmaltes y Labiales': CategoryInfo(
      description:
          'Esmaltes de uñas en cientos de colores y labiales de larga duración. Maquillaje accesible y de tendencia para lucir perfecta.',
      imageUrl:
          'https://images.unsplash.com/photo-1586495777744-4e6232bf3077?w=600',
      tags: ['Maquillaje', 'Belleza', 'Uñas'],
    ),
    'Accesorios navideños': CategoryInfo(
      description:
          'Esferas, luces, adornos y todo para decorar tu árbol y hogar en Navidad. Crea la atmósfera más festiva del año.',
      imageUrl:
          'https://images.unsplash.com/photo-1482517967863-00e15c9b44be?w=600',
      tags: ['Navidad', 'Decoración', 'Festivo'],
    ),
    'Audífonos y Bluetooth': CategoryInfo(
      description:
          'Audífonos con y sin cable, parlantes bluetooth y accesorios de audio para música, llamadas y entretenimiento diario.',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
      tags: ['Tecnología', 'Audio', 'Música'],
    ),
    'Billeteras': CategoryInfo(
      description:
          'Billeteras para hombre y mujer en cuero sintético y tela. Diseños modernos con múltiples compartimentos para tarjetas y billetes.',
      imageUrl:
          'https://images.unsplash.com/photo-1627123424574-724758594e93?w=600',
      tags: ['Accesorio', 'Cuero', 'Práctico'],
    ),
    'Velas aromáticas': CategoryInfo(
      description:
          'Velas aromáticas artesanales en cera de soya y parafina. Aromas relajantes para el hogar: lavanda, vainilla, canela y más.',
      imageUrl:
          'https://images.unsplash.com/photo-1602607144011-c6239039803a?w=600',
      tags: ['Aromas', 'Relajación', 'Hogar'],
    ),
    'Cajas para obsequios': CategoryInfo(
      description:
          'Cajas decorativas para armar el regalo perfecto. Diferentes tamaños, colores y diseños para toda ocasión especial.',
      imageUrl:
          'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=600',
      tags: ['Regalo', 'Envoltorio', 'Decoración'],
    ),
    'Espejos': CategoryInfo(
      description:
          'Espejos de mano, de bolsillo y de pared con marcos decorativos. Imprescindibles para tu tocador y para decorar espacios.',
      imageUrl:
          'https://images.unsplash.com/photo-1596447594408-467e6e8cfe72?w=600',
      tags: ['Belleza', 'Decoración', 'Hogar'],
    ),
    'Uñas postizas': CategoryInfo(
      description:
          'Uñas acrílicas y press-on de diferentes formas, tamaños y diseños. Manicura perfecta en minutos desde casa.',
      imageUrl:
          'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=600',
      tags: ['Belleza', 'Uñas', 'Moda'],
    ),
    'Rizador': CategoryInfo(
      description:
          'Rizadores y onduladores para crear peinados perfectos. Con protección de temperatura y distintos tamaños de rizo.',
      imageUrl:
          'https://images.unsplash.com/photo-1522338140262-f46f5913618a?w=600',
      tags: ['Cabello', 'Belleza', 'Estilismo'],
    ),
    'Pestañas postizas': CategoryInfo(
      description:
          'Pestañas postizas de pelo natural y sintético. Desde looks naturales hasta dramáticos para ocasiones especiales.',
      imageUrl:
          'https://images.unsplash.com/photo-1583241800698-e8ab01830a22?w=600',
      tags: ['Maquillaje', 'Belleza', 'Ojos'],
    ),
    'Llaveros': CategoryInfo(
      description:
          'Llaveros personalizados, de personajes, metálicos y de cuero. El detalle perfecto para regalar o para ti mismo.',
      imageUrl:
          'https://images.unsplash.com/photo-1634577153016-a646ad01f0d0?w=600',
      tags: ['Accesorio', 'Regalo', 'Personalizado'],
    ),
    'Brochas para maquillaje': CategoryInfo(
      description:
          'Set de brochas profesionales para base, contorno, sombras y más. Cerdas suaves para una aplicación perfecta.',
      imageUrl:
          'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600',
      tags: ['Maquillaje', 'Belleza', 'Profesional'],
    ),
    'Desodorantes': CategoryInfo(
      description:
          'Desodorantes en barra, roll-on y spray para hombre y mujer. Frescura y protección de larga duración todo el día.',
      imageUrl:
          'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=600',
      tags: ['Higiene', 'Frescura', 'Cuidado personal'],
    ),
    'Gel y fijación para pelo': CategoryInfo(
      description:
          'Geles, cremas y sprays fijadores para todo tipo de peinado. Control fuerte y flexible sin maltrato al cabello.',
      imageUrl:
          'https://images.unsplash.com/photo-1522338140262-f46f5913618a?w=600',
      tags: ['Cabello', 'Estilo', 'Cuidado'],
    ),
    'Tinte de cabello': CategoryInfo(
      description:
          'Tintes semipermanentes y permanentes en una paleta de colores vibrantes y naturales para transformar tu look.',
      imageUrl:
          'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=600',
      tags: ['Cabello', 'Color', 'Transformación'],
    ),
    'Corta uñas y Limas': CategoryInfo(
      description:
          'Corta uñas de acero inoxidable, limas de diferentes granos y estuches de manicura completos para el cuidado de tus manos.',
      imageUrl:
          'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=600',
      tags: ['Manicura', 'Higiene', 'Cuidado'],
    ),
    'Pinza para cejas': CategoryInfo(
      description:
          'Pinzas de precisión y kits de depilación para cejas perfectas. Diseño ergonómico para mayor control y comodidad.',
      imageUrl:
          'https://images.unsplash.com/photo-1583241800698-e8ab01830a22?w=600',
      tags: ['Belleza', 'Cejas', 'Precisión'],
    ),
    'Alcancías': CategoryInfo(
      description:
          'Alcancías decorativas para niños y adultos. Formas divertidas de animales, personajes y diseños creativos para ahorrar.',
      imageUrl:
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=600',
      tags: ['Ahorro', 'Niños', 'Decoración'],
    ),
    'Casino y entretenimiento': CategoryInfo(
      description:
          'Juegos de mesa, naipes, dados, ruletas y más para noches de entretenimiento en familia o con amigos.',
      imageUrl:
          'https://images.unsplash.com/photo-1626958390928-3a3d26c9de5d?w=600',
      tags: ['Entretenimiento', 'Juego', 'Familia'],
    ),

    // ── PAPELERÍA ────────────────────────────────────────────────────
    'Cuadernos': CategoryInfo(
      description:
          'Cuadernos universitarios, escolares y cuadriculados de 50, 100 y 200 hojas. Tapas duras y blandas en varios diseños.',
      imageUrl:
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
      tags: ['Escolar', 'Escritura', 'Organización'],
    ),
    'Hojas A4 y Bond': CategoryInfo(
      description:
          'Resmas de papel A4 bond 75 gr para impresora y papel bond para escritura manual. Blancura superior y acabado liso.',
      imageUrl:
          'https://images.unsplash.com/photo-1568667256549-094345857637?w=600',
      tags: ['Papel', 'Oficina', 'Impresión'],
    ),
    'Papel crepé y Fomix': CategoryInfo(
      description:
          'Papel crepé y foamy en todos los colores del arcoíris. Ideal para manualidades, decoraciones y proyectos escolares.',
      imageUrl:
          'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=600',
      tags: ['Manualidades', 'Arte', 'Color'],
    ),
    'Cartón prensado': CategoryInfo(
      description:
          'Cartón prensado en láminas de varios grosores para maquetas, encuadernación y proyectos de arte y diseño.',
      imageUrl:
          'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=600',
      tags: ['Manualidades', 'Maquetas', 'Arte'],
    ),
    'Agendas y Diccionarios': CategoryInfo(
      description:
          'Agendas 2026 con planificador mensual y semanal, y diccionarios ilustrados para todos los niveles escolares.',
      imageUrl:
          'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=600',
      tags: ['Organización', 'Escolar', 'Planificación'],
    ),
    'Pinturas y Acuarelas': CategoryInfo(
      description:
          'Sets de acuarelas, temperas y pinturas al agua de 12, 18 y 24 colores. Para uso escolar y artístico.',
      imageUrl:
          'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600',
      tags: ['Arte', 'Pintura', 'Escolar'],
    ),
    'Lápices de colores': CategoryInfo(
      description:
          'Lápices de colores en cajas de 12 a 48 unidades. Minas suaves de alta pigmentación para colorear y dibujar.',
      imageUrl:
          'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=600',
      tags: ['Arte', 'Color', 'Escolar'],
    ),
    'Resaltadores': CategoryInfo(
      description:
          'Resaltadores de colores fluorescentes de punta biselada. Ideales para estudiar, subrayar apuntes y organizar información.',
      imageUrl:
          'https://images.unsplash.com/photo-1456735190827-d1262f71b8a3?w=600',
      tags: ['Estudio', 'Organización', 'Oficina'],
    ),
    'Esferos y Lapiceros': CategoryInfo(
      description:
          'Esferos y bolígrafos de tinta azul, negra y roja. Con tinta de flujo uniforme para una escritura suave y precisa.',
      imageUrl:
          'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=600',
      tags: ['Escritura', 'Escolar', 'Oficina'],
    ),
    'Marcadores': CategoryInfo(
      description:
          'Marcadores permanentes y borrables, punta fina y gruesa. Para pizarras, carteles, manualidades y uso escolar.',
      imageUrl:
          'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=600',
      tags: ['Arte', 'Escritura', 'Escolar'],
    ),
    'Borrador y Sacapuntas': CategoryInfo(
      description:
          'Borradores de vinilo sin PVC y sacapuntas metálicos de doble agujero. Precisión y limpieza para cada trazo.',
      imageUrl:
          'https://images.unsplash.com/photo-1456735190827-d1262f71b8a3?w=600',
      tags: ['Escolar', 'Precisión', 'Herramienta'],
    ),
    'Silicona y Pegamento': CategoryInfo(
      description:
          'Pegamento en barra, líquido y pistola de silicona caliente. Adhesivos seguros para papel, foamy, tela y más materiales.',
      imageUrl:
          'https://images.unsplash.com/photo-1581093452543-c2f14a2fb9f9?w=600',
      tags: ['Manualidades', 'Pegamento', 'Arte'],
    ),
    'Reglas y Tijeras': CategoryInfo(
      description:
          'Reglas de 15, 20 y 30 cm, transportadores y tijeras escolares y de uso general con punta redondeada y filo superior.',
      imageUrl:
          'https://images.unsplash.com/photo-1456735190827-d1262f71b8a3?w=600',
      tags: ['Herramienta', 'Escolar', 'Medición'],
    ),
    'Lana e Hilos': CategoryInfo(
      description:
          'Lana acrílica y algodón para tejido, crochet y manualidades. Gran variedad de colores y grosores disponibles.',
      imageUrl:
          'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=600',
      tags: ['Tejido', 'Manualidades', 'Arte'],
    ),
    'Cintas': CategoryInfo(
      description:
          'Cintas adhesivas, de embalaje, decorativas y washi tape en múltiples anchos y diseños para sellar y decorar.',
      imageUrl:
          'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=600',
      tags: ['Adhesivo', 'Decoración', 'Manualidades'],
    ),
    'Adornos en fomix': CategoryInfo(
      description:
          'Letras, flores, figuras y plantillas de foamy para decorar cuadernos, carteles y trabajos escolares con creatividad.',
      imageUrl:
          'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=600',
      tags: ['Manualidades', 'Decoración', 'Arte'],
    ),
    'Pintura acrílica': CategoryInfo(
      description:
          'Pinturas acrílicas de alta pigmentación en tubos y frascos. Secado rápido, resistentes al agua y perfectas para lienzo y madera.',
      imageUrl:
          'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600',
      tags: ['Arte', 'Pintura', 'Profesional'],
    ),
    'Slime': CategoryInfo(
      description:
          'Slimes de colores, brillantinas y texturas distintas. La actividad sensorial y creativa favorita de los niños.',
      imageUrl:
          'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=600',
      tags: ['Niños', 'Juego', 'Sensorial'],
    ),
    'Paletas de colores': CategoryInfo(
      description:
          'Paletas de sombras, acuarelas y colores para maquillaje y arte. Desde tonos pastel hasta pigmentos ultra vibrantes.',
      imageUrl:
          'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600',
      tags: ['Arte', 'Color', 'Maquillaje'],
    ),
    'Calculadoras': CategoryInfo(
      description:
          'Calculadoras básicas y científicas para uso escolar y universitario. Pantalla grande y funciones avanzadas.',
      imageUrl:
          'https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=600',
      tags: ['Escolar', 'Matemáticas', 'Tecnología'],
    ),
    'Estilete': CategoryInfo(
      description:
          'Estiletes metálicos y de plástico con hoja retráctil para cortes precisos en papel, cartón y más materiales.',
      imageUrl:
          'https://images.unsplash.com/photo-1581093452543-c2f14a2fb9f9?w=600',
      tags: ['Herramienta', 'Corte', 'Manualidades'],
    ),
    'Perforadora': CategoryInfo(
      description:
          'Perforadoras de 2 y 4 agujeros para archivar documentos con facilidad. Capacidad para hasta 20 hojas por perforación.',
      imageUrl:
          'https://images.unsplash.com/photo-1588702547919-26089e690ecc?w=600',
      tags: ['Oficina', 'Organización', 'Archivo'],
    ),
    'Tape dispenser': CategoryInfo(
      description:
          'Dispensadores de cinta adhesiva de escritorio. Corte fácil y preciso con base antideslizante para uso diario.',
      imageUrl:
          'https://images.unsplash.com/photo-1588702547919-26089e690ecc?w=600',
      tags: ['Oficina', 'Adhesivo', 'Escritorio'],
    ),
    'Grapadora': CategoryInfo(
      description:
          'Grapadoras de escritorio para 20-50 hojas con repuesto de grapas incluido. Compactas y de uso intensivo.',
      imageUrl:
          'https://images.unsplash.com/photo-1588702547919-26089e690ecc?w=600',
      tags: ['Oficina', 'Archivo', 'Herramienta'],
    ),
    'Pilas': CategoryInfo(
      description:
          'Pilas alcalinas AA, AAA, C, D y de 9V de larga duración para controles remotos, juguetes y dispositivos electrónicos.',
      imageUrl:
          'https://images.unsplash.com/photo-1610282456014-7b24988c5e43?w=600',
      tags: ['Electricidad', 'Electrónica', 'Hogar'],
    ),
    'Papel higiénico': CategoryInfo(
      description:
          'Papel higiénico triple hoja de alta suavidad y absorción. Paquetes individuales y de gran cantidad para hogar y oficina.',
      imageUrl:
          'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?w=600',
      tags: ['Higiene', 'Hogar', 'Esencial'],
    ),
    'Peinillas': CategoryInfo(
      description:
          'Peinillas y peines de diferentes tamaños y dientes para todo tipo de cabello. Antiestáticas y de alta durabilidad.',
      imageUrl:
          'https://images.unsplash.com/photo-1522338140262-f46f5913618a?w=600',
      tags: ['Cabello', 'Higiene', 'Cuidado'],
    ),
  };

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
