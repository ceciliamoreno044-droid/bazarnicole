// ignore_for_file: file_names

import 'dart:convert';
import 'package:bazarnicole/Presentation/Template/catalog_template.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Producto real proveniente del backup de Drive.
class DriveProduct {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final String categoryName;
  final String storeName;

  const DriveProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.categoryName,
    this.storeName = '',
  });
}

/// Resultado del catálogo cargado desde Drive.
class CatalogDriveData {
  /// Categorías con sus productos reales. Key = nombre de categoría.
  final Map<String, List<DriveProduct>> productsByCategory;

  /// Mapa de nombre de archivo (sin extensión, normalizado) → thumbnailLink de Drive.
  final Map<String, String> imageThumbnails;

  /// Email del usuario autenticado.
  final String userEmail;

  /// Secciones del catálogo construidas desde los JSON de Drive.
  /// Listas vacías si no se pudo construir el catálogo.
  final List<CatalogSection> sections;

  const CatalogDriveData({
    required this.productsByCategory,
    required this.imageThumbnails,
    required this.userEmail,
    this.sections = const [],
  });

  bool get hasData => productsByCategory.isNotEmpty;
}

/// Cliente HTTP autenticado con Bearer token.
class _AuthClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;
  _AuthClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}

/// Servicio para leer datos del catálogo desde el backup en Google Drive.
///
/// Estructura esperada en Drive:
///   bazarypapeleria/
///     BazarNicole_Backup_YYYYMMDD_HHMM/
///       tablas_json/
///         products.json
///         categories.json
///         inventory.json
///         stores.json
///         ...
///       imagenes/
///         (archivos de imagen)
class DriveDataService {
  // ID fijo de la carpeta raíz "bazarypapeleria" en Drive.
  static const _bazarFolderId = '1mksspeR2VoZuSj92LIke0dxobma6U0Ke';

  // ID fijo del backup más reciente: BazarNicole_Backup_20260615_2020
  static const _backupFolderId = '14jkB_xNTPtFgNM4CdPhDMHorlAWHPEZE';

  // API Key pública de Google — solo lectura en carpetas compartidas públicamente.
  static const _apiKey = 'AIzaSyDlhgSJdJTO1plLjJOFM1g8dBQ8f0U_RUY';

