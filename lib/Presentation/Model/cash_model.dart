/// Denominaciones disponibles en USD (Ecuador)
class CashDenomination {
  final double value;
  final String label;
  final bool isCoin; // false = billete

  const CashDenomination({
    required this.value,
    required this.label,
    required this.isCoin,
  });
}

/// Catálogo de denominaciones (billetes y monedas USD)
class CashDenominations {
  static const List<CashDenomination> bills = [
    CashDenomination(value: 100, label: '\$100', isCoin: false),
    CashDenomination(value: 50, label: '\$50', isCoin: false),
    CashDenomination(value: 20, label: '\$20', isCoin: false),
    CashDenomination(value: 10, label: '\$10', isCoin: false),
    CashDenomination(value: 5, label: '\$5', isCoin: false),
    CashDenomination(value: 1, label: '\$1', isCoin: false),
  ];

  static const List<CashDenomination> coins = [
    CashDenomination(value: 1.00, label: '\$1.00', isCoin: true),
    CashDenomination(value: 0.50, label: '\$0.50', isCoin: true),
    CashDenomination(value: 0.25, label: '\$0.25', isCoin: true),
    CashDenomination(value: 0.10, label: '\$0.10', isCoin: true),
    CashDenomination(value: 0.05, label: '\$0.05', isCoin: true),
    CashDenomination(value: 0.01, label: '\$0.01', isCoin: true),
  ];

  static List<CashDenomination> get all => [...bills, ...coins];
}

/// Entrada de una denominación: cuántos billetes/monedas de cierto valor
class DenominationEntry {
  final CashDenomination denomination;
  int quantity;

  DenominationEntry({required this.denomination, this.quantity = 0});

  double get subtotal => denomination.value * quantity;

  Map<String, dynamic> toMap(int sessionId, String moment) => {
        'session_id': sessionId,
        'value': denomination.value,
        'label': denomination.label,
        'is_coin': denomination.isCoin ? 1 : 0,
        'quantity': quantity,
        'subtotal': subtotal,
        'moment': moment, // 'open' | 'close'
        'created_at': DateTime.now().toIso8601String(),
      };

  static DenominationEntry fromMap(Map<String, dynamic> map) {
    final value = (map['value'] as num).toDouble();
    final isCoin = (map['is_coin'] as int) == 1;
    final denom = CashDenominations.all.firstWhere(
      (d) => d.value == value && d.isCoin == isCoin,
      orElse: () => CashDenomination(
        value: value,
        label: map['label'] as String,
        isCoin: isCoin,
      ),
    );
    return DenominationEntry(
      denomination: denom,
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}

/// Resumen de caja: total en billetes, total en monedas, gran total
class CashBreakdown {
  final List<DenominationEntry> entries;
  final String moment; // 'open' | 'close'

  const CashBreakdown({required this.entries, required this.moment});

  double get totalBills => entries
      .where((e) => !e.denomination.isCoin && e.quantity > 0)
      .fold(0, (sum, e) => sum + e.subtotal);

  double get totalCoins => entries
      .where((e) => e.denomination.isCoin && e.quantity > 0)
      .fold(0, (sum, e) => sum + e.subtotal);

  double get grandTotal => totalBills + totalCoins;
}
