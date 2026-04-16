import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'backup_service.dart';
import 'database_location_service.dart';

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

    await _seedStores(db);
    await _seedCatalog(db);
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
  static Future<Map<String, dynamic>?> getActiveCashSession(
    int storeId,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT cs.id, cs.store_id, cs.opening_amount, cs.opened_at, cs.status,
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
        '''INSERT INTO cash_sessions (store_id, opening_amount, opened_at, status)
           VALUES (?, ?, ?, 'open')''',
        [storeId, openingAmount, DateTime.now().toIso8601String()],
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
        final available =
            stockRows.isEmpty ? 0 : (stockRows.first['stock'] as num).toInt();
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
        final paidNow =
            payments.fold<double>(0, (s, p) => s + (p['amount'] as num));
        await txn.rawInsert(
          '''INSERT INTO credit_sales (sale_id, total, paid, status)
             VALUES (?, ?, ?, ?)''',
          [
            saleId,
            total,
            paidNow,
            paidNow >= total ? 'paid' : 'pending',
          ],
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
}
