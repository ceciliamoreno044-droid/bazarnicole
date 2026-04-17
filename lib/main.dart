import 'dart:io';
import 'package:bazarnicole/Presentation/View/Auth/app_routes.dart';
import 'package:bazarnicole/Presentation/Services/auth_service.dart';
import 'package:bazarnicole/Presentation/Services/database_service.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bazarnicole/Presentation/Controller/auth_provider.dart';
import 'package:bazarnicole/Presentation/Controller/product_management_controller.dart';
import 'package:bazarnicole/Presentation/Controller/cash_controller.dart';
import 'package:bazarnicole/Presentation/Controller/customers_controller.dart';
import 'package:bazarnicole/Presentation/Controller/pos_controller.dart';
import 'package:bazarnicole/Presentation/Controller/purchases_controller.dart';
import 'package:bazarnicole/Presentation/Controller/reports_controller.dart';
import 'package:bazarnicole/Presentation/Context/providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Removida la variable global no utilizada que puede causar problemas
// late MyDatabase driftDatabase; // ❌ COMENTADA PARA EVITAR SIGSEGV

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 INICIALIZAR LOCALIZACIÓN PARA FECHAS
  await initializeDateFormatting('es', null);

  // 🖥️ CONFIGURAR TAMAÑO DE VENTANA PARA DESKTOP
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    // Configuración básica que funciona en Windows
    await windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Configurar después de mostrar
    await windowManager.setSize(const Size(800, 600));
    await windowManager.setMinimumSize(const Size(400, 300));
    await windowManager.setResizable(true);
    await windowManager.setMinimizable(true);
    await windowManager.setMaximizable(true);
    await windowManager.setClosable(true);
    await windowManager.setTitle(
      'Sistema de Gestión Comercial – Bazar & Tienda',
    );

    // Para Windows, intentar restaurar si está minimizado
    if (Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 200));
      await windowManager.restore(); // Asegurar que no esté minimizado
      await windowManager.focus();
    }
  } // 🔧 INICIALIZACIÓN ESPECÍFICA POR PLATAFORMA
  await _initializePlatformSpecific();

  // 🗄️ INICIALIZAR BASE DE DATOS DE FORMA SEGURA
  await _initDatabaseSafely();

  // 🌐 En web, mostrar el catálogo público directamente
  if (kIsWeb) {
    runApp(MyApp(initialRoute: AppRoutes.catalog));
    return;
  }

  try {
    // Verificar si hay sesión activa
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    String initialRoute;
    if (isLoggedIn) {
      initialRoute = AppRoutes.dashboard;
    } else {
      initialRoute = AppRoutes.login;
    }

    runApp(MyApp(initialRoute: initialRoute));
  } catch (e) {
    runApp(MyApp(initialRoute: AppRoutes.login));
  }
}

// 🚀 INICIALIZACIÓN ESPECÍFICA POR PLATAFORMA
Future<void> _initializePlatformSpecific() async {
  if (kIsWeb) {
    return;
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else if (Platform.isIOS || Platform.isAndroid) {
    // No hacer nada, usar el SQLite nativo de la plataforma
  }
}

// 🛡️ INICIALIZACIÓN SEGURA DE BASE DE DATOS
Future<void> _initDatabaseSafely() async {
  try {
    // Para iOS/Android, usar método directo sin servicios complejos
    if (Platform.isIOS || Platform.isAndroid) {
      await _initMobileDatabase();
    } else {
      // Para desktop, usar el DatabaseService normal
      await DatabaseService.database;
    }
  } catch (e) {
    // Intentar método fallback más seguro
    await _safeFallbackDatabaseInit();
  }
}

// 🔧 INICIALIZACIÓN DIRECTA PARA MÓVILES (EVITA SIGSEGV)
Future<void> _initMobileDatabase() async {
  try {
    final dbPath = join(await getDatabasesPath(), 'bazarnicole.db');

    final File dbFile = File(dbPath);

    // Verificar si existe
    if (!await dbFile.exists()) {
      final ByteData data = await rootBundle.load(
        'assets/database/bazarnicole.db',
      );
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await dbFile.writeAsBytes(bytes, flush: true);
    }

    // Verificar que se puede abrir
    final db = await openDatabase(dbPath, version: 1, readOnly: false);

    // Cerrar inmediatamente - solo verificamos que funcione
    await db.close();
  } catch (e) {
    rethrow;
  }
}

// 🔧 MÉTODO FALLBACK MEJORADO Y SEGURO

Future<void> _safeFallbackDatabaseInit() async {
  try {
    // Solo para plataformas móviles, usar el método tradicional
    if (Platform.isIOS || Platform.isAndroid) {
      final dbPath = join(await getDatabasesPath(), 'bazarnicole.db');

      // Verificar si existe y es válida
      final File dbFile = File(dbPath);
      if (await dbFile.exists()) {
        try {
          final db = await openDatabase(
            dbPath,
            readOnly: true, // Solo lectura para verificación
          );
          await db.close();
          return;
        } catch (e) {
          await dbFile.delete();
        }
      }

      // Copiar desde assets solo si es necesario
      try {
        final ByteData data = await rootBundle.load(
          'assets/database/bazarnicole.db',
        );
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        await dbFile.writeAsBytes(bytes, flush: true);

        // Verificar que se puede abrir
        final db = await openDatabase(dbPath);
        await db.close();
      } catch (e) {
        throw Exception('No se pudo inicializar la base de datos');
      }
    }
  } catch (e) {
    // En este punto, la app continuará pero sin base de datos prepoblada
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductManagementController()),
        ChangeNotifierProvider(create: (_) => CashController()),
        ChangeNotifierProvider(create: (_) => PosController()),
        ChangeNotifierProvider(create: (_) => PurchasesController()),
        ChangeNotifierProvider(create: (_) => CustomersController()),
        ChangeNotifierProvider(create: (_) => ReportsController()),
        // Providers de contexto
        ...AppProviders.getProviders(),
      ],
      child: MaterialApp(
        title: 'Bazar & Tienda',
        theme: ThemeData(
          primaryColor: AppColors.primaryLogo,
          useMaterial3: true,
        ),
        initialRoute: initialRoute,
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
      ),
    );
  }
}
