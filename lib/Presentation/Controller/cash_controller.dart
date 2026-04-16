import 'package:bazarnicole/Presentation/Services/database_service.dart';
import 'package:flutter/foundation.dart';

class CashController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  // Locales
  List<Map<String, dynamic>> stores = [];
  int? selectedStoreId;

  // Métodos de pago
  List<Map<String, dynamic>> paymentMethods = [];

  // Sesión activa
  Map<String, dynamic>? activeSession;

  // Movimientos de la sesión activa
  List<Map<String, dynamic>> movements = [];

  // Resumen financiero
  Map<String, dynamic>? summary;

  bool get hasOpenSession => activeSession != null;
  int? get sessionId => activeSession != null
      ? (activeSession!['id'] as num).toInt()
      : null;

  Future<void> initialize() async {
    if (isLoading) return;
    _setLoading(true);
    try {
      stores = await DatabaseService.getStores();
      paymentMethods = await DatabaseService.getPaymentMethods();
      if (stores.isNotEmpty) {
        selectedStoreId ??= (stores.first['id'] as num).toInt();
        await _loadSession();
      }
    } catch (e) {
      errorMessage = 'Error al inicializar la caja: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectStore(int storeId) async {
    selectedStoreId = storeId;
    activeSession = null;
    movements = [];
    summary = null;
    notifyListeners();
    await _loadSession();
  }

  Future<void> refresh() async {
    if (selectedStoreId == null) return;
    await _loadSession();
  }

  Future<void> _loadSession() async {
    if (selectedStoreId == null) return;
    try {
      activeSession =
          await DatabaseService.getActiveCashSession(selectedStoreId!);
      if (activeSession != null) {
        await _loadMovements();
      } else {
        movements = [];
        summary = null;
      }
    } catch (e) {
      errorMessage = 'Error al cargar sesión: $e';
    }
    notifyListeners();
  }

  Future<void> _loadMovements() async {
    if (sessionId == null) return;
    movements = await DatabaseService.getCashMovements(sessionId!);
    summary = await DatabaseService.getCashSessionSummary(sessionId!);
  }

  Future<void> openSession(double openingAmount) async {
    if (selectedStoreId == null) {
      throw Exception('Selecciona un local');
    }
    _setLoading(true);
    try {
      await DatabaseService.openCashSession(
        storeId: selectedStoreId!,
        openingAmount: openingAmount,
      );
      await _loadSession();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeSession(double closingAmount) async {
    if (sessionId == null) throw Exception('No hay sesión abierta');
    _setLoading(true);
    try {
      await DatabaseService.closeCashSession(
        sessionId: sessionId!,
        closingAmount: closingAmount,
      );
      activeSession = null;
      movements = [];
      summary = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense({
    required double amount,
    required String method,
    String? description,
  }) async {
    if (sessionId == null) throw Exception('No hay sesión de caja abierta');
    await DatabaseService.addCashMovement(
      sessionId: sessionId!,
      type: 'expense',
      amount: amount,
      method: method,
      description: description,
    );
    await _loadMovements();
    notifyListeners();
  }

  Future<void> addIncome({
    required double amount,
    required String method,
    String? description,
  }) async {
    if (sessionId == null) throw Exception('No hay sesión de caja abierta');
    await DatabaseService.addCashMovement(
      sessionId: sessionId!,
      type: 'income',
      amount: amount,
      method: method,
      description: description,
    );
    await _loadMovements();
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
