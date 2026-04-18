// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_location_service.dart';

/// Resultado de una operación de backup.
class BackupResult {
  final bool success;
  final String message;
  final String? driveFolderUrl;
  final List<String> uploadedFiles;

  BackupResult({
    required this.success,
    required this.message,
    this.driveFolderUrl,
    this.uploadedFiles = const [],
  });
}

/// Reporte de progreso durante el backup.
class BackupProgress {
  final String step;
  final int current;
  final int total;

  BackupProgress({
    required this.step,
    required this.current,
    required this.total,
  });

  double get percent => total == 0 ? 0 : current / total;
}

/// Cliente HTTP autenticado con el token de Google Sign-In.
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  _AuthenticatedClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// Servicio para exportar la base de datos a JSON y subir a Google Drive.
class GoogleDriveBackupService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveScope],
  );

  static GoogleSignInAccount? _currentUser;

  /// Retorna si hay un usuario autenticado activamente.
  static bool get isSignedIn => _currentUser != null;

  static String get currentUserEmail => _currentUser?.email ?? 'No autenticado';

  /// Inicia sesión con Google y retorna el email del usuario.
  static Future<String> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('El usuario canceló el inicio de sesión');
      }
      _currentUser = account;
      return account.email;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Cierra sesión de Google.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Intenta restaurar la sesión silenciosamente.
  static Future<String?> signInSilently() async {
    final account = await _googleSignIn.signInSilently();
    _currentUser = account;
    return account?.email;
  }

  /// Realiza el backup completo: JSON de tablas + imágenes a Google Drive.
  /// [onProgress] se llama con cada paso.
  static Future<BackupResult> performBackup({
    void Function(BackupProgress)? onProgress,
  }) async {
    try {
      // 1. Verificar autenticación
      if (_currentUser == null) {
        throw Exception('Debe iniciar sesión primero');
      }

      onProgress?.call(
        BackupProgress(step: 'Autenticando...', current: 0, total: 10),
      );

      final auth = await _currentUser!.authentication;
      final authClient = _AuthenticatedClient(http.Client(), {
        'Authorization': 'Bearer ${auth.accessToken}',
      });
      final driveApi = drive.DriveApi(authClient);

      // 2. Crear carpeta raíz en Drive con timestamp
      onProgress?.call(
        BackupProgress(
          step: 'Creando carpeta en Drive...',
          current: 1,
          total: 10,
        ),
      );

      final now = DateTime.now();
      final folderName =
          'BazarNicole_Backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      // Carpeta destino fija en Drive: "bazarypapeleria"
      const String _bazarFolderId = '1mksspeR2VoZuSj92LIke0dxobma6U0Ke';

      final rootFolderId = await _createDriveFolder(
        driveApi,
        folderName,
        _bazarFolderId,
      );

      // 3. Crear subcarpeta para JSONs
      final jsonFolderId = await _createDriveFolder(
        driveApi,
        'tablas_json',
        rootFolderId,
      );

      // 4. Exportar tablas a JSON y subir
      onProgress?.call(
        BackupProgress(
          step: 'Exportando tablas de la base de datos...',
          current: 2,
          total: 10,
        ),
      );

      final dbPath = await _getDbPath();
      final db = await _openDb(dbPath);

      final tables = await _getAllTableNames(db);
      final List<String> uploadedFiles = [];

      for (int i = 0; i < tables.length; i++) {
        final table = tables[i];
        onProgress?.call(
          BackupProgress(
            step: 'Exportando tabla: $table (${i + 1}/${tables.length})',
            current: 3 + i,
            total: 3 + tables.length + 3,
          ),
        );

        final rows = await db.query(table);
        final jsonContent = jsonEncode(rows);
        await _uploadTextFile(
          driveApi,
          '$table.json',
          jsonContent,
          jsonFolderId,
        );
        uploadedFiles.add('$table.json');
      }

      await db.close();

      // 5. Crear subcarpeta para imágenes
      onProgress?.call(
        BackupProgress(
          step: 'Buscando imágenes...',
          current: 3 + tables.length + 1,
          total: 3 + tables.length + 3,
        ),
      );

      final imagesFolderId = await _createDriveFolder(
        driveApi,
        'imagenes',
        rootFolderId,
      );
      final imagesUploaded = await _uploadImagesFolder(
        driveApi,
        imagesFolderId,
        onProgress: (step) => onProgress?.call(
          BackupProgress(
            step: step,
            current: 3 + tables.length + 2,
            total: 3 + tables.length + 3,
          ),
        ),
      );
      uploadedFiles.addAll(imagesUploaded);

      // 6. Enlace a la carpeta
      onProgress?.call(
        BackupProgress(
          step: '¡Backup completado!',
          current: 3 + tables.length + 3,
          total: 3 + tables.length + 3,
        ),
      );

      final folderUrl = 'https://drive.google.com/drive/folders/$rootFolderId';

      authClient.close();

      return BackupResult(
        success: true,
        message: '✅ Backup completado exitosamente en Google Drive',
        driveFolderUrl: folderUrl,
        uploadedFiles: uploadedFiles,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '⛔ Error durante el backup: $e',
      );
    }
  }

  // ─── Métodos privados ──────────────────────────────────────────────────────

  static Future<String> _getDbPath() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final path = await getDatabasesPath();
      return '$path/data.db';
    }
    return DatabaseLocationService.getDatabasePath();
  }

  static Future<Database> _openDb(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return openDatabase(path, readOnly: true);
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(readOnly: true),
    );
  }

  static Future<List<String>> _getAllTableNames(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  static Future<String> _createDriveFolder(
    drive.DriveApi driveApi,
    String name,
    String? parentId,
  ) async {
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';

    if (parentId != null) {
      folder.parents = [parentId];
    }

    final created = await driveApi.files.create(folder);
    return created.id!;
  }

  static Future<void> _uploadTextFile(
    drive.DriveApi driveApi,
    String fileName,
    String content,
    String parentFolderId,
  ) async {
    final bytes = utf8.encode(content);
    final stream = Stream.value(bytes);

    final file = drive.File()
      ..name = fileName
      ..parents = [parentFolderId];

    await driveApi.files.create(
      file,
      uploadMedia: drive.Media(stream, bytes.length),
    );
  }

  static Future<List<String>> _uploadImagesFolder(
    drive.DriveApi driveApi,
    String parentFolderId, {
    void Function(String)? onProgress,
  }) async {
    final List<String> uploaded = [];

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docsDir.path}/images');

      if (!await imagesDir.exists()) {
        onProgress?.call('No se encontró carpeta de imágenes (omitido)');
        return uploaded;
      }

      final files = imagesDir
          .listSync(recursive: false)
          .whereType<File>()
          .where((f) {
            final ext = f.path.toLowerCase();
            return ext.endsWith('.jpg') ||
                ext.endsWith('.jpeg') ||
                ext.endsWith('.png') ||
                ext.endsWith('.webp');
          })
          .toList();

      for (final imageFile in files) {
        final fileName = imageFile.uri.pathSegments.last;
        onProgress?.call('Subiendo imagen: $fileName');

        final bytes = await imageFile.readAsBytes();
        final stream = Stream.value(bytes);
        final mimeType = _getMimeType(fileName);

        final driveFile = drive.File()
          ..name = fileName
          ..parents = [parentFolderId];

        await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(stream, bytes.length, contentType: mimeType),
        );
        uploaded.add(fileName);
      }
    } catch (e) {
      debugPrint('Error al subir imágenes: $e');
    }

    return uploaded;
  }

  static String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }
}