  // URL base de Drive REST API v3
  static const _driveBase = 'https://www.googleapis.com/drive/v3';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveReadonlyScope],
  );

  static GoogleSignInAccount? _account;

  // ── Auth ────────────────────────────────────────────────────────────────────

  static bool get isSignedIn => _account != null;
  static String get userEmail => _account?.email ?? '';

  /// Intenta restaurar la sesión de Google silenciosamente.
  /// Retorna el email si logró autenticarse, null si no.
  static Future<String?> signInSilently() async {
    try {
      _account = await _googleSignIn.signInSilently();
      return _account?.email;
    } catch (e) {
      debugPrint('[DriveDataService] signInSilently error: $e');
      return null;
    }
  }

  /// Lanza el flujo explícito de inicio de sesión con Google.
  static Future<String> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Inicio de sesión cancelado');
    _account = account;
    return account.email;
  }

  /// Cierra la sesión.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  // ── Carga pública (sin login) ────────────────────────────────────────────────

  /// Carga el catálogo desde una carpeta Drive compartida públicamente,
  /// usando solo la API Key (sin OAuth). No requiere inicio de sesión.
  ///
  /// La carpeta raíz y sus subcarpetas deben tener permisos
  /// "Cualquier persona con el enlace puede ver".
  static Future<CatalogDriveData> fetchPublic() async {
    try {
      // El backup folder es conocido y fijo — no necesita búsqueda dinámica.
      const backupFolderId = _backupFolderId;

      // 1. Localizar subcarpetas tablas_json e imagenes
      final jsonFolderId = await _publicFindSubfolder(
        backupFolderId,
        'tablas_json',
      );
      final imagesFolderId = await _publicFindSubfolder(
        backupFolderId,
        'imagenes',
      );

      // 2. Descargar JSON en paralelo
      final results = await Future.wait([
        _publicDownloadJson(jsonFolderId, 'products.json'),
        _publicDownloadJson(jsonFolderId, 'categories.json'),
        _publicDownloadJson(jsonFolderId, 'stores.json'),
      ]);

      final productsJson = results[0];
      final categoriesJson = results[1];
      final storesJson = results[2];

      // 3. Listar imágenes
      final imageThumbnails = await _publicListImageThumbnails(imagesFolderId);

      // 4. Construir mapa legacy y secciones
      final productsByCategory = _buildProductsByCategory(
        productsJson: productsJson,
        categoriesJson: categoriesJson,
        storesJson: storesJson,
      );

      final sections = CatalogBuilder.buildFromJson(
        productsJson: productsJson,
        categoriesJson: categoriesJson,
        storesJson: storesJson,
        imageThumbnails: imageThumbnails,
      );

      return CatalogDriveData(
        productsByCategory: productsByCategory,
        imageThumbnails: imageThumbnails,
        userEmail: '',
        sections: sections,
      );
    } catch (e) {
      debugPrint('[DriveDataService.fetchPublic] error: $e');
      rethrow;
    }
  }

  // ── Helpers públicos (API Key) ────────────────────────────────────────────

  static Uri _driveFilesUri(Map<String, String> params) {
    return Uri.parse(
      '$_driveBase/files',
    ).replace(queryParameters: {...params, 'key': _apiKey});
  }

  static Future<Map<String, dynamic>> _publicGet(Uri uri) async {
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Drive API error ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Busca una subcarpeta por nombre usando API Key.
  static Future<String> _publicFindSubfolder(
    String parentId,
    String name,
  ) async {
    final uri = _driveFilesUri({
      'q':
          "'$parentId' in parents and name='$name' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      'pageSize': '5',
      'fields': 'files(id,name)',
    });
    final data = await _publicGet(uri);
    final files = (data['files'] as List?)?.cast<Map<String, dynamic>>();
    if (files == null || files.isEmpty) {
      throw Exception("Subcarpeta '$name' no encontrada en Drive.");
    }
    return files.first['id'] as String;
  }

  /// Descarga un JSON de Drive usando API Key.
  static Future<List<Map<String, dynamic>>> _publicDownloadJson(
    String folderId,
    String fileName,
  ) async {
    // 1. Buscar el archivo
    final listUri = _driveFilesUri({
      'q': "'$folderId' in parents and name='$fileName' and trashed=false",
      'pageSize': '5',
      'fields': 'files(id,name)',
    });
    final listData = await _publicGet(listUri);
    final files = (listData['files'] as List?)?.cast<Map<String, dynamic>>();
    if (files == null || files.isEmpty) {
      debugPrint('[DriveDataService] $fileName no encontrado, omitiendo.');
      return [];
    }

    // 2. Descargar contenido
    final fileId = files.first['id'] as String;
    final downloadUri = Uri.parse(
      '$_driveBase/files/$fileId',
    ).replace(queryParameters: {'alt': 'media', 'key': _apiKey});
    final resp = await http.get(downloadUri);
    if (resp.statusCode != 200) {
      debugPrint(
        '[DriveDataService] Error descargando $fileName: ${resp.statusCode}',
      );
      return [];
    }

    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    return [];
  }

  /// Lista thumbnails de imágenes en un folder usando API Key.
  static Future<Map<String, String>> _publicListImageThumbnails(
    String folderId,
  ) async {
    final Map<String, String> result = {};
    String? pageToken;

    do {
      final params = <String, String>{
        'q': "'$folderId' in parents and trashed=false",
        'pageSize': '100',
        'fields': 'nextPageToken,files(id,name,thumbnailLink)',
      };
      if (pageToken != null) params['pageToken'] = pageToken;

      final uri = _driveFilesUri(params);
      final data = await _publicGet(uri);
      final files =
          (data['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (final f in files) {
        final name = f['name'] as String?;
        if (name == null) continue;
        final normalized = _normalizeName(name);
        final thumb = f['thumbnailLink'] != null
            ? (f['thumbnailLink'] as String).replaceAll(
                RegExp(r'=s\d+'),
                '=s800',
              )
            : 'https://lh3.googleusercontent.com/d/${f['id']}';
        result[normalized] = thumb;
      }

      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null);

    debugPrint('[DriveDataService] Imágenes cargadas: ${result.length}');
    return result;
  }

  // ── Carga principal (OAuth) ─────────────────────────────────────────────────

  /// Carga productos e imágenes del backup más reciente en Drive.
  ///
  /// Lanza [Exception] si no hay sesión activa o si falla la lectura.
  static Future<CatalogDriveData> fetchCatalogData() async {
    if (_account == null) {
      throw Exception('No hay sesión activa. Inicia sesión primero.');
    }

    final auth = await _account!.authentication;
    final client = _AuthClient(http.Client(), auth.accessToken!);
    final driveApi = drive.DriveApi(client);

    try {
      // 1. Encontrar la carpeta de backup más reciente
      final backupFolderId = await _findLatestBackupFolder(driveApi);

      // 2. Localizar subcarpeta de JSONs
      final jsonFolderId = await _findSubfolder(
        driveApi,
        backupFolderId,
        'tablas_json',
      );
      final imagesFolderId = await _findSubfolder(
        driveApi,
        backupFolderId,
        'imagenes',
      );

      // 3. Descargar solo products.json y categories.json
      final results = await Future.wait([
        _downloadJson(driveApi, jsonFolderId, 'products.json'),
        _downloadJson(driveApi, jsonFolderId, 'categories.json'),
        _downloadJson(driveApi, jsonFolderId, 'stores.json'),
      ]);

      final productsJson = results[0];
      final categoriesJson = results[1];
      final storesJson = results[2];

      // 4. Parsear datos
      final productsByCategory = _buildProductsByCategory(
        productsJson: productsJson,
        categoriesJson: categoriesJson,
        storesJson: storesJson,
      );

      // 5. Listar imágenes
      final imageThumbnails = await _listImageThumbnails(
        driveApi,
        imagesFolderId,
      );

      // 6. Construir secciones del catálogo desde los JSON crudos
      final sections = CatalogBuilder.buildFromJson(
        productsJson: productsJson,
        categoriesJson: categoriesJson,
        storesJson: storesJson,
        imageThumbnails: imageThumbnails,
      );

      return CatalogDriveData(
        productsByCategory: productsByCategory,
        imageThumbnails: imageThumbnails,
        userEmail: _account!.email,
        sections: sections,
      );
    } finally {
      client.close();
    }
  }

  // ── Helpers privados ────────────────────────────────────────────────────────

  /// Encuentra la carpeta de backup más reciente dentro de bazarypapeleria.
  static Future<String> _findLatestBackupFolder(drive.DriveApi api) async {
    final list = await api.files.list(
      q: "'$_bazarFolderId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      orderBy: 'createdTime desc',
      pageSize: 10,
      $fields: 'files(id,name,createdTime)',
    );

    final files = list.files;
    if (files == null || files.isEmpty) {
      throw Exception('No se encontró ninguna carpeta de backup en Drive.');
    }

    // La primera es la más reciente (orderBy createdTime desc)
    debugPrint('[DriveDataService] Backup folder: ${files.first.name}');
    return files.first.id!;
  }

  /// Busca una subcarpeta por nombre dentro de un folder dado.
  static Future<String> _findSubfolder(
    drive.DriveApi api,
    String parentId,
    String name,
  ) async {
    final list = await api.files.list(
      q: "'$parentId' in parents and name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      pageSize: 5,
      $fields: 'files(id,name)',
    );

    final files = list.files;
    if (files == null || files.isEmpty) {
      throw Exception("Subcarpeta '$name' no encontrada en Drive.");
    }
    return files.first.id!;
  }

  /// Descarga el contenido de un archivo JSON y lo parsea como lista de mapas.
  static Future<List<Map<String, dynamic>>> _downloadJson(
    drive.DriveApi api,
    String folderId,
    String fileName,
  ) async {
    // Buscar el archivo
    final list = await api.files.list(
      q: "'$folderId' in parents and name = '$fileName' and trashed = false",
      pageSize: 5,
      $fields: 'files(id,name)',
    );

    final files = list.files;
    if (files == null || files.isEmpty) {
      debugPrint('[DriveDataService] $fileName no encontrado, omitiendo.');
      return [];
    }

    final fileId = files.first.id!;
    final media =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }

    final content = utf8.decode(bytes);
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Lista los archivos de imagen en el folder y retorna un mapa
  /// normalizedName → thumbnailLink (o directLink si thumbnailLink está vacío).
  static Future<Map<String, String>> _listImageThumbnails(
    drive.DriveApi api,
    String folderId,
  ) async {
    final Map<String, String> result = {};
    String? pageToken;

    do {
      final list = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        pageSize: 100,
        pageToken: pageToken,
        $fields: 'nextPageToken,files(id,name,thumbnailLink,webContentLink)',
      );

      for (final f in list.files ?? []) {
        if (f.name == null) continue;
        final normalized = _normalizeName(f.name!);
        // Usar thumbnailLink con tamaño mayor; fallback a Google Drive viewer
        final thumb = f.thumbnailLink != null
            ? f.thumbnailLink!.replaceAll(RegExp(r'=s\d+'), '=s800')
            : 'https://lh3.googleusercontent.com/d/${f.id}';
        result[normalized] = thumb;
      }

      pageToken = list.nextPageToken;
    } while (pageToken != null);

    debugPrint('[DriveDataService] Imágenes cargadas: ${result.length}');
    return result;
  }

  /// Construye el mapa categoryName → [DriveProduct] a partir de los JSONs.
  static Map<String, List<DriveProduct>> _buildProductsByCategory({
    required List<Map<String, dynamic>> productsJson,
    required List<Map<String, dynamic>> categoriesJson,
    required List<Map<String, dynamic>> storesJson,
  }) {
    // Mapa categoryId → categoryName
    final categoryNames = <int, String>{};
    for (final c in categoriesJson) {
      final id = (c['id'] as num?)?.toInt();
      final name = c['name'] as String?;
      if (id != null && name != null) categoryNames[id] = name;
    }

    // Mapa storeId → storeName
    final storeNames = <int, String>{};
    for (final s in storesJson) {
      final id = (s['id'] as num?)?.toInt();
      final name = s['name'] as String?;
      if (id != null && name != null) storeNames[id] = name;
    }

    final Map<String, List<DriveProduct>> byCategory = {};

    for (final p in productsJson) {
      final id = (p['id'] as num?)?.toInt();
      final name = p['name'] as String?;
      final sku = p['sku'] as String? ?? '';
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      final categoryId = (p['category_id'] as num?)?.toInt();
      final storeId = (p['store_id'] as num?)?.toInt();
      // Stock directo desde la tabla products (campo stock si existe)
      final stock = (p['stock'] as num?)?.toInt() ?? 0;

      if (id == null || name == null) continue;

      final categoryName =
          (categoryId != null ? categoryNames[categoryId] : null) ??
          'Sin categoría';

      final storeName = (storeId != null ? storeNames[storeId] : null) ?? '';

      final product = DriveProduct(
        id: id,
        name: name,
        sku: sku,
        price: price,
        stock: stock,
        categoryName: categoryName,
        storeName: storeName,
      );

      byCategory.putIfAbsent(categoryName, () => []).add(product);
    }

    // Ordenar productos por nombre dentro de cada categoría
    for (final list in byCategory.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    return byCategory;
  }

  // ── Utilidades ──────────────────────────────────────────────────────────────

  /// Normaliza un nombre de archivo para búsqueda aproximada.
  /// Remueve extensión, convierte a minúsculas y quita tildes.
  static String _normalizeName(String fileName) {
    // Quitar extensión
    final withoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    return _removeAccents(withoutExt.toLowerCase().trim());
  }

  static String _removeAccents(String input) {
    const accents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const plain = 'aaaaaeeeeiiiioooooouuuunc';
    var result = input;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result;
  }

  /// Dada la información de imágenes y el nombre de categoría,
  /// retorna la URL del thumbnail más apropiado o null si no hay coincidencia.
  static String? findImageForCategory(
    Map<String, String> thumbnails,
    String categoryName,
  ) {
    final normalized = _removeAccents(categoryName.toLowerCase());
    // Búsqueda exacta
    if (thumbnails.containsKey(normalized)) return thumbnails[normalized];
    // Búsqueda parcial: alguna imagen cuyo nombre contiene la categoría
    for (final entry in thumbnails.entries) {
      if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
