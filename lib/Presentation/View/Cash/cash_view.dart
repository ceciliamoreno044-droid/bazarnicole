import 'package:bazarnicole/Presentation/Controller/cash_controller.dart';
import 'package:bazarnicole/Presentation/Renders/responsive_helper.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CashView extends StatefulWidget {
  const CashView({super.key});

  @override
  State<CashView> createState() => _CashViewState();
}

class _CashViewState extends State<CashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashController>().initialize();
    });
  }

  Future<void> _showOpenDialog() async {
    final amountController = TextEditingController(text: '0');
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<CashController>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Abrir caja'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Monto inicial'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final amount = double.tryParse(amountController.text.trim()) ?? 0;
        await controller.openSession(amount);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Caja abierta correctamente')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _showMovementDialog(String type) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String? selectedMethod;
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<CashController>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(type == 'income' ? 'Registrar ingreso' : 'Registrar gasto'),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            final methods = controller.paymentMethods;
            selectedMethod ??= methods.isNotEmpty
                ? methods.first['name'] as String
                : 'Efectivo';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Monto'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Método'),
                  items: methods
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m['name'] as String,
                          child: Text(m['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setLocalState(() => selectedMethod = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final amount = double.tryParse(amountController.text.trim()) ?? 0;
        if (type == 'income') {
          await controller.addIncome(
            amount: amount,
            method: selectedMethod ?? 'Efectivo',
            description: descController.text,
          );
        } else {
          await controller.addExpense(
            amount: amount,
            method: selectedMethod ?? 'Efectivo',
            description: descController.text,
          );
        }
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Movimiento registrado')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _showCloseDialog() async {
    final amountController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<CashController>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar caja'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Dinero real al cierre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final amount = double.tryParse(amountController.text.trim()) ?? 0;
        await controller.closeSession(amount);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Caja cerrada correctamente')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        final appBarHeight = ResponsiveHelper.getAppBarHeight(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.blackOverlay,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blackOverlay, AppColors.blackOverlay],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AppBar(
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.whiteOverlay,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: const Text('Caja diaria'),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<CashController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.stores.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = controller.summary ?? {};
          final byMethod = (summary['by_method'] as List?) ?? [];

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  value: controller.selectedStoreId,
                  decoration: const InputDecoration(labelText: 'Local'),
                  items: controller.stores
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: (s['id'] as num).toInt(),
                          child: Text(s['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.selectStore(value);
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.hasOpenSession
                              ? 'Caja abierta'
                              : 'Caja cerrada',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (controller.activeSession != null)
                          Text(
                            'Apertura: \$${((controller.activeSession!['opening_amount'] ?? 0) as num).toStringAsFixed(2)}',
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!controller.hasOpenSession)
                              ElevatedButton.icon(
                                onPressed: _showOpenDialog,
                                icon: const Icon(Icons.lock_open),
                                label: const Text('Abrir caja'),
                              ),
                            if (controller.hasOpenSession) ...[
                              ElevatedButton.icon(
                                onPressed: () => _showMovementDialog('income'),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Ingreso'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showMovementDialog('expense'),
                                icon: const Icon(Icons.remove_circle_outline),
                                label: const Text('Gasto'),
                              ),
                              FilledButton.icon(
                                onPressed: _showCloseDialog,
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Cerrar caja'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.hasOpenSession)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresos: \$${((summary['total_income'] ?? 0) as num).toStringAsFixed(2)}',
                          ),
                          Text(
                            'Egresos: \$${((summary['total_expense'] ?? 0) as num).toStringAsFixed(2)}',
                          ),
                          Text(
                            'Saldo esperado: \$${((summary['expected_balance'] ?? 0) as num).toStringAsFixed(2)}',
                          ),
                          Text(
                            'Caja física: \$${((summary['physical_cash'] ?? 0) as num).toStringAsFixed(2)}',
                          ),
                          Text(
                            'Caja virtual: \$${((summary['virtual_balance'] ?? 0) as num).toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Por método',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          ...byMethod.map(
                            (row) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(row['method']?.toString() ?? '-'),
                              subtitle: Text(
                                'Ingreso: \$${((row['income'] ?? 0) as num).toStringAsFixed(2)} · Egreso: \$${((row['expense'] ?? 0) as num).toStringAsFixed(2)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Movimientos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (controller.movements.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay movimientos registrados'),
                    ),
                  )
                else
                  ...controller.movements.reversed.map(
                    (m) => Card(
                      child: ListTile(
                        leading: Icon(
                          m['type'] == 'income'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: m['type'] == 'income'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          m['description']?.toString().isNotEmpty == true
                              ? m['description'].toString()
                              : (m['type'] == 'income' ? 'Ingreso' : 'Gasto'),
                        ),
                        subtitle: Text('Método: ${m['method']}'),
                        trailing: Text(
                          '\$${((m['amount'] ?? 0) as num).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: m['type'] == 'income'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
