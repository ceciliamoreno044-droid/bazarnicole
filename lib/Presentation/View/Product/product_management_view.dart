import 'dart:io';

import 'package:bazarnicole/Presentation/Controller/product_management_controller.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProductManagementView extends StatefulWidget {
  const ProductManagementView({super.key});

  @override
  State<ProductManagementView> createState() => _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _auxCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _priceController = TextEditingController(text: '0.00');
  final _costPriceController = TextEditingController(text: '0.00');
  final _ivaRateController = TextEditingController(text: '0.00');
  final _profitIvaController = TextEditingController(text: '0.00');
  final _bazarController = TextEditingController(text: '0');
  final _tiendaController = TextEditingController(text: '0');
  final _searchController = TextEditingController();
  int? _selectedStoreId;
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductManagementController>().initialize();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _auxCodeController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _ivaRateController.dispose();
    _profitIvaController.dispose();
    _bazarController.dispose();
    _tiendaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _imagePaths = [..._imagePaths, ...picked.map((x) => x.path)];
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProductManagementController>();
    final stocks = <int, int>{};

    for (final store in controller.stores) {
      final id = (store['id'] as num).toInt();
      final name = store['name'] as String;
      final source = name == 'Bazar'
          ? _bazarController.text
          : _tiendaController.text;
      stocks[id] = int.tryParse(source) ?? 0;
    }

    try {
      await controller.createProduct(
        name: _nameController.text,
        category: _categoryController.text,
        price: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0,
        costPrice:
            double.tryParse(_costPriceController.text.replaceAll(',', '.')) ??
            0,
        ivaRate:
            double.tryParse(_ivaRateController.text.replaceAll(',', '.')) ?? 0,
        profitIva:
            double.tryParse(_profitIvaController.text.replaceAll(',', '.')) ??
            0,
        sku: _skuController.text,
        auxCode: _auxCodeController.text,
        description: _descriptionController.text,
        tags: _tagsController.text,
        storeId: _selectedStoreId,
        images: _imagePaths,
        initialStock: stocks,
      );

      _nameController.clear();
      _categoryController.clear();
      _skuController.clear();
      _auxCodeController.clear();
      _descriptionController.clear();
      _tagsController.clear();
      _priceController.text = '0.00';
      _costPriceController.text = '0.00';
      _ivaRateController.text = '0.00';
      _profitIvaController.text = '0.00';
      _bazarController.text = '0';
      _tiendaController.text = '0';
      setState(() {
        _selectedStoreId = null;
        _imagePaths = [];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto creado en el catálogo compartido'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showEditProductDialog(Map<String, dynamic> item) async {
    final controller = context.read<ProductManagementController>();
    final nameController = TextEditingController(
      text: item['name']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: item['category']?.toString() ?? '',
    );
    final skuController = TextEditingController(
      text: item['sku']?.toString() ?? '',
    );
    final auxCodeController = TextEditingController(
      text: item['aux_code']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: item['description']?.toString() ?? '',
    );
    final tagsController = TextEditingController(
      text: item['tags']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: ((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    final costPriceController = TextEditingController(
      text: ((item['cost_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    final ivaRateController = TextEditingController(
      text: ((item['iva_rate'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    final profitIvaController = TextEditingController(
      text: ((item['profit_iva'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );

    int? editStoreId = item['store_id'] != null
        ? (item['store_id'] as num).toInt()
        : null;
    List<String> editImages =
        item['images'] != null && (item['images'] as String).isNotEmpty
        ? (item['images'] as String).split(',')
        : [];
    final bazarStockController = TextEditingController(
      text: ((item['stock_bazar'] as num?)?.toInt() ?? 0).toString(),
    );
    final tiendaStockController = TextEditingController(
      text: ((item['stock_tienda'] as num?)?.toInt() ?? 0).toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Editar producto'),
                  if (item['uid'] != null)
                    Text(
                      'ID: ${item['uid']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Categoría
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // SKU + Código auxiliar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: skuController,
                              decoration: const InputDecoration(
                                labelText: 'SKU',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: auxCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Código auxiliar',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Descripción
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Etiquetas
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas',
                          hintText: 'Ej: oferta, nuevo, importado',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Precio venta + Precio compra
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Precio de venta',
                                prefixText: '\$',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: costPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Precio de compra',
                                prefixText: '\$',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // IVA gubernamental + IVA ganancia
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ivaRateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'IVA gubernamental %',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: profitIvaController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'IVA ganancia %',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Local
                      DropdownButtonFormField<int?>(
                        value: editStoreId,
                        decoration: const InputDecoration(
                          labelText: 'Local principal',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sin asignar'),
                          ),
                          ...controller.stores.map((s) {
                            final id = (s['id'] as num).toInt();
                            return DropdownMenuItem<int?>(
                              value: id,
                              child: Text(s['name'] as String),
                            );
                          }),
                        ],
                        onChanged: (v) => setDialogState(() => editStoreId = v),
                      ),
                      const SizedBox(height: 12),
                      // Cantidades por local
                      const Text(
                        'Cantidad en inventario',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bazarStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad Bazar',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: tiendaStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad Tienda',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Imágenes
                      const Text(
                        'Imágenes del producto',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...editImages.asMap().entries.map((entry) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(entry.value),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() {
                                      editImages = List.from(editImages)
                                        ..removeAt(entry.key);
                                    }),
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red.shade600,
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickMultiImage(
                                imageQuality: 80,
                              );
                              if (picked.isNotEmpty) {
                                setDialogState(() {
                                  editImages = [
                                    ...editImages,
                                    ...picked.map((x) => x.path),
                                  ];
                                });
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('Eliminar producto'),
                        content: Text(
                          '¿Seguro que deseas eliminar "${item['name']}"?\n\nSe eliminará el producto y todo su inventario. Esta acción no se puede deshacer.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      await controller.deleteProduct(
                        (item['id'] as num).toInt(),
                      );
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Producto eliminado')),
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
                  child: const Text('Eliminar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final productId = (item['id'] as num).toInt();
                      // Construir mapa de stock por local
                      final stockByStore = <int, int>{};
                      for (final store in controller.stores) {
                        final sid = (store['id'] as num).toInt();
                        final storeName = store['name'] as String;
                        stockByStore[sid] = storeName == 'Bazar'
                            ? int.tryParse(bazarStockController.text) ?? 0
                            : int.tryParse(tiendaStockController.text) ?? 0;
                      }
                      await controller.updateProductWithStock(
                        productId: productId,
                        name: nameController.text,
                        category: categoryController.text,
                        sku: skuController.text,
                        auxCode: auxCodeController.text,
                        description: descriptionController.text,
                        tags: tagsController.text,
                        price:
                            double.tryParse(
                              priceController.text.replaceAll(',', '.'),
                            ) ??
                            0,
                        costPrice:
                            double.tryParse(
                              costPriceController.text.replaceAll(',', '.'),
                            ) ??
                            0,
                        ivaRate:
                            double.tryParse(
                              ivaRateController.text.replaceAll(',', '.'),
                            ) ??
                            0,
                        profitIva:
                            double.tryParse(
                              profitIvaController.text.replaceAll(',', '.'),
                            ) ??
                            0,
                        storeId: editStoreId,
                        images: editImages,
                        stockByStore: stockByStore,
                      );
                      if (!mounted) return;
                      navigator.pop();
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
                  child: const Text('Guardar cambios'),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryLogo,
        foregroundColor: Colors.white,
        title: const Text('Productos compartidos'),
      ),
      body: Consumer<ProductManagementController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Un solo sistema, múltiples locales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Los productos son únicos y el stock se controla por Bazar y Tienda en la misma base de datos.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nuevo producto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nombre
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa un nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Categoría
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              hintText: 'Ejemplo: Escolar, Hogar, Belleza',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // SKU + Código auxiliar
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _skuController,
                                  decoration: const InputDecoration(
                                    labelText: 'SKU (opcional)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _auxCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Código auxiliar',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Descripción
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Etiquetas
                          TextFormField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                              labelText: 'Etiquetas',
                              hintText: 'Ej: oferta, nuevo, importado',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Precio venta + Precio compra
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Precio de venta',
                                    prefixText: '\$',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _costPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Precio de compra',
                                    prefixText: '\$',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // IVA gubernamental + IVA ganancia
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ivaRateController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'IVA gubernamental %',
                                    suffixText: '%',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _profitIvaController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'IVA ganancia %',
                                    suffixText: '%',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Local principal
                          DropdownButtonFormField<int?>(
                            value: _selectedStoreId,
                            decoration: const InputDecoration(
                              labelText: 'Local principal',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin asignar'),
                              ),
                              ...controller.stores.map((s) {
                                final id = (s['id'] as num).toInt();
                                return DropdownMenuItem<int?>(
                                  value: id,
                                  child: Text(s['name'] as String),
                                );
                              }),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedStoreId = v),
                          ),
                          const SizedBox(height: 16),
                          // Stock inicial por local
                          const Text(
                            'Stock inicial por local',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bazarController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Bazar',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _tiendaController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Tienda',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Imágenes del producto
                          const Text(
                            'Imágenes del producto',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._imagePaths.asMap().entries.map((entry) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(entry.value),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _imagePaths = List.from(_imagePaths)
                                            ..removeAt(entry.key);
                                        }),
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.red.shade600,
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              InkWell(
                                onTap: _pickImages,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : _saveProduct,
                              icon: const Icon(Icons.add_box_outlined),
                              label: const Text('Guardar producto'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar en el catálogo',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              controller.loadCatalog();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    controller.loadCatalog(search: value);
                  },
                ),
                const SizedBox(height: 16),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (controller.isLoading && controller.products.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (controller.products.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay productos registrados todavía.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = controller.products[index];
                      final firstImage =
                          item['images'] != null &&
                              (item['images'] as String).isNotEmpty
                          ? (item['images'] as String).split(',').first
                          : null;
                      final price = (item['price'] as num?)?.toDouble() ?? 0;
                      final costPrice =
                          (item['cost_price'] as num?)?.toDouble() ?? 0;
                      final ivaRate =
                          (item['iva_rate'] as num?)?.toDouble() ?? 0;
                      return Card(
                        child: ListTile(
                          leading: firstImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(firstImage),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => CircleAvatar(
                                      backgroundColor: Colors.indigo.shade50,
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.indigo.shade50,
                                  child: const Icon(Icons.inventory_2_outlined),
                                ),
                          title: Text(item['name']?.toString() ?? ''),
                          onTap: () => _showEditProductDialog(item),
                          subtitle: Text(
                            'SKU: ${item['sku']} · ${item['category']}'
                            '\nVenta: \$${price.toStringAsFixed(2)} · Compra: \$${costPrice.toStringAsFixed(2)} · IVA: ${ivaRate.toStringAsFixed(1)}%'
                            '${item['aux_code'] != null && item['aux_code'].toString().isNotEmpty ? ' · Aux: ${item['aux_code']}' : ''}'
                            '${item['store_name'] != null && (item['store_name'] as String).isNotEmpty ? ' · Local: ${item['store_name']}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Bazar: ${item['stock_bazar']}'),
                              Text('Tienda: ${item['stock_tienda']}'),
                              Text(
                                'Total: ${item['total_stock']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate()
                        .fadeIn(delay: Duration(milliseconds: 40 * (index % 20)), duration: 300.ms)
                        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 40 * (index % 20)), duration: 300.ms, curve: Curves.easeOut);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
