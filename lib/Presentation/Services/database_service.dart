import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'backup_service.dart';
import 'database_location_service.dart';

/// Genera un ID de 20 caracteres aleatorios estilo Firebase (letras y números).
String generateFirebaseId() {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random.secure();
  return List.generate(20, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Servicio principal para manejar la conexión con SQLite.
/// Mantiene un único sistema con múltiples locales compartiendo la misma base.
class DatabaseService {
  static Database? _database;

  static const List<String> _storeNames = ['Bazar', 'Tienda'];

  static const Map<String, List<String>> _catalogByStore = {
    'Bazar': [
      'Peluches',
      'Carteras',
      'Juguetes',
      'Portarretratos',
      'Accesorios de cocina',
      'Lámparas dormitorio',
      'Fundas de regalo',
      'Pelotas de fútbol',
      'Pelotas de indor',
      'Zapatos deportivos',
      'Zapatillas',
      'Mochilas',
      'Loncheras',
      'Plateros y accesorios para platos',
      'Accesorios para fiestas y cumpleaños',
      'Lazos',
      'Vinchas',
      'Joyería',
      'Perfumes',
      'Esmaltes y labiales',
      'Accesorios navideños',
      'Audífonos',
      'Auricular Bluetooth',
      'Billeteras para hombre y mujer',
      'Velas aromáticas',
      'Cajas para obsequios',
      'Espejos',
    ],
    'Tienda': [
      'Cuadernos',
      'Hojas A4',
      'Papel crepé',
      'Fomix',
      'Hojas papel bond',
      'Cartón prensado',
      'Espuma flex',
      'Agendas',
      'Diccionario',
      'Pinturas',
      'Lápices de colores',
      'Resaltadores',
      'Acuarelas',
      'Sacapuntas',
      'Corrector',
      'Goma',
      'Silicona',
      'Lápiz',
      'Esferos',
      'Marcador doble punta',
      'Lapicero borrable',
      'Esferos azul',
      'Borrador',
      'Marcador permanente y borrable',
      'Lana',
      'Hilo ratón',
      'Cintas',
      'Adornos tipo lentejuelas',
      'Reglas',
      'Tijera',
      'Pilas',
      'Adornos en fomix recortados',
      'Pintura acrílica Artesco',
      'Slime',
      'Paletas de colores',
      'Calculadora',
      'Estilete',
      'Prestobarba',
      'Brujita',
      'Peinillas',
      'Descorchador vinos',
      'Cepillo de dientes',
      'Uñas postizas',
      'Rizador',
      'Pestañas postizas',
      'Pegamento de uñas y cejas',
      'Moños',
      'Ampollas para el pelo',
      'Llaveros',
      'Invisibles',
      'Fosforeras',
      'Corta uñas',
      'Limas',
      'Pinza para cejas',
      'Brochas para maquillaje',
      'Tiras de sostén',
      'Cherry para zapatos saca brillo',
      'Desodorantes en aerosol',
      'Fijación e hidratación para pelo',
      'Teta para recién nacido',
      'Banderola para sacar brillo zapatos',
      'Talco de pies',
      'Limpiador facial',
      'Tinte de cabello',
      'Crema oxigenada',
      'Gel',
      'Esponja para sacar brillo zapatos',
      'Desinfectante ambiental',
      'Casino',
      'Alcancías',
      'Aceite limpiador de madera',
      'Desodorante en barra',
      'Desodorante en crema',
      'Aceite Johnson',
      'Repelente',
      'Listerine',
      'Protector solar',
      'Crema hidratante corporal',
      'Cirio vela',
      'Difusor de esencia',
      'Fósforos',
      'Jaboncillo',
      'Jabón',
      'Pasta dental niño y adulto',
      'Suavizante para ropa',
      'Gillette',
      'Pañitos húmedos',
      'Shampoo',
      'Papel aluminio',
      'Toallas higiénicas',
      'Esencias para carro',
      'Silicón en spray para cabello',
      'Leche',
      'Cinta transparente y de todo tipo',
      'Detergente',
      'Guantes',
      'Cloro',
      'Ambiental tips',
      'Enlatados',
      'Sardina',
      'Atún real',
      'Tallarines',
      'Fideos',
      'Panela',
      'Lavavajilla',
      'Focos',
      'Pañales',
      'Café',
      'Harina',
      'Azúcar',
      'Sal',
      'Avena',
      'Aceite',
      'Manteca',
      'Perforadora',
      'Tape dispenser',
      'Grapadora',
      'Insecticidas',
      'Aliños de todo tipo',
      'Condimentos',
      'Esencias',
      'Salsas',
      'Cocos',
      'Mantequilla',
      'Productos lácteos',
      'Jugos o néctares',
      'Café en polvo',
      'Leche condensada',
      'Enlatados tipo verduras',
      'Frutas',
      'Frutos secos',
      'Leches saborizadas',
      'Cremas de peinar',
      'Papel higiénico',
      'Galletas Amor',
      'Bombones',
      'Gelatina',
      'Horchata en sobre',
      'Tés en cartón por sobres',
      'Frescosolo',
      'Polvo de hornear',
      'Mezcla de polvo chantilly',
      'Platos desechables',
      'Servilletas',
      'Velas',
      'Carpetas',
      'Fundas',
      'Esponjas',
    ],
  };

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = await DatabaseLocationService.getDatabasePath();

    try {
      await DatabaseLocationService.ensureDatabaseDirectoryExists(path);
    } catch (_) {
      path = await DatabaseLocationService.getFallbackPath();
      await DatabaseLocationService.ensureDatabaseDirectoryExists(path);
    }

    if (!await DatabaseLocationService.databaseExists(path)) {
      try {
        final data = await rootBundle.load('assets/database/bazarnicole.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception('No se pudo copiar la base de datos desde assets: $e');
      }
    }

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async => _ensureBusinessSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async =>
          _ensureBusinessSchema(db),
      onOpen: (db) async => _ensureBusinessSchema(db),
    );

    await _ensureBusinessSchema(db);
    _performAutomaticBackupIfNeeded();
    return db;
  }

  static Future<void> _ensureBusinessSchema(DatabaseExecutor db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        category_id INTEGER,
        price REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        UNIQUE(product_id, store_id),
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        supplier_id INTEGER,
        total REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        cost REAL NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        client_id INTEGER,
        date TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        FOREIGN KEY (client_id) REFERENCES clients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        from_store_id INTEGER NOT NULL,
        to_store_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (from_store_id) REFERENCES stores(id),
        FOREIGN KEY (to_store_id) REFERENCES stores(id)
      )
    ''');

    // --- Módulo de Caja ---

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_cash INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        opening_amount REAL NOT NULL DEFAULT 0,
        closing_amount REAL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        status TEXT NOT NULL DEFAULT 'open',
        FOREIGN KEY (store_id) REFERENCES stores(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL DEFAULT 'Efectivo',
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES cash_sessions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        method_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (method_id) REFERENCES payment_methods(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL UNIQUE,
        total REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (sale_id) REFERENCES sales(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        credit_sale_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        method_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (credit_sale_id) REFERENCES credit_sales(id),
        FOREIGN KEY (method_id) REFERENCES payment_methods(id)
      )
    ''');

    // --- Módulo de Usuarios y Roles ---
    // Si la tabla users existe pero es la del dump de Firebase (tiene columna _key),
    // la renombramos a firebase_users para no entrar en conflicto.
    try {
      final cols = await db.rawQuery("PRAGMA table_info(users)");
      if (cols.isNotEmpty) {
        final hasKey = cols.any((c) => c['name'] == '_key');
        if (hasKey) {
          await db.execute('ALTER TABLE users RENAME TO firebase_users');
        }
      }
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        lastname TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cajero',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await _seedAdminUser(db);
    await _seedPaymentMethods(db);

    await _ensureColumn(
      db,
      table: 'products',
      column: 'price',
      definition: 'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      table: 'sales',
      column: 'client_id',
      definition: 'INTEGER',
    );
    await _ensureColumn(
      db,
      table: 'suppliers',
      column: 'email',
      definition: 'TEXT',
    );
    await _ensureColumn(
      db,
      table: 'suppliers',
      column: 'notes',
      definition: 'TEXT',
    );

    // Migración de la tabla users (por si existía antes con menos columnas)
    await _ensureColumn(
      db,
      table: 'users',
      column: 'uid',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'email',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'password',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'name',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'lastname',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'role',
      definition: "TEXT NOT NULL DEFAULT 'cajero'",
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'is_active',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _ensureColumn(
      db,
      table: 'users',
      column: 'created_at',
      definition: "TEXT NOT NULL DEFAULT ''",
    );

    // Migración: quién abre la caja
    await _ensureColumn(
      db,
      table: 'cash_sessions',
      column: 'opened_by',
      definition: 'INTEGER',
    );
    await _ensureColumn(
      db,
      table: 'cash_sessions',
      column: 'opened_by_name',
      definition: "TEXT NOT NULL DEFAULT ''",
    );

    // Migración: tabla de desglose de denominaciones al abrir/cerrar caja
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_denominations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        value REAL NOT NULL,
        label TEXT NOT NULL,
        is_coin INTEGER NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL DEFAULT 0,
        moment TEXT NOT NULL DEFAULT 'open',
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES cash_sessions(id) ON DELETE CASCADE
      )
    ''');

    await _seedStores(db);
    await _seedCatalog(db);
  }

  static Future<void> _seedAdminUser(DatabaseExecutor db) async {
    // Crear usuario administrador por defecto si no existen usuarios
    final count = await db.rawQuery('SELECT COUNT(*) as c FROM users');
    final total = (count.first['c'] as num).toInt();
    if (total == 0) {
      final uid = generateFirebaseId();
      await db.rawInsert(
        '''INSERT OR IGNORE INTO users (uid, email, password, name, lastname, role, is_active, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [uid, 'admin@bazarnicole.com', 'admin123', 'Administrador', '', 'admin', 1, DateTime.now().toIso8601String()],
      );
    }
  }

  static Future<void> _seedPaymentMethods(DatabaseExecutor db) async {
    const methods = [
      {'name': 'Efectivo', 'is_cash': 1},
      {'name': 'Transferencia', 'is_cash': 0},
      {'name': 'Depósito', 'is_cash': 0},
      {'name': 'PayPal', 'is_cash': 0},
      {'name': 'Tarjeta débito', 'is_cash': 0},
      {'name': 'Crédito', 'is_cash': 0},
    ];
    for (final m in methods) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO payment_methods (name, is_cash) VALUES (?, ?)',
        [m['name'], m['is_cash']],
      );
    }
  }

  static Future<void> _seedStores(DatabaseExecutor db) async {
    for (final storeName in _storeNames) {
      await db.rawInsert('INSERT OR IGNORE INTO stores (name) VALUES (?)', [
        storeName,
      ]);
    }
  }

  static Future<void> _seedCatalog(DatabaseExecutor db) async {
    await _ensureCategory(db, 'Sin categoría');

    final stores = await db.rawQuery('SELECT id, name FROM stores ORDER BY id');
    final storeIds = <String, int>{
      for (final row in stores)
        row['name'] as String: (row['id'] as num).toInt(),
    };

    if (storeIds.isEmpty) return;

    for (final entry in _catalogByStore.entries) {
      final categoryId = await _ensureCategory(db, entry.key);

      for (final rawName in entry.value) {
        final productName = _cleanName(rawName);
        final existing = await db.rawQuery(
          'SELECT id FROM products WHERE lower(name) = ?',
          [productName.toLowerCase()],
        );

        int productId;
        if (existing.isNotEmpty) {
          productId = (existing.first['id'] as num).toInt();
        } else {
          final uniqueSku = await _uniqueSku(db, _buildSku(productName));
          productId = await db.rawInsert(
            'INSERT INTO products (name, sku, category_id, created_at) VALUES (?, ?, ?, ?)',
            [
              productName,
              uniqueSku,
              categoryId,
              DateTime.now().toIso8601String(),
            ],
          );
        }

        for (final storeId in storeIds.values) {
          await db.rawInsert(
            'INSERT OR IGNORE INTO inventory (product_id, store_id, stock) VALUES (?, ?, 0)',
            [productId, storeId],
          );
        }
      }
    }
  }

  static Future<void> _ensureColumn(
    DatabaseExecutor db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static Future<int> _ensureCategory(
    DatabaseExecutor db,
    String? categoryName,
  ) async {
    final name = _cleanName(
      categoryName?.isNotEmpty == true ? categoryName! : 'Sin categoría',
    );

    await db.rawInsert('INSERT OR IGNORE INTO categories (name) VALUES (?)', [
      name,
    ]);

    final rows = await db.rawQuery(
      'SELECT id FROM categories WHERE name = ? LIMIT 1',
      [name],
    );

    return (rows.first['id'] as num).toInt();
  }

  static Future<int?> _ensureSupplier(
    DatabaseExecutor db,
    String? supplierName, {
    String? phone,
  }) async {
    final name = _cleanName(supplierName ?? '');
    if (name.isEmpty) return null;

    final cleanPhone = phone?.trim();

    await db.rawInsert(
      'INSERT OR IGNORE INTO suppliers (name, phone) VALUES (?, ?)',
      [name, cleanPhone?.isEmpty == true ? null : cleanPhone],
    );

    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      await db.rawUpdate(
        'UPDATE suppliers SET phone = ? WHERE lower(name) = ?',
        [cleanPhone, name.toLowerCase()],
      );
    }

    final rows = await db.rawQuery(
      'SELECT id FROM suppliers WHERE lower(name) = ? LIMIT 1',
      [name.toLowerCase()],
    );

    return rows.isEmpty ? null : (rows.first['id'] as num).toInt();
  }

  static Future<String> _uniqueSku(DatabaseExecutor db, String baseSku) async {
    final cleanBase = _buildSku(baseSku);
    var candidate = cleanBase;
    var suffix = 1;

    while (true) {
      final rows = await db.rawQuery(
        'SELECT id FROM products WHERE upper(sku) = upper(?) LIMIT 1',
        [candidate],
      );

      if (rows.isEmpty) return candidate;

      candidate = '$cleanBase-$suffix';
      suffix++;
    }
  }

  static String _buildSku(String name) {
    final normalized = name
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    if (normalized.isEmpty) return 'ITEM';
    return normalized.substring(0, min(normalized.length, 32));
  }

  static String _cleanName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static void _performAutomaticBackupIfNeeded() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await BackupService.performAutomaticBackupIfNeeded();
      } catch (_) {}
    });
  }

  static Future<List<Map<String, dynamic>>> getStores() async {
    final db = await database;
    return db.rawQuery('SELECT id, name FROM stores ORDER BY id');
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.rawQuery('SELECT id, name FROM categories ORDER BY name');
  }

  static Future<List<Map<String, dynamic>>> getProducts({
    String search = '',
  }) async {
    final db = await database;
    final filter = '%${search.trim()}%';

    return db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.sku,
        p.price,
        COALESCE(c.name, 'Sin categoría') AS category,
        COALESCE(SUM(i.stock), 0) AS total_stock,
        COALESCE(MAX(CASE WHEN s.name = 'Bazar' THEN i.stock END), 0) AS stock_bazar,
        COALESCE(MAX(CASE WHEN s.name = 'Tienda' THEN i.stock END), 0) AS stock_tienda
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      LEFT JOIN inventory i ON i.product_id = p.id
      LEFT JOIN stores s ON s.id = i.store_id
      WHERE p.name LIKE ? OR p.sku LIKE ? OR COALESCE(c.name, '') LIKE ?
      GROUP BY p.id, p.name, p.sku, p.price, c.name
      ORDER BY p.name COLLATE NOCASE
      ''',
      [filter, filter, filter],
    );
  }

  static Future<List<Map<String, dynamic>>> getInventoryByStore(
    int storeId, {
    String search = '',
  }) async {
    final db = await database;
    final filter = '%${search.trim()}%';

    return db.rawQuery(
      '''
      SELECT
        p.id AS product_id,
        p.name,
        p.sku,
        p.price,
        COALESCE(c.name, 'Sin categoría') AS category,
        COALESCE(i.stock, 0) AS stock
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      LEFT JOIN inventory i ON i.product_id = p.id AND i.store_id = ?
      WHERE p.name LIKE ? OR p.sku LIKE ? OR COALESCE(c.name, '') LIKE ?
      ORDER BY p.name COLLATE NOCASE
      ''',
      [storeId, filter, filter, filter],
    );
  }

  static Future<void> createProduct({
    required String name,
    double price = 0,
    String? sku,
    String? categoryName,
    Map<int, int> initialStock = const {},
  }) async {
    final cleanName = _cleanName(name);
    if (cleanName.isEmpty) {
      throw Exception('El nombre del producto es obligatorio');
    }

    await transaction((txn) async {
      final existing = await txn.rawQuery(
        'SELECT id FROM products WHERE lower(name) = ?',
        [cleanName.toLowerCase()],
      );

      if (existing.isNotEmpty) {
        throw Exception(
          'El producto ya existe. Usa el inventario por local para ajustar stock.',
        );
      }

      final categoryId = await _ensureCategory(txn, categoryName);
      final uniqueSku = await _uniqueSku(
        txn,
        (sku?.trim().isNotEmpty ?? false) ? sku!.trim() : _buildSku(cleanName),
      );

      final productId = await txn.rawInsert(
        'INSERT INTO products (name, sku, category_id, price, created_at) VALUES (?, ?, ?, ?, ?)',
        [
          cleanName,
          uniqueSku,
          categoryId,
          price < 0 ? 0 : price,
          DateTime.now().toIso8601String(),
        ],
      );

      final storeRows = await txn.rawQuery('SELECT id FROM stores ORDER BY id');
      for (final store in storeRows) {
        final storeId = (store['id'] as num).toInt();
        await txn.rawInsert(
          'INSERT OR IGNORE INTO inventory (product_id, store_id, stock) VALUES (?, ?, ?)',
          [productId, storeId, max(0, initialStock[storeId] ?? 0)],
        );
      }
    });
  }

  static Future<void> updateInventoryStock({
    required int productId,
    required int storeId,
    required int stock,
  }) async {
    final db = await database;
    final safeStock = max(0, stock);

    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO inventory (product_id, store_id, stock) VALUES (?, ?, 0)',
        [productId, storeId],
      );

      await txn.rawUpdate(
        'UPDATE inventory SET stock = ? WHERE product_id = ? AND store_id = ?',
        [safeStock, productId, storeId],
      );
    });
  }

  static Future<void> transferInventory({
    required int productId,
    required int fromStoreId,
    required int toStoreId,
    required int quantity,
  }) async {
    if (fromStoreId == toStoreId) {
      throw Exception('Selecciona dos locales distintos');
    }

    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor que cero');
    }

    await transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO inventory (product_id, store_id, stock) VALUES (?, ?, 0)',
        [productId, fromStoreId],
      );
      await txn.rawInsert(
        'INSERT OR IGNORE INTO inventory (product_id, store_id, stock) VALUES (?, ?, 0)',
        [productId, toStoreId],
      );

      final sourceRows = await txn.rawQuery(
        'SELECT stock FROM inventory WHERE product_id = ? AND store_id = ? LIMIT 1',
        [productId, fromStoreId],
      );

      final available = sourceRows.isEmpty
          ? 0
          : (sourceRows.first['stock'] as num).toInt();

      if (available < quantity) {
        throw Exception('No hay stock suficiente en el local origen');
      }

      await txn.rawUpdate(
        'UPDATE inventory SET stock = stock - ? WHERE product_id = ? AND store_id = ?',
        [quantity, productId, fromStoreId],
      );

      await txn.rawUpdate(
        'UPDATE inventory SET stock = stock + ? WHERE product_id = ? AND store_id = ?',
        [quantity, productId, toStoreId],
      );

      await txn.rawInsert(
        'INSERT INTO inventory_movements (product_id, from_store_id, to_store_id, quantity, date) VALUES (?, ?, ?, ?, ?)',
        [
          productId,
          fromStoreId,
          toStoreId,
          quantity,
          DateTime.now().toIso8601String(),
        ],
      );
    });
  }

  static Future<int> registerSale({
    required int storeId,
    required List<Map<String, dynamic>> items,
    int? clientId,
  }) async {
    if (items.isEmpty) {
      throw Exception('La venta debe contener al menos un producto');
    }

    return transaction((txn) async {
      double total = 0;

      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toInt();
        final price = (item['price'] as num).toDouble();

        if (quantity <= 0) {
          throw Exception('La cantidad de venta debe ser mayor que cero');
        }

        final stockRows = await txn.rawQuery(
          'SELECT stock FROM inventory WHERE product_id = ? AND store_id = ? LIMIT 1',
          [productId, storeId],
        );

        final available = stockRows.isEmpty
            ? 0
            : (stockRows.first['stock'] as num).toInt();

        if (available < quantity) {
          throw Exception('Stock insuficiente para completar la venta');
        }

        total += quantity * price;
      }

      final saleId = await txn.rawInsert(
        'INSERT INTO sales (store_id, client_id, date, total) VALUES (?, ?, ?, ?)',
        [storeId, clientId, DateTime.now().toIso8601String(), total],
      );

      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toInt();
        final price = (item['price'] as num).toDouble();

        await txn.rawInsert(
          'INSERT INTO sale_items (sale_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
          [saleId, productId, quantity, price],
        );

        await txn.rawUpdate(
          'UPDATE inventory SET stock = stock - ? WHERE product_id = ? AND store_id = ?',
          [quantity, productId, storeId],
        );
      }

      return saleId;
    });
  }

  static Future<void> updateProduct({
    required int productId,
    required String name,
    required String categoryName,
    required String sku,
    required double price,
  }) async {
    final cleanName = _cleanName(name);
    if (cleanName.isEmpty) {
      throw Exception('El nombre del producto es obligatorio');
    }

    await transaction((txn) async {
      final repeated = await txn.rawQuery(
        'SELECT id FROM products WHERE lower(name) = ? AND id != ?',
        [cleanName.toLowerCase(), productId],
      );

      if (repeated.isNotEmpty) {
        throw Exception('Ya existe otro producto con ese nombre');
      }

      final categoryId = await _ensureCategory(txn, categoryName);
      await txn.rawUpdate(
        'UPDATE products SET name = ?, sku = ?, category_id = ?, price = ? WHERE id = ?',
        [
          cleanName,
          sku.trim().isEmpty ? _buildSku(cleanName) : sku.trim(),
          categoryId,
          price < 0 ? 0 : price,
          productId,
        ],
      );
    });
  }

  static Future<List<Map<String, dynamic>>> getCustomers({
    String search = '',
  }) async {
    final db = await database;
    final filter = '%${search.trim()}%';

    return db.rawQuery(
      '''
      SELECT id, name, phone, email, notes, created_at
      FROM clients
      WHERE name LIKE ? OR COALESCE(phone, '') LIKE ? OR COALESCE(email, '') LIKE ?
      ORDER BY name COLLATE NOCASE
      ''',
      [filter, filter, filter],
    );
  }

  static Future<void> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final cleanName = _cleanName(name);
    if (cleanName.isEmpty) {
      throw Exception('El nombre del cliente es obligatorio');
    }

    final db = await database;
    await db.rawInsert(
      'INSERT INTO clients (name, phone, email, notes, created_at) VALUES (?, ?, ?, ?, ?)',
      [
        cleanName,
        phone?.trim(),
        email?.trim(),
        notes?.trim(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  static Future<List<Map<String, dynamic>>> getCustomerHistory(
    int customerId,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT sa.id, sa.date, sa.total, st.name AS store_name
      FROM sales sa
      LEFT JOIN stores st ON st.id = sa.store_id
      WHERE sa.client_id = ?
      ORDER BY sa.date DESC
      ''',
      [customerId],
    );
  }

  static Future<List<Map<String, dynamic>>> getSuppliers({
    String search = '',
  }) async {
    final db = await database;
    final filter = '%${search.trim()}%';

    return db.rawQuery(
      '''
      SELECT id, name, phone
      FROM suppliers
      WHERE name LIKE ? OR COALESCE(phone, '') LIKE ?
      ORDER BY name COLLATE NOCASE
      ''',
      [filter, filter],
    );
  }

  static Future<int> registerPurchase({
    required int storeId,
    required List<Map<String, dynamic>> items,
    String? supplierName,
    String? supplierPhone,
  }) async {
    if (items.isEmpty) {
      throw Exception('La compra debe contener al menos un producto');
    }

    return transaction((txn) async {
      double total = 0;

      for (final item in items) {
        final quantity = (item['quantity'] as num).toInt();
        final cost = (item['cost'] as num).toDouble();

        if (quantity <= 0) {
          throw Exception('La cantidad de compra debe ser mayor que cero');
        }

        if (cost < 0) {
          throw Exception('El costo no puede ser negativo');
        }

        total += quantity * cost;
      }

      final supplierId = await _ensureSupplier(
        txn,
        supplierName,
        phone: supplierPhone,
      );

      final purchaseId = await txn.rawInsert(
        'INSERT INTO purchases (store_id, supplier_id, total, date) VALUES (?, ?, ?, ?)',
        [storeId, supplierId, total, DateTime.now().toIso8601String()],
      );

      for (final item in items) {
        final productId = (item['product_id'] as num).toInt();
        final quantity = (item['quantity'] as num).toInt();
        final cost = (item['cost'] as num).toDouble();

        await txn.rawInsert(
          'INSERT OR IGNORE INTO inventory (product_id, store_id, stock) VALUES (?, ?, 0)',
          [productId, storeId],
        );

        await txn.rawInsert(
          'INSERT INTO purchase_items (purchase_id, product_id, quantity, cost) VALUES (?, ?, ?, ?)',
          [purchaseId, productId, quantity, cost],
        );

        await txn.rawUpdate(
          'UPDATE inventory SET stock = stock + ? WHERE product_id = ? AND store_id = ?',
          [quantity, productId, storeId],
        );
      }

      return purchaseId;
    });
  }

  static Future<List<Map<String, dynamic>>> getSalesHistory({
    int? storeId,
    int? customerId,
    DateTime? date,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (storeId != null) {
      conditions.add('sa.store_id = ?');
      args.add(storeId);
    }
    if (customerId != null) {
      conditions.add('sa.client_id = ?');
      args.add(customerId);
    }
    if (date != null) {
      conditions.add('sa.date LIKE ?');
      args.add('${date.toIso8601String().split('T').first}%');
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT sa.id, sa.date, sa.total,
             st.name AS store_name,
             COALESCE(c.name, 'Consumidor final') AS client_name
      FROM sales sa
      INNER JOIN stores st ON st.id = sa.store_id
      LEFT JOIN clients c ON c.id = sa.client_id
      $whereClause
      ORDER BY sa.date DESC, sa.id DESC
      ''', args);
  }

  static Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT si.id, p.name AS product_name, si.quantity, si.price
      FROM sale_items si
      INNER JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
      ORDER BY si.id ASC
      ''',
      [saleId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPurchaseHistory({
    int? storeId,
    int? supplierId,
    DateTime? date,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (storeId != null) {
      conditions.add('pu.store_id = ?');
      args.add(storeId);
    }
    if (supplierId != null) {
      conditions.add('pu.supplier_id = ?');
      args.add(supplierId);
    }
    if (date != null) {
      conditions.add('pu.date LIKE ?');
      args.add('${date.toIso8601String().split('T').first}%');
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT pu.id, pu.date, pu.total,
             st.name AS store_name,
             COALESCE(sp.name, 'Sin proveedor') AS supplier_name
      FROM purchases pu
      INNER JOIN stores st ON st.id = pu.store_id
      LEFT JOIN suppliers sp ON sp.id = pu.supplier_id
      $whereClause
      ORDER BY pu.date DESC, pu.id DESC
      ''', args);
  }

  static Future<List<Map<String, dynamic>>> getPurchaseItems(
    int purchaseId,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT pi.id, p.name AS product_name, pi.quantity, pi.cost
      FROM purchase_items pi
      INNER JOIN products p ON p.id = pi.product_id
      WHERE pi.purchase_id = ?
      ORDER BY pi.id ASC
      ''',
      [purchaseId],
    );
  }

  static Future<Map<String, dynamic>> getReportsSnapshot() async {
    final db = await database;
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    final salesToday = await db.rawQuery(
      'SELECT COUNT(*) AS sales_count, COALESCE(SUM(total), 0) AS total FROM sales WHERE date >= ?',
      [dayStart],
    );

    final salesByStore = await db.rawQuery('''
      SELECT st.name, COUNT(sa.id) AS sales_count, COALESCE(SUM(sa.total), 0) AS total
      FROM stores st
      LEFT JOIN sales sa ON sa.store_id = st.id
      GROUP BY st.id, st.name
      ORDER BY total DESC, st.name ASC
    ''');

    final topProducts = await db.rawQuery('''
      SELECT p.name, COALESCE(SUM(si.quantity), 0) AS units, COALESCE(SUM(si.quantity * si.price), 0) AS revenue
      FROM sale_items si
      INNER JOIN products p ON p.id = si.product_id
      GROUP BY p.id, p.name
      ORDER BY units DESC, revenue DESC
      LIMIT 10
    ''');

    return {
      'salesToday': salesToday.isNotEmpty
          ? salesToday.first
          : {'sales_count': 0, 'total': 0},
      'salesByStore': salesByStore,
      'topProducts': topProducts,
    };
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  static Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return db.rawInsert(sql, arguments);
  }

  static Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return db.rawUpdate(sql, arguments);
  }

  static Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return db.rawDelete(sql, arguments);
  }

  static Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }

  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final path = await DatabaseLocationService.getDatabasePath();
      final exists = await DatabaseLocationService.databaseExists(path);
      final size = exists
          ? await DatabaseLocationService.getDatabaseSize(path)
          : 0.0;

      return {
        'path': path,
        'exists': exists,
        'sizeMB': size,
        'systemInfo': DatabaseLocationService.getSystemInfo(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'path': 'Error obteniendo ruta',
        'exists': false,
        'sizeMB': 0.0,
      };
    }
  }

  static Future<bool> createManualBackup({String? customName}) async {
    try {
      return await BackupService.createBackup(customName: customName);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> restoreFromBackup(String backupName) async {
    try {
      await closeDatabase();
      final result = await BackupService.restoreFromBackup(backupName);
      if (result) {
        _database = await _initDatabase();
      }
      return result;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // MÉTODOS DE PAGO
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final db = await database;
    return db.rawQuery(
      'SELECT id, name, is_cash FROM payment_methods ORDER BY id',
    );
  }

  // ─────────────────────────────────────────────
  // SESIONES DE CAJA (APERTURA / CIERRE)
  // ─────────────────────────────────────────────

  /// Retorna la sesión activa para el local, o null si está cerrada.
  static Future<Map<String, dynamic>?> getActiveCashSession(int storeId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT cs.id, cs.store_id, cs.opening_amount, cs.opened_at, cs.status,
             cs.opened_by, cs.opened_by_name,
             st.name AS store_name
      FROM cash_sessions cs
      JOIN stores st ON st.id = cs.store_id
      WHERE cs.store_id = ? AND cs.status = 'open'
      ORDER BY cs.id DESC
      LIMIT 1
      ''',
      [storeId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Abre una nueva sesión de caja.
  static Future<int> openCashSession({
    required int storeId,
    required double openingAmount,
    int? openedBy,
    String openedByName = '',
  }) async {
    return transaction((txn) async {
      final existing = await txn.rawQuery(
        "SELECT id FROM cash_sessions WHERE store_id = ? AND status = 'open' LIMIT 1",
        [storeId],
      );
      if (existing.isNotEmpty) {
        throw Exception('Ya hay una caja abierta para este local');
      }

      final sessionId = await txn.rawInsert(
        '''INSERT INTO cash_sessions (store_id, opening_amount, opened_at, status, opened_by, opened_by_name)
           VALUES (?, ?, ?, 'open', ?, ?)''',
        [storeId, openingAmount, DateTime.now().toIso8601String(), openedBy, openedByName],
      );

      // Registrar apertura como movimiento de ingreso
      await txn.rawInsert(
        '''INSERT INTO cash_movements (session_id, type, amount, method, description, created_at)
           VALUES (?, 'income', ?, 'Efectivo', 'Apertura de caja', ?)''',
        [sessionId, openingAmount, DateTime.now().toIso8601String()],
      );

      return sessionId;
    });
  }

  /// Cierra la sesión de caja activa.
  static Future<void> closeCashSession({
    required int sessionId,
    required double closingAmount,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final updated = await db.rawUpdate(
      '''UPDATE cash_sessions
         SET closing_amount = ?, closed_at = ?, status = 'closed'
         WHERE id = ? AND status = 'open' ''',
      [closingAmount, now, sessionId],
    );
    if (updated == 0) {
      throw Exception('No se encontró una sesión abierta con ese ID');
    }
  }

  // ─────────────────────────────────────────────
  // MOVIMIENTOS DE CAJA
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCashMovements(
    int sessionId,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''SELECT id, type, amount, method, description, created_at
         FROM cash_movements
         WHERE session_id = ?
         ORDER BY id ASC''',
      [sessionId],
    );
  }

  static Future<void> addCashMovement({
    required int sessionId,
    required String type, // 'income' | 'expense'
    required double amount,
    required String method,
    String? description,
  }) async {
    if (amount <= 0) throw Exception('El monto debe ser mayor que cero');
    if (type != 'income' && type != 'expense') {
      throw Exception('Tipo de movimiento inválido');
    }
    final db = await database;
    await db.rawInsert(
      '''INSERT INTO cash_movements (session_id, type, amount, method, description, created_at)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [
        sessionId,
        type,
        amount,
        method,
        description?.trim(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  /// Resumen financiero de la sesión: ingresos, egresos, saldo esperado.
  static Future<Map<String, dynamic>> getCashSessionSummary(
    int sessionId,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''SELECT
           COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
         FROM cash_movements
         WHERE session_id = ?''',
      [sessionId],
    );
    final row = rows.first;
    final totalIncome = (row['total_income'] as num).toDouble();
    final totalExpense = (row['total_expense'] as num).toDouble();

    // Desglose por método
    final byMethod = await db.rawQuery(
      '''SELECT method,
           COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
         FROM cash_movements
         WHERE session_id = ?
         GROUP BY method
         ORDER BY method''',
      [sessionId],
    );

    final balances = await db.rawQuery(
      '''SELECT
           COALESCE(SUM(
             CASE
               WHEN cm.type = 'income' AND COALESCE(pm.is_cash, 0) = 1 THEN cm.amount
               WHEN cm.type = 'expense' AND COALESCE(pm.is_cash, 0) = 1 THEN -cm.amount
               ELSE 0
             END
           ), 0) AS physical_cash,
           COALESCE(SUM(
             CASE
               WHEN cm.type = 'income' AND COALESCE(pm.is_cash, 0) = 0 THEN cm.amount
               WHEN cm.type = 'expense' AND COALESCE(pm.is_cash, 0) = 0 THEN -cm.amount
               ELSE 0
             END
           ), 0) AS virtual_balance
         FROM cash_movements cm
         LEFT JOIN payment_methods pm ON lower(pm.name) = lower(cm.method)
         WHERE cm.session_id = ?''',
      [sessionId],
    );

    final balanceRow = balances.first;

    return {
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'expected_balance': totalIncome - totalExpense,
      'physical_cash': (balanceRow['physical_cash'] as num).toDouble(),
      'virtual_balance': (balanceRow['virtual_balance'] as num).toDouble(),
      'by_method': byMethod,
    };
  }

  // ─────────────────────────────────────────────
  // DENOMINACIONES DE CAJA (billetes / monedas)
  // ─────────────────────────────────────────────

  /// Guarda el desglose de denominaciones para una sesión.
  /// [moment]: 'open' al abrir, 'close' al cerrar.
  static Future<void> saveCashDenominations({
    required int sessionId,
    required List<Map<String, dynamic>> entries, // toMap() de cada DenominationEntry
    required String moment,
  }) async {
    final db = await database;
    final batch = db.batch();
    // Elimina registros previos del mismo momento para evitar duplicados
    batch.delete(
      'cash_denominations',
      where: 'session_id = ? AND moment = ?',
      whereArgs: [sessionId, moment],
    );
    for (final e in entries) {
      if ((e['quantity'] as int) > 0) {
        batch.insert('cash_denominations', {
          'session_id': sessionId,
          'value': e['value'],
          'label': e['label'],
          'is_coin': e['is_coin'],
          'quantity': e['quantity'],
          'subtotal': e['subtotal'],
          'moment': moment,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
    await batch.commit(noResult: true);
  }

  /// Recupera el desglose de denominaciones de una sesión y momento.
  static Future<List<Map<String, dynamic>>> getCashDenominations({
    required int sessionId,
    required String moment,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''SELECT value, label, is_coin, quantity, subtotal
         FROM cash_denominations
         WHERE session_id = ? AND moment = ?
         ORDER BY is_coin ASC, value DESC''',
      [sessionId, moment],
    );
  }

  /// Suma total de billetes y monedas guardados para un momento.
  static Future<Map<String, double>> getCashDenominationTotals({
    required int sessionId,
    required String moment,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''SELECT
           COALESCE(SUM(CASE WHEN is_coin = 0 THEN subtotal ELSE 0 END), 0) AS total_bills,
           COALESCE(SUM(CASE WHEN is_coin = 1 THEN subtotal ELSE 0 END), 0) AS total_coins
         FROM cash_denominations
         WHERE session_id = ? AND moment = ?''',
      [sessionId, moment],
    );
    final row = rows.first;
    return {
      'total_bills': (row['total_bills'] as num).toDouble(),
      'total_coins': (row['total_coins'] as num).toDouble(),
    };
  }

  // ─────────────────────────────────────────────
  // HISTORIAL DE SESIONES DE CAJA
  // ─────────────────────────────────────────────

  /// Devuelve sesiones cerradas de un local.
  /// Filtros opcionales (se pasan como strings ya formateados):
  ///   [yearFilter]  → '2026'
  ///   [monthFilter] → '2026-04'
  ///   [weekFilter]  → '2026-15'  (año-semana ISO)
  static Future<List<Map<String, dynamic>>> getCashSessionHistory(
    int storeId, {
    String? yearFilter,
    String? monthFilter,
    String? weekFilter,
  }) async {
    final db = await database;
    String where = "cs.store_id = ? AND cs.status = 'closed'";
    final args = <dynamic>[storeId];

    if (weekFilter != null) {
      where += " AND strftime('%Y-%W', cs.opened_at) = ?";
      args.add(weekFilter);
    } else if (monthFilter != null) {
      where += " AND strftime('%Y-%m', cs.opened_at) = ?";
      args.add(monthFilter);
    } else if (yearFilter != null) {
      where += " AND strftime('%Y', cs.opened_at) = ?";
      args.add(yearFilter);
    }

    return db.rawQuery(
      '''
      SELECT cs.id, cs.opening_amount, cs.closing_amount,
             cs.opened_at, cs.closed_at,
             COALESCE(cs.opened_by_name, '') AS opened_by_name,
             st.name AS store_name,
             COALESCE(SUM(CASE WHEN cm.type = 'income' THEN cm.amount ELSE 0 END), 0) AS total_income,
             COALESCE(SUM(CASE WHEN cm.type = 'expense' THEN cm.amount ELSE 0 END), 0) AS total_expense
      FROM cash_sessions cs
      JOIN stores st ON st.id = cs.store_id
      LEFT JOIN cash_movements cm ON cm.session_id = cs.id
      WHERE $where
      GROUP BY cs.id
      ORDER BY cs.opened_at DESC
      ''',
      args,
    );
  }

  /// Devuelve los años distintos en que hubo sesiones cerradas para un local.
  static Future<List<String>> getCashSessionYears(int storeId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''SELECT DISTINCT strftime('%Y', opened_at) AS year
         FROM cash_sessions
         WHERE store_id = ? AND status = 'closed'
         ORDER BY year DESC''',
      [storeId],
    );
    return rows.map((r) => r['year'] as String).toList();
  }

  // ─────────────────────────────────────────────
  // VENTA CON MÚLTIPLES MÉTODOS DE PAGO
  // ─────────────────────────────────────────────

  /// Registra una venta y sus pagos. Si se proporciona [sessionId],
  /// también genera movimientos en caja por cada método de pago.
  static Future<int> registerSaleWithPayments({
    required int storeId,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
    // [{method_id: int, method_name: String, amount: double}]
    int? clientId,
    int? sessionId,
    bool isCredit = false,
  }) async {
    if (items.isEmpty) {
      throw Exception('La venta debe contener al menos un producto');
    }
    if (payments.isEmpty) {
      throw Exception('Debes indicar al menos un método de pago');
    }

    return transaction((txn) async {
      double total = 0;

      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toInt();
        final price = (item['price'] as num).toDouble();

        if (quantity <= 0) {
          throw Exception('La cantidad debe ser mayor que cero');
        }

        final stockRows = await txn.rawQuery(
          'SELECT stock FROM inventory WHERE product_id = ? AND store_id = ? LIMIT 1',
          [productId, storeId],
        );
        final available = stockRows.isEmpty
            ? 0
            : (stockRows.first['stock'] as num).toInt();
        if (available < quantity) {
          throw Exception('Stock insuficiente para completar la venta');
        }

        total += quantity * price;
      }

      final saleId = await txn.rawInsert(
        'INSERT INTO sales (store_id, client_id, date, total) VALUES (?, ?, ?, ?)',
        [storeId, clientId, DateTime.now().toIso8601String(), total],
      );

      // Guardar ítems y reducir stock
      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toInt();
        final price = (item['price'] as num).toDouble();

        await txn.rawInsert(
          'INSERT INTO sale_items (sale_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
          [saleId, productId, quantity, price],
        );
        await txn.rawUpdate(
          'UPDATE inventory SET stock = stock - ? WHERE product_id = ? AND store_id = ?',
          [quantity, productId, storeId],
        );
      }

      // Guardar métodos de pago
      for (final p in payments) {
        final methodId = (p['method_id'] as num).toInt();
        final amount = (p['amount'] as num).toDouble();
        await txn.rawInsert(
          'INSERT INTO sale_payments (sale_id, method_id, amount) VALUES (?, ?, ?)',
          [saleId, methodId, amount],
        );

        // Registrar ingreso en caja si hay sesión activa
        if (sessionId != null) {
          await txn.rawInsert(
            '''INSERT INTO cash_movements (session_id, type, amount, method, description, created_at)
               VALUES (?, 'income', ?, ?, ?, ?)''',
            [
              sessionId,
              amount,
              p['method_name'] ?? 'Efectivo',
              'Venta #$saleId',
              DateTime.now().toIso8601String(),
            ],
          );
        }
      }

      // Venta a crédito
      if (isCredit) {
        final paidNow = payments.fold<double>(
          0,
          (s, p) => s + (p['amount'] as num),
        );
        await txn.rawInsert(
          '''INSERT INTO credit_sales (sale_id, total, paid, status)
             VALUES (?, ?, ?, ?)''',
          [saleId, total, paidNow, paidNow >= total ? 'paid' : 'pending'],
        );
      }

      return saleId;
    });
  }

  // ─────────────────────────────────────────────
  // VENTAS A CRÉDITO / ABONOS
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCreditSalesPending() async {
    final db = await database;
    return db.rawQuery(
      '''SELECT cs.id, cs.sale_id, cs.total, cs.paid, cs.status,
                (cs.total - cs.paid) AS balance,
                sa.date, sa.store_id, c.name AS client_name,
                st.name AS store_name
         FROM credit_sales cs
         JOIN sales sa ON sa.id = cs.sale_id
         LEFT JOIN clients c ON c.id = sa.client_id
         JOIN stores st ON st.id = sa.store_id
         WHERE cs.status = 'pending'
         ORDER BY sa.date DESC''',
    );
  }

  static Future<void> addCreditPayment({
    required int creditSaleId,
    required double amount,
    required int methodId,
    int? sessionId,
    String? methodName,
  }) async {
    if (amount <= 0) throw Exception('El abono debe ser mayor que cero');
    await transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT total, paid FROM credit_sales WHERE id = ? LIMIT 1',
        [creditSaleId],
      );
      if (rows.isEmpty) throw Exception('Crédito no encontrado');

      final paid = (rows.first['paid'] as num).toDouble();
      final newPaid = paid + amount;

      await txn.rawInsert(
        '''INSERT INTO credit_payments (credit_sale_id, amount, method_id, date)
           VALUES (?, ?, ?, ?)''',
        [creditSaleId, amount, methodId, DateTime.now().toIso8601String()],
      );

      await txn.rawUpdate(
        '''UPDATE credit_sales SET paid = ?,
           status = CASE WHEN ? >= total THEN 'paid' ELSE 'pending' END
           WHERE id = ?''',
        [newPaid, newPaid, creditSaleId],
      );

      if (sessionId != null) {
        await txn.rawInsert(
          '''INSERT INTO cash_movements (session_id, type, amount, method, description, created_at)
             VALUES (?, 'income', ?, ?, 'Abono crédito', ?)''',
          [
            sessionId,
            amount,
            methodName ?? 'Efectivo',
            DateTime.now().toIso8601String(),
          ],
        );
      }
    });
  }

  // ─────────────────────────────────────────────
  // ANÁLISIS DE INVENTARIO (FASE 5)
  // ─────────────────────────────────────────────

  /// Obtiene unidades vendidas por producto en un período
  static Future<Map<int, int>> getUnitsSoldByProduct({
    required int storeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final db = await database;
      
      String whereClause = 'si.product_id IS NOT NULL AND s.store_id = ?';
      List<dynamic> whereArgs = [storeId];
      
      if (dateFrom != null) {
        whereClause += ' AND s.date >= ?';
        whereArgs.add(dateFrom.toIso8601String());
      }
      
      if (dateTo != null) {
        whereClause += ' AND s.date <= ?';
        whereArgs.add(dateTo.toIso8601String());
      }
      
      final result = await db.rawQuery('''
        SELECT 
          si.product_id,
          SUM(si.quantity) as totalSold
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE $whereClause
        GROUP BY si.product_id
      ''', whereArgs);
      
      final Map<int, int> unitsSold = {};
      for (var row in result) {
        final productId = (row['product_id'] as num).toInt();
        final quantity = (row['totalSold'] as num).toInt();
        unitsSold[productId] = quantity;
      }
      
      return unitsSold;
    } catch (e) {
      print('Error en getUnitsSoldByProduct: $e');
      return {};
    }
  }

  /// Obtiene TOP N productos más vendidos
  static Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required int storeId,
    int topCount = 5,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final db = await database;
      
      String whereClause = 's.store_id = ?';
      List<dynamic> whereArgs = [storeId];
      
      if (dateFrom != null) {
        whereClause += ' AND s.date >= ?';
        whereArgs.add(dateFrom.toIso8601String());
      }
      
      if (dateTo != null) {
        whereClause += ' AND s.date <= ?';
        whereArgs.add(dateTo.toIso8601String());
      }
      
      final result = await db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          p.sku,
          SUM(si.quantity) as totalSold,
          AVG(si.price) as avgPrice,
          COUNT(DISTINCT s.id) as saleTimes
        FROM sale_items si
        JOIN products p ON si.product_id = p.id
        JOIN sales s ON si.sale_id = s.id
        WHERE $whereClause
        GROUP BY p.id
        ORDER BY totalSold DESC
        LIMIT ?
      ''', [...whereArgs, topCount]);
      
      return result;
    } catch (e) {
      print('Error en getTopSellingProducts: $e');
      return [];
    }
  }

  /// Obtiene TOP N productos con mejor margen
  static Future<List<Map<String, dynamic>>> getTopMarginProducts({
    required int storeId,
    int topCount = 5,
  }) async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          p.sku,
          p.price as sellPrice,
          COALESCE((SELECT cost FROM purchase_items 
                    WHERE product_id = p.id 
                    LIMIT 1), 0) as costPrice,
          (p.price - COALESCE((SELECT cost FROM purchase_items 
                               WHERE product_id = p.id 
                               LIMIT 1), 0)) as marginPerUnit,
          CASE 
            WHEN COALESCE((SELECT cost FROM purchase_items 
                          WHERE product_id = p.id 
                          LIMIT 1), 0) > 0
            THEN ((p.price - COALESCE((SELECT cost FROM purchase_items 
                                      WHERE product_id = p.id 
                                      LIMIT 1), 0)) / 
                  COALESCE((SELECT cost FROM purchase_items 
                           WHERE product_id = p.id 
                           LIMIT 1), 1) * 100)
            ELSE 0 
          END as marginPercent,
          i.stock as quantity
        FROM products p
        LEFT JOIN inventory i ON p.id = i.product_id AND i.store_id = ?
        WHERE i.store_id = ?
        ORDER BY marginPercent DESC
        LIMIT ?
      ''', [storeId, storeId, topCount]);
      
      return result;
    } catch (e) {
      print('Error en getTopMarginProducts: $e');
      return [];
    }
  }

  /// Obtiene información de inversión de bodega
  static Future<Map<String, dynamic>> getInventoryInvestmentSummary({
    required int storeId,
  }) async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT p.id) as totalProducts,
          SUM(i.stock) as totalUnits,
          SUM(i.stock * COALESCE((SELECT cost FROM purchase_items 
                                  WHERE product_id = p.id 
                                  LIMIT 1), 0)) as totalInvested,
          SUM(i.stock * p.price) as totalSellValue,
          AVG(p.price - COALESCE((SELECT cost FROM purchase_items 
                                  WHERE product_id = p.id 
                                  LIMIT 1), 0)) as avgMarginPerUnit,
          COUNT(CASE WHEN i.stock <= 2 THEN 1 END) as lowStockCount
        FROM products p
        LEFT JOIN inventory i ON p.id = i.product_id
        WHERE i.store_id = ?
      ''', [storeId]);
      
      if (result.isEmpty) {
        return {
          'totalProducts': 0,
          'totalUnits': 0,
          'totalInvested': 0.0,
          'totalSellValue': 0.0,
          'avgMarginPerUnit': 0.0,
          'lowStockCount': 0,
          'potentialGain': 0.0,
          'potentialROI': 0.0,
        };
      }
      
      final row = result.first;
      final totalInvested = (row['totalInvested'] as num?)?.toDouble() ?? 0.0;
      final totalSellValue = (row['totalSellValue'] as num?)?.toDouble() ?? 0.0;
      final potentialGain = totalSellValue - totalInvested;
      final potentialROI = totalInvested > 0 ? (potentialGain / totalInvested) * 100 : 0.0;
      
      return {
        'totalProducts': (row['totalProducts'] as num?)?.toInt() ?? 0,
        'totalUnits': (row['totalUnits'] as num?)?.toInt() ?? 0,
        'totalInvested': totalInvested,
        'totalSellValue': totalSellValue,
        'potentialGain': potentialGain,
        'potentialROI': potentialROI,
        'avgMarginPerUnit': (row['avgMarginPerUnit'] as num?)?.toDouble() ?? 0.0,
        'lowStockCount': (row['lowStockCount'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('Error en getInventoryInvestmentSummary: $e');
      return {};
    }
  }

  /// Obtiene tendencia de ventas (últimos 7 días)
  static Future<Map<String, double>> getSalesTrendLast7Days({
    required int storeId,
  }) async {
    try {
      final db = await database;
      final Map<String, double> trend = {};
      
      // Inicializar con los últimos 7 días
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        trend[dateStr] = 0.0;
      }
      
      final result = await db.rawQuery('''
        SELECT 
          DATE(s.date) as saleDate,
          SUM(s.total) as dayTotal
        FROM sales s
        WHERE s.store_id = ?
          AND s.date >= datetime('now', '-7 days')
        GROUP BY DATE(s.date)
        ORDER BY s.date
      ''', [storeId]);
      
      // Actualizar trend con datos reales
      for (var row in result) {
        final dateStr = row['saleDate'] as String;
        final dayTotal = (row['dayTotal'] as num).toDouble();
        if (trend.containsKey(dateStr)) {
          trend[dateStr] = dayTotal;
        }
      }
      
      return trend;
    } catch (e) {
      print('Error en getSalesTrendLast7Days: $e');
      return {};
    }
  }

  /// Obtiene rotación promedio de inventario (unidades/día)
  static Future<double> getAverageInventoryRotation({
    required int storeId,
    int daysToAnalyze = 30,
  }) async {
    try {
      final db = await database;
      
      final dateFrom = DateTime.now().subtract(Duration(days: daysToAnalyze));
      
      final result = await db.rawQuery('''
        SELECT SUM(si.quantity) as totalSold
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE s.store_id = ?
          AND s.date >= ?
      ''', [storeId, dateFrom.toIso8601String()]);
      
      if (result.isEmpty || result.first['totalSold'] == null) {
        return 0.0;
      }
      
      final totalSold = (result.first['totalSold'] as num).toDouble();
      return totalSold / daysToAnalyze;
    } catch (e) {
      print('Error en getAverageInventoryRotation: $e');
      return 0.0;
    }
  }

  /// Obtiene productos con inversión crítica (bajo stock, alto valor)
  static Future<List<Map<String, dynamic>>> getCriticalInvestmentProducts({
    required int storeId,
    double minInvestmentValue = 500.0,
    int maxStock = 2,
  }) async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          p.sku,
          p.price,
          COALESCE((SELECT cost FROM purchase_items 
                    WHERE product_id = p.id 
                    LIMIT 1), 0) as costPrice,
          i.stock,
          (i.stock * COALESCE((SELECT cost FROM purchase_items 
                              WHERE product_id = p.id 
                              LIMIT 1), 0)) as investmentValue
        FROM products p
        JOIN inventory i ON p.id = i.product_id
        WHERE i.store_id = ?
          AND i.stock <= ?
          AND (i.stock * COALESCE((SELECT cost FROM purchase_items 
                                  WHERE product_id = p.id 
                                  LIMIT 1), 0)) >= ?
        ORDER BY investmentValue DESC
      ''', [storeId, maxStock, minInvestmentValue]);
      
      return result;
    } catch (e) {
      print('Error en getCriticalInvestmentProducts: $e');
      return [];
    }
  }

  /// Obtiene reporte completo de análisis de inventario
  static Future<Map<String, dynamic>> getInventoryAnalysisReport({
    required int storeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final now = DateTime.now();
      final from = dateFrom ?? DateTime(now.year, now.month, 1);
      final to = dateTo ?? now;
      
      // Obtener todos los datos en paralelo
      final unitsSoldData = await getUnitsSoldByProduct(
        storeId: storeId,
        dateFrom: from,
        dateTo: to,
      );
      
      final topSellers = await getTopSellingProducts(
        storeId: storeId,
        topCount: 10,
        dateFrom: from,
        dateTo: to,
      );
      
      final topMargin = await getTopMarginProducts(
        storeId: storeId,
        topCount: 10,
      );
      
      final investment = await getInventoryInvestmentSummary(storeId: storeId);
      
      final trend = await getSalesTrendLast7Days(storeId: storeId);
      
      final rotation = await getAverageInventoryRotation(
        storeId: storeId,
        daysToAnalyze: 30,
      );
      
      final critical = await getCriticalInvestmentProducts(storeId: storeId);
      
      // Calcular métricas adicionales
      final totalSales = topSellers.fold<double>(
        0,
        (sum, item) => sum + ((item['totalSold'] as num?)?.toDouble() ?? 0),
      );
      
      return {
        'period': {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
        'investment': investment,
        'unitsSoldByProduct': unitsSoldData,
        'topSellers': topSellers,
        'topMargin': topMargin,
        'salesTrend': trend,
        'averageRotation': rotation,
        'criticalProducts': critical,
        'totalSalesInPeriod': totalSales,
        'generatedAt': now.toIso8601String(),
      };
    } catch (e) {
      print('Error en getInventoryAnalysisReport: $e');
      return {};
    }
  }
}
