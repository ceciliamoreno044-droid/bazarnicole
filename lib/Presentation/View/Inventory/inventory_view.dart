import 'package:bazarnicole/Presentation/Controller/inventory_controller.dart';
import 'package:bazarnicole/Presentation/Renders/responsive_helper.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEditStockDialog(Map<String, dynamic> item) async {
    final controller = context.read<InventoryController>();
    final stockController = TextEditingController(
      text: (((item['stock'] as num?)?.toInt()) ?? 0).toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Actualizar stock de ${item['name']}'),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nuevo stock',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await controller.updateStock(
                  productId: (item['product_id'] as num).toInt(),
                  stock: int.tryParse(stockController.text) ?? 0,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTransferDialog(Map<String, dynamic> item) async {
    final controller = context.read<InventoryController>();
    if (controller.selectedStoreId == null || controller.stores.length < 2) {
      return;
    }

    final qtyController = TextEditingController(text: '1');
    int fromStoreId = controller.selectedStoreId!;
    int toStoreId =
        (controller.stores.firstWhere(
                  (store) => (store['id'] as num).toInt() != fromStoreId,
                )['id']
                as num)
            .toInt();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Transferir entre locales'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['name']?.toString() ?? ''),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: fromStoreId,
                    decoration: const InputDecoration(
                      labelText: 'Origen',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.stores.map((store) {
                      final id = (store['id'] as num).toInt();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(store['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        fromStoreId = value;
                        if (toStoreId == fromStoreId) {
                          toStoreId =
                              (controller.stores.firstWhere(
                                        (store) =>
                                            (store['id'] as num).toInt() !=
                                            fromStoreId,
                                      )['id']
                                      as num)
                                  .toInt();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: toStoreId,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.stores
                        .where(
                          (store) =>
                              (store['id'] as num).toInt() != fromStoreId,
                        )
                        .map((store) {
                          final id = (store['id'] as num).toInt();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(store['name'].toString()),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => toStoreId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(this.context);

                    try {
                      await controller.transferStock(
                        productId: (item['product_id'] as num).toInt(),
                        fromStoreId: fromStoreId,
                        toStoreId: toStoreId,
                        quantity: int.tryParse(qtyController.text) ?? 0,
                      );
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Transferencia registrada'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Transferir'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  child: Text(
                    'Inventario por local',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteOverlay,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<InventoryController>(
        builder: (context, controller, _) {
          final selectedStoreId = controller.selectedStoreId;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Controla el stock del Bazar y la Tienda desde una sola base de datos.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (controller.stores.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedStoreId,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.stores.map((store) {
                      final id = (store['id'] as num).toInt();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(store['name'].toString()),
                      );
                    }).toList(),
                    onChanged: controller.selectStore,
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar producto',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              controller.updateSearch('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    controller.updateSearch(value);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(
                      title: 'Productos',
                      value: controller.totalProducts.toString(),
                    ),
                    _SummaryCard(
                      title: 'Unidades',
                      value: controller.totalUnits.toString(),
                    ),
                    _SummaryCard(
                      title: 'Bajo stock',
                      value: controller.lowStockCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: controller.isLoading && controller.inventory.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : controller.inventory.isEmpty
                      ? const Center(
                          child: Text('No hay productos para este local'),
                        )
                      : ListView.separated(
                          itemCount: controller.inventory.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = controller.inventory[index];
                            final stock =
                                ((item['stock'] as num?)?.toInt() ?? 0);
                            final stockColor = stock <= 2
                                ? Colors.red
                                : Colors.green;

                            return Card(
                              child: ListTile(
                                title: Text(item['name']?.toString() ?? ''),
                                subtitle: Text(
                                  'SKU: ${item['sku']} · Categoría: ${item['category']}',
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: stockColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Text(
                                    stock.toString(),
                                    style: TextStyle(
                                      color: stockColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar stock',
                                      onPressed: () =>
                                          _showEditStockDialog(item),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Transferir',
                                      onPressed: () =>
                                          _showTransferDialog(item),
                                      icon: const Icon(Icons.swap_horiz),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
