// ignore_for_file: file_names, deprecated_member_use

import 'dart:io';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_location_service.dart';

class AdminDBPage extends StatefulWidget {
  const AdminDBPage({super.key});

  @override
  State<AdminDBPage> createState() => _AdminDBPageState();
}

class _AdminDBPageState extends State<AdminDBPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  List<Map<String, dynamic>> _queryResult = [];
  String _message = '';
  Color _messageColor = AppColors.blackOverlay;
  bool _isLoading = false;
  final ScrollController _verticalScroll = ScrollController();

  late Database db;
  String? _actualDbPath; // Ruta real obtenida del DatabaseLocationService

  // ✅ MÉTODO MEJORADO: Obtener la ruta real usando DatabaseLocationService
  Future<String> get dbPath async {
    if (_actualDbPath != null) return _actualDbPath!;

    if (Platform.isAndroid || Platform.isIOS) {
      // Para móviles, usar el método estándar
      final path = await getDatabasesPath();
      _actualDbPath = '$path/data.db';
    } else {
      // Para desktop, usar el DatabaseLocationService para obtener la ruta correcta
      _actualDbPath = await DatabaseLocationService.getDatabasePath();
    }

    return _actualDbPath!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _openDB();
  }

  Future<void> _openDB() async {
    setState(() => _isLoading = true);
    try {
      final path = await dbPath; // ✅ Await para obtener la ruta

      if (Platform.isAndroid || Platform.isIOS) {
        // Para Android e iOS usar SQLite nativo
        db = await openDatabase(path);
      } else {
        // Para Desktop (macOS, Windows, Linux) usar sqflite_ffi
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        db = await databaseFactory.openDatabase(path);
      }
      setState(() {
        _message =
            '✅ Base de datos conectada correctamente (${_getCurrentPlatform()})';
        _messageColor = AppColors.darkGreen;
      });
    } catch (e) {
      setState(() {
        _message = '⛔ Error al conectar: $e';
        _messageColor = AppColors.primaryRed;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runQuery() async {
    final sql = _queryController.text.trim();
    if (sql.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (sql.toLowerCase().startsWith('select')) {
        final result = await db.rawQuery(sql);
        setState(() {
          _queryResult = result;
          _message = '✅ Consulta exitosa (${result.length} filas)';
          _messageColor = AppColors.darkGreen;
        });
      } else {
        int changes = 0;
        if (sql.toLowerCase().startsWith('update')) {
          changes = await db.rawUpdate(sql);
        } else if (sql.toLowerCase().startsWith('delete')) {
          changes = await db.rawDelete(sql);
        } else if (sql.toLowerCase().startsWith('insert')) {
          changes = await db.rawInsert(sql);
        } else {
          await db.execute(sql);
        }
        setState(() {
          _queryResult = [];
          if (sql.toLowerCase().startsWith('update')) {
            _message = '🔄 UPDATE realizado ($changes registros afectados)';
            _messageColor = AppColors.primaryBlue;
          } else if (sql.toLowerCase().startsWith('delete')) {
            _message = '🗑️ DELETE realizado ($changes registros eliminados)';
            _messageColor = AppColors.primaryRed;
          } else if (sql.toLowerCase().startsWith('insert')) {
            _message = '📥 INSERT realizado ($changes registros insertados)';
            _messageColor = AppColors.darkGreen;
          } else {
            _message = '⚙️ Comando ejecutado correctamente';
            _messageColor = AppColors.primaryBlue;
          }
        });
      }
    } catch (e) {
      setState(() {
        _message = '⛔ Error SQL: ${_formatError(e.toString())}';
        _messageColor = AppColors.primaryRed;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatError(String error) {
    final regex = RegExp(
      r'(near .*: syntax error)|(no such table: \w+)|(NOT NULL constraint failed: \w+\.\w+)',
    );
    final match = regex.firstMatch(error);
    return match?.group(0) ?? error;
  }

  Future<void> _copyToClipboard(String text, {String? successMessage}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successMessage ?? '📋 Copiado al portapapeles',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.darkGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⛔ Error al copiar: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryRed,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  String _generateResultsText() {
    if (_queryResult.isEmpty) {
      return 'No hay resultados para mostrar';
    }

    final columns = _queryResult.first.keys.toList();
    final StringBuffer buffer = StringBuffer();

    // Información de la consulta
    buffer.writeln('=== RESULTADOS DE CONSULTA SQL ===');
    buffer.writeln('Fecha: ${DateTime.now().toString()}');
    buffer.writeln('Plataforma: ${_getCurrentPlatform()}');
    buffer.writeln('Registros encontrados: ${_queryResult.length}');
    buffer.writeln('Consulta ejecutada: ${_queryController.text.trim()}');
    buffer.writeln('');

    // Encabezados
    buffer.writeln(columns.join('\t'));
    buffer.writeln('-' * (columns.length * 15)); // Línea separadora

    // Datos
    for (int i = 0; i < _queryResult.length; i++) {
      final row = _queryResult[i];
      final values = columns
          .map((col) => row[col]?.toString() ?? 'NULL')
          .toList();
      buffer.writeln('${i + 1}.\t${values.join('\t')}');
    }

    buffer.writeln('');
    buffer.writeln('=== FIN DE RESULTADOS ===');

    return buffer.toString();
  }

  String _generateCleanResultsText() {
    if (_queryResult.isEmpty) {
      return 'No hay resultados para mostrar';
    }

    final columns = _queryResult.first.keys.toList();
    final StringBuffer buffer = StringBuffer();

    // Solo encabezados y datos (formato CSV/TSV)
    buffer.writeln(columns.join('\t'));

    for (final row in _queryResult) {
      final values = columns.map((col) => row[col]?.toString() ?? '').toList();
      buffer.writeln(values.join('\t'));
    }

    return buffer.toString();
  }

  String _getCurrentPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Desconocida';
  }

  String _getPlatformIcon() {
    if (Platform.isAndroid) return '🤖';
    if (Platform.isIOS) return '🍎';
    if (Platform.isMacOS) return '💻';
    if (Platform.isWindows) return '🪟';
    if (Platform.isLinux) return '🐧';
    return '❓';
  }

  Future<void> _replaceDatabase() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Selecciona el archivo de base de datos',
      );

      if (result != null && result.files.single.path != null) {
        final File selectedFile = File(result.files.single.path!);

        // Cerrar la conexión actual
        await db.close();

        final path = await dbPath; // ✅ Await para obtener la ruta real

        if (Platform.isAndroid || Platform.isIOS) {
          // Para móviles, obtener la ruta real de la base de datos
          final String realDbPath = await getDatabasesPath();
          final String fullDbPath = '$realDbPath/data.db';

          // Hacer backup de la DB actual
          final String backupPath =
              '$realDbPath/data.db.backup.${DateTime.now().millisecondsSinceEpoch}';

          if (await File(fullDbPath).exists()) {
            await File(fullDbPath).copy(backupPath);
          }

          // Reemplazar con el nuevo archivo
          await selectedFile.copy(fullDbPath);
        } else {
          // Para desktop, usar la ruta obtenida del LocationService
          final String backupPath =
              '${path}.backup.${DateTime.now().millisecondsSinceEpoch}';
          await File(path).copy(backupPath);
          await selectedFile.copy(path);
        }

        // Reabrir la conexión
        await _openDB();

        setState(() {
          _message =
              '✅ Base de datos reemplazada exitosamente desde: ${result.files.single.name}';
          _messageColor = AppColors.darkGreen;
        });
      } else {
        setState(() {
          _message = '⚠️ No se seleccionó ningún archivo';
          _messageColor = AppColors.primaryBlue;
        });
      }
    } catch (e) {
      setState(() {
        _message = '⛔ Error al reemplazar la base de datos: $e';
        _messageColor = AppColors.primaryRed;
      });
      // Intentar reabrir la conexión original
      try {
        await _openDB();
      } catch (reopenError) {
        setState(() {
          _message =
              '⛔ Error crítico: No se pudo reabrir la base de datos: $reopenError';
          _messageColor = AppColors.primaryRed;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyDatabaseFromAssets() async {
    setState(() => _isLoading = true);

    try {
      // Cerrar la conexión actual
      await db.close();

      final path = await dbPath; // ✅ Await para obtener la ruta real

      String realDbPath;
      if (Platform.isAndroid || Platform.isIOS) {
        // Para móviles, obtener la ruta real de la base de datos
        final String dbDirectory = await getDatabasesPath();
        realDbPath = '$dbDirectory/data.db';
      } else {
        // Para desktop, usar la ruta obtenida del LocationService
        realDbPath = path;
      }

      // Hacer backup de la DB actual
      final String backupPath =
          '${realDbPath}.backup.${DateTime.now().millisecondsSinceEpoch}';

      // Verificar si existe la DB actual para hacer backup
      if (await File(realDbPath).exists()) {
        await File(realDbPath).copy(backupPath);
      }

      // Cargar el archivo desde assets
      final ByteData data = await rootBundle.load('assets/database/data.db');

      // Escribir los bytes al archivo de destino
      final List<int> bytes = data.buffer.asUint8List();
      await File(realDbPath).writeAsBytes(bytes);

      // Reabrir la conexión
      await _openDB();

      setState(() {
        _message =
            '✅ Base de datos restaurada exitosamente desde assets del proyecto';
        _messageColor = AppColors.darkGreen;
      });
    } catch (e) {
      setState(() {
        _message = '⛔ Error al restaurar desde assets: $e';
        _messageColor = AppColors.primaryRed;
      });
      // Intentar reabrir la conexión original
      try {
        await _openDB();
      } catch (reopenError) {
        setState(() {
          _message =
              '⛔ Error crítico: No se pudo reabrir la base de datos: $reopenError';
          _messageColor = AppColors.primaryRed;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportDB() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newFile = File('${directory.path}/data.db');

      final path = await dbPath; // ✅ Await para obtener la ruta real

      String sourceDbPath;
      if (Platform.isAndroid || Platform.isIOS) {
        // Para móviles, obtener la ruta real de la base de datos
        final String dbDirectory = await getDatabasesPath();
        sourceDbPath = '$dbDirectory/data.db';
      } else {
        // Para desktop, usar la ruta obtenida del LocationService
        sourceDbPath = path;
      }

      await File(sourceDbPath).copy(newFile.path);

      Share.shareXFiles([XFile(newFile.path)], text: 'Base de datos exportada');

      setState(() {
        _message = '📤 Base de datos exportada: ${newFile.path}';
        _messageColor = AppColors.darkGreen;
      });
    } catch (e) {
      setState(() {
        _message = '⛔ Error al exportar: $e';
        _messageColor = AppColors.primaryRed;
      });
    }
  }

  Future<void> _openDatabaseFolder() async {
    try {
      String realPath;
      if (Platform.isAndroid || Platform.isIOS) {
        final String dbDirectory = await getDatabasesPath();
        realPath = '$dbDirectory/data.db';
      } else {
        realPath = await dbPath;
      }

      final String folderPath = File(realPath).parent.path;

      if (Platform.isAndroid || Platform.isIOS) {
        await _copyToClipboard(
          folderPath,
          successMessage:
              '📋 Ruta de carpeta copiada (en móvil no se puede abrir directamente)',
        );

        setState(() {
          _message =
              'ℹ️ En ${_getCurrentPlatform()} la carpeta no se puede abrir directamente. Ruta copiada al portapapeles.';
          _messageColor = AppColors.primaryBlue;
        });
        return;
      }

      ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', [folderPath]);
      } else if (Platform.isWindows) {
        result = await Process.run('explorer', [folderPath]);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', [folderPath]);
      } else {
        throw UnsupportedError('Plataforma no compatible para abrir carpetas');
      }

      if (result.exitCode == 0) {
        setState(() {
          _message = '📂 Carpeta abierta: $folderPath';
          _messageColor = AppColors.darkGreen;
        });
      } else {
        throw Exception(
          result.stderr.toString().isNotEmpty
              ? result.stderr.toString()
              : 'No se pudo abrir la carpeta',
        );
      }
    } catch (e) {
      setState(() {
        _message = '⛔ Error al abrir carpeta de la DB: $e';
        _messageColor = AppColors.primaryRed;
      });
    }
  }

  void _clearConsole() {
    setState(() {
      _queryResult = [];
      _message = 'No hay resultados para mostrar';
      _messageColor = AppColors.primaryBlue;
    });
    _queryController.clear();
  }

  Widget _buildResultConsole() {
    if (_queryResult.isEmpty) {
      return Center(
        child: Text(
          'No hay resultados para mostrar',
          style: TextStyle(
            color: AppColors.mediumGray,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    final columns = _queryResult.first.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkGray.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.blackOverlay.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOverlay.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _verticalScroll,
        child: ListView(
          controller: _verticalScroll,
          children: [
            // Encabezados
            RichText(
              text: TextSpan(
                children: [
                  for (int i = 0; i < columns.length; i++)
                    TextSpan(
                      text: (i > 0 ? '   ' : '') + columns[i].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.lightWhite,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Separador
            Container(
              height: 2,
              color: AppColors.lightWhite.withOpacity(0.25),
              margin: const EdgeInsets.only(bottom: 8),
            ),
            // Filas
            for (final row in _queryResult)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: RichText(
                  text: TextSpan(
                    children: [
                      for (int i = 0; i < columns.length; i++)
                        TextSpan(
                          text:
                              (i > 0 ? '   ' : '') +
                              (row[columns[i]]?.toString() ?? 'NULL'),
                          style: TextStyle(
                            color: row[columns[i]] == null
                                ? AppColors.lightRed
                                : AppColors.lightGreen.withOpacity(0.95),
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplaceDBTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Información de la plataforma
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.primaryBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _getPlatformIcon(),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plataforma Actual',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentPlatform(),
                            style: TextStyle(
                              color: AppColors.blackOverlay,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mediumGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.mediumGray.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ruta de la Base de Datos:',
                              style: TextStyle(
                                color: AppColors.mediumGray,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: AppColors.primaryBlue,
                              size: 16,
                            ),
                            onPressed: () async {
                              String realPath;
                              if (Platform.isAndroid || Platform.isIOS) {
                                final String dbDirectory =
                                    await getDatabasesPath();
                                realPath = '$dbDirectory/data.db';
                              } else {
                                realPath =
                                    await dbPath; // ✅ Await para obtener la ruta real
                              }
                              _copyToClipboard(
                                realPath,
                                successMessage:
                                    '📋 Ruta de DB copiada al portapapeles',
                              );
                            },
                            tooltip: 'Copiar ruta',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.open_in_new,
                              color: AppColors.darkGreen,
                              size: 16,
                            ),
                            onPressed: _isLoading ? null : _openDatabaseFolder,
                            tooltip: 'OPEN - Abrir carpeta',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                      FutureBuilder<String>(
                        future: () async {
                          if (Platform.isAndroid || Platform.isIOS) {
                            final String dbDirectory = await getDatabasesPath();
                            return '$dbDirectory/data.db';
                          } else {
                            return await dbPath; // ✅ Await para obtener la ruta real
                          }
                        }(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Cargando...',
                            style: TextStyle(
                              color: AppColors.blackOverlay,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Título de opciones
          Text(
            'OPCIONES DE REEMPLAZO',
            style: TextStyle(
              color: AppColors.blackOverlay,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Opción 1: Seleccionar archivo
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.darkGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.folder_open,
                          color: AppColors.darkGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seleccionar archivo .db',
                          style: TextStyle(
                            color: AppColors.blackOverlay,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona un archivo de base de datos (.db) desde tu dispositivo para reemplazar la actual.',
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('SELECCIONAR ARCHIVO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _replaceDatabase,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Opción 2: Desde assets (futura implementación)
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.storage,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Desde Assets del Proyecto',
                          style: TextStyle(
                            color: AppColors.blackOverlay,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Restaurar desde la base de datos predefinida incluida en assets/database/data.db del proyecto.',
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('RESTAURAR DESDE ASSETS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _copyDatabaseFromAssets,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Estado/Mensaje
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _messageColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _messageColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _messageColor == AppColors.primaryRed
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: _messageColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _message.isEmpty
                        ? 'Selecciona una opción para reemplazar la base de datos'
                        : _message,
                    style: TextStyle(
                      color: _messageColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_message.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, color: _messageColor, size: 20),
                    onPressed: () => _copyToClipboard(
                      _message,
                      successMessage: '📋 Mensaje copiado al portapapeles',
                    ),
                    tooltip: 'Copiar mensaje',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
              ],
            ),
          ),

          if (_isLoading) ...[
            const SizedBox(height: 20),
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          ],

          // Espacio adicional al final para evitar que el contenido quede muy pegado
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSQLTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Información de la plataforma para SQL Tab
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.darkGreen.withOpacity(0.1),
                  AppColors.darkGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.darkGreen.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPlatformIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getCurrentPlatform()} - Consultas SQL',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FutureBuilder<String>(
                        future: dbPath,
                        builder: (context, snapshot) {
                          final dbName = snapshot.hasData
                              ? snapshot.data!.split('/').last.split('\\').last
                              : 'Cargando...';
                          return Text(
                            'Base de datos: $dbName',
                            style: TextStyle(
                              color: AppColors.mediumGray,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackOverlay.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Escribe tu consulta SQL aquí',
                labelStyle: TextStyle(
                  color: AppColors.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  color: AppColors.primaryBlue,
                  iconSize: 36,
                  onPressed: _runQuery,
                ),
              ),
              style: TextStyle(
                color: AppColors.darkGray,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: const Text(
                    'EJECUTAR CONSULTA',
                    style: TextStyle(fontSize: 15, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blackOverlay,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _runQuery,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services, size: 22),
                label: const Text('LIMPIAR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.mediumGray,
                  side: BorderSide(color: AppColors.mediumGray),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _clearConsole,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _messageColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _messageColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _messageColor == AppColors.primaryRed
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: _messageColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _messageColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_message.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, color: _messageColor, size: 20),
                    onPressed: () => _copyToClipboard(
                      _message,
                      successMessage: '📋 Mensaje copiado al portapapeles',
                    ),
                    tooltip: 'Copiar mensaje',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'RESULTADOS:',
                style: TextStyle(
                  color: AppColors.blackOverlay,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_queryResult.isNotEmpty) ...[
                Text(
                  '${_queryResult.length} registros',
                  style: TextStyle(color: AppColors.mediumGray, fontSize: 14),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.copy,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  tooltip: 'Copiar resultados',
                  onSelected: (String value) {
                    switch (value) {
                      case 'completo':
                        _copyToClipboard(
                          _generateResultsText(),
                          successMessage:
                              '📋 Resultados completos copiados (${_queryResult.length} registros)',
                        );
                        break;
                      case 'limpio':
                        _copyToClipboard(
                          _generateCleanResultsText(),
                          successMessage:
                              '📋 Datos limpios copiados (CSV format)',
                        );
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'completo',
                          child: Row(
                            children: [
                              Icon(Icons.article_outlined),
                              SizedBox(width: 8),
                              Text('Reporte completo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'limpio',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart_outlined),
                              SizedBox(width: 8),
                              Text('Solo datos (CSV)'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : _buildResultConsole(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      db.close();
    } catch (e) {
      // Ignorar errores al cerrar la DB
    }
    _queryController.dispose();
    _verticalScroll.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightPastel,
      appBar: AppBar(
        backgroundColor: AppColors.blackOverlay,
        title: const Text(
          '🛠 Panel de Administración de DB',
          style: TextStyle(color: AppColors.lightPastel),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download,
              size: 26,
              color: AppColors.lightPastel,
            ),
            onPressed: _exportDB,
            tooltip: 'Exportar base de datos',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.lightPastel),
          onPressed: () => Navigator.pushNamed(context, '/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.lightPastel,
          indicatorWeight: 3,
          labelColor: AppColors.lightPastel,
          unselectedLabelColor: AppColors.lightPastel.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.terminal), text: 'Consultas SQL'),
            Tab(
              icon: Icon(Icons.swap_horizontal_circle),
              text: 'Reemplazar DB',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSQLTab(), _buildReplaceDBTab()],
      ),
    );
  }
}
