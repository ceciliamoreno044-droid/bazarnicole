// ignore_for_file: file_names

import 'dart:io';

import 'package:bazarnicole/Presentation/Controller/product_management_controller.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ─── Input decoration compartida ────────────────────────────────────────────

InputDecoration _modernInput({
  required String label,
  String? hint,
  String? prefix,
  String? suffix,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefix,
    suffixText: suffix,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: AppColors.lightWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
    hintStyle: TextStyle(color: Colors.grey.shade400),
  );
}

Widget _formSection({required String title, required List<Widget> children}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 12),
      ...children,
    ],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN VIEW
// ════════════════════════════════════════════════════════════════════════════

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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

  // ════════════════ LÓGICA DE NEGOCIO — sin cambios ════════════════════════

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
      _scaffoldKey.currentState?.closeEndDrawer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Producto creado en el catálogo compartido'),
            ],
          ),
          backgroundColor: const Color(0xff1a7f4b),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLogo,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Editar producto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item['uid'] != null)
                                  Text(
                                    'ID: ${item['uid']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cuerpo
                    Flexible(
                      child: Container(
                        color: AppColors.whiteOverlay,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formSection(
                                title: 'Información básica',
                                children: [
                                  TextField(
                                    controller: nameController,
                                    decoration: _modernInput(
                                      label: 'Nombre del producto',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: categoryController,
                                    decoration: _modernInput(
                                      label: 'Categoría',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: skuController,
                                          decoration: _modernInput(
                                            label: 'SKU',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: auxCodeController,
                                          decoration: _modernInput(
                                            label: 'Código auxiliar',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: descriptionController,
                                    maxLines: 3,
                                    decoration: _modernInput(
                                      label: 'Descripción',
                                      hint: 'Describe el producto...',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: tagsController,
                                    decoration: _modernInput(
                                      label: 'Etiquetas',
                                      hint: 'Ej: oferta, nuevo, importado',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(color: Colors.grey.shade100),
                              const SizedBox(height: 24),
                              _formSection(
                                title: 'Precios e impuestos',
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: priceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: _modernInput(
                                            label: 'Precio de venta',
                                            prefix: '\$',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: costPriceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: _modernInput(
                                            label: 'Precio de compra',
                                            prefix: '\$',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: ivaRateController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: _modernInput(
                                            label: 'IVA gubernamental',
                                            suffix: '%',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: profitIvaController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: _modernInput(
                                            label: 'IVA ganancia',
                                            suffix: '%',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(color: Colors.grey.shade100),
                              const SizedBox(height: 24),
                              _formSection(
                                title: 'Local e inventario',
                                children: [
                                  DropdownButtonFormField<int?>(
                                    value: editStoreId,
                                    decoration: _modernInput(
                                      label: 'Local principal',
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
                                        setDialogState(() => editStoreId = v),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: bazarStockController,
                                          keyboardType: TextInputType.number,
                                          decoration: _modernInput(
                                            label: 'Cantidad Bazar',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: tiendaStockController,
                                          keyboardType: TextInputType.number,
                                          decoration: _modernInput(
                                            label: 'Cantidad Tienda',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(color: Colors.grey.shade100),
                              const SizedBox(height: 24),
                              _formSection(
                                title: 'Imágenes del producto',
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      ...editImages.asMap().entries.map((
                                        entry,
                                      ) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(entry.value),
                                                width: 84,
                                                height: 84,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      width: 84,
                                                      height: 84,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey
                                                            .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => setDialogState(() {
                                                  editImages = List.from(
                                                    editImages,
                                                  )..removeAt(entry.key);
                                                }),
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade600,
                                                    shape: BoxShape.circle,
                                                  ),
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
                                          final picked = await picker
                                              .pickMultiImage(imageQuality: 80);
                                          if (picked.isNotEmpty) {
                                            setDialogState(() {
                                              editImages = [
                                                ...editImages,
                                                ...picked.map((x) => x.path),
                                              ];
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            color: AppColors.lightWhite,
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                color: Colors.grey.shade400,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Añadir',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Acciones
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                            ),
                            onPressed: () async {
                              final navigator = Navigator.of(ctx);
                              final messenger = ScaffoldMessenger.of(context);
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (c) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                        backgroundColor: Colors.red.shade600,
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
                                  SnackBar(
                                    content: const Text('Producto eliminado'),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Eliminar'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: AppColors.primaryRed),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.blackOverlay,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              final navigator = Navigator.of(ctx);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final productId = (item['id'] as num).toInt();
                                final stockByStore = <int, int>{};
                                for (final store in controller.stores) {
                                  final sid = (store['id'] as num).toInt();
                                  final storeName = store['name'] as String;
                                  stockByStore[sid] = storeName == 'Bazar'
                                      ? int.tryParse(
                                              bazarStockController.text,
                                            ) ??
                                            0
                                      : int.tryParse(
                                              tiendaStockController.text,
                                            ) ??
                                            0;
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
                                        priceController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0,
                                  costPrice:
                                      double.tryParse(
                                        costPriceController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0,
                                  ivaRate:
                                      double.tryParse(
                                        ivaRateController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0,
                                  profitIva:
                                      double.tryParse(
                                        profitIvaController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
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
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Guardar cambios'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // DRAWER — Nuevo Producto
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildNewProductDrawer(ProductManagementController controller) {
    return Drawer(
      width: 480,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 20,
              16,
              20,
            ),
            color: AppColors.primaryLogo,
            child: Row(
              children: [
                const Icon(
                  Icons.add_box_outlined,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo producto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Agregar al catálogo compartido',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
                  icon: const Icon(Icons.close, color: AppColors.whiteOverlay),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.whiteOverlay,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formSection(
                        title: 'Información básica',
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: _modernInput(
                              label: 'Nombre del producto',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa un nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _categoryController,
                            decoration: _modernInput(
                              label: 'Categoría',
                              hint: 'Escolar, Hogar, Belleza...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _skuController,
                                  decoration: _modernInput(
                                    label: 'SKU (opcional)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _auxCodeController,
                                  decoration: _modernInput(
                                    label: 'Código auxiliar',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: _modernInput(
                              label: 'Descripción',
                              hint: 'Describe el producto...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tagsController,
                            decoration: _modernInput(
                              label: 'Etiquetas',
                              hint: 'oferta, nuevo, importado',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.shade100),
                      const SizedBox(height: 24),
                      _formSection(
                        title: 'Precios e impuestos',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _modernInput(
                                    label: 'Precio de venta',
                                    prefix: '\$',
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
                                  decoration: _modernInput(
                                    label: 'Precio de compra',
                                    prefix: '\$',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ivaRateController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _modernInput(
                                    label: 'IVA gubernamental',
                                    suffix: '%',
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
                                  decoration: _modernInput(
                                    label: 'IVA ganancia',
                                    suffix: '%',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.shade100),
                      const SizedBox(height: 24),
                      _formSection(
                        title: 'Local e inventario inicial',
                        children: [
                          DropdownButtonFormField<int?>(
                            value: _selectedStoreId,
                            decoration: _modernInput(label: 'Local principal'),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bazarController,
                                  keyboardType: TextInputType.number,
                                  decoration: _modernInput(
                                    label: 'Stock Bazar',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _tiendaController,
                                  keyboardType: TextInputType.number,
                                  decoration: _modernInput(
                                    label: 'Stock Tienda',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.shade100),
                      const SizedBox(height: 24),
                      _formSection(
                        title: 'Imágenes del producto',
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ..._imagePaths.asMap().entries.map((entry) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(entry.value),
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _imagePaths = List.from(_imagePaths)
                                            ..removeAt(entry.key);
                                        }),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            shape: BoxShape.circle,
                                          ),
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
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: AppColors.lightWhite,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.grey.shade400,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Añadir',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.whiteOverlay,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackOverlay,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: controller.isLoading ? null : _saveProduct,
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  controller.isLoading ? 'Guardando...' : 'Guardar producto',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // WIDGETS UI
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    int index = 0,
  }) {
    return Expanded(
      child:
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLogo,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: 400.ms,
              )
              .slideY(
                begin: 0.15,
                end: 0,
                delay: Duration(milliseconds: 100 * index),
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
    );
  }

  Widget _buildStockBadge(int stock) {
    final Color badgeColor;
    final String emoji;
    if (stock <= 5) {
      badgeColor = const Color(0xFFFFE5E5);
      emoji = '🔴';
    } else if (stock <= 20) {
      badgeColor = const Color(0xFFFFF8E1);
      emoji = '🟡';
    } else {
      badgeColor = const Color(0xFFE8F5E9);
      emoji = '🟢';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $stock uds.',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.lightWhite,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, int index) {
    final firstImage =
        item['images'] != null && (item['images'] as String).isNotEmpty
        ? (item['images'] as String).split(',').first
        : null;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final totalStock =
        ((item['stock_bazar'] as num?)?.toInt() ?? 0) +
        ((item['stock_tienda'] as num?)?.toInt() ?? 0);
    final category = item['category']?.toString() ?? '';
    final sku = item['sku']?.toString() ?? '';

    return _HoverCard(
          onTap: () => _showEditProductDialog(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: firstImage != null
                      ? Image.file(
                          File(firstImage),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '📦 $category',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (sku.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: $sku',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildStockBadge(totalStock),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(
                            color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showEditProductDialog(item),
                        child: const Text(
                          'Editar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * (index % 20)),
          duration: 300.ms,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          delay: Duration(milliseconds: 40 * (index % 20)),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.lightWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 44,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún no tienes productos registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer producto para comenzar.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                '+ Crear producto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 768) return 3;
    return 2;
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductManagementController>(
      builder: (context, controller, _) {
        final totalProducts = controller.products.length;
        final totalStock = controller.products.fold<int>(
          0,
          (sum, p) =>
              sum +
              ((p['stock_bazar'] as num?)?.toInt() ?? 0) +
              ((p['stock_tienda'] as num?)?.toInt() ?? 0),
        );
        final inventoryValue = controller.products.fold<double>(0, (sum, p) {
          final cost = (p['cost_price'] as num?)?.toDouble() ?? 0;
          final stock =
              ((p['stock_bazar'] as num?)?.toInt() ?? 0) +
              ((p['stock_tienda'] as num?)?.toInt() ?? 0);
          return sum + cost * stock;
        });

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF6F7F9),
          endDrawer: _buildNewProductDrawer(controller),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.blackOverlay,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppColors.whiteOverlay,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Productos',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.whiteOverlay,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestiona inventario y stock entre todos los locales.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.whiteOverlay,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openEndDrawer(),
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: AppColors.primaryLogo,
                            ),
                            label: const Text(
                              'Nuevo Producto',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLogo,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Métricas
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        _buildMetricCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Productos',
                          value: '$totalProducts',
                          color: AppColors.primaryBlue,
                          index: 0,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          icon: Icons.warehouse_outlined,
                          title: 'Stock Total',
                          value: '$totalStock',
                          color: const Color(0xFF1a7f4b),
                          index: 1,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          icon: Icons.payments_outlined,
                          title: 'Valor Inventario',
                          value: inventoryValue >= 1000
                              ? '\$${(inventoryValue / 1000).toStringAsFixed(1)}k'
                              : '\$${inventoryValue.toStringAsFixed(0)}',
                          color: AppColors.primaryLogo,
                          index: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Buscador
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: SizedBox(
                      height: 56,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade400,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.loadCatalog();
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey.shade400,
                                    size: 18,
                                  ),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          controller.loadCatalog(search: value);
                        },
                      ),
                    ),
                  ),
                ),

                // Error
                if (controller.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Catálogo
                if (controller.isLoading && controller.products.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (controller.products.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = controller.products[index];
                        return _buildProductCard(item, index);
                      }, childCount: controller.products.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount(context),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.62,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HOVER CARD
// ════════════════════════════════════════════════════════════════════════════

class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.10 : 0.05),
                blurRadius: _hovered ? 20 : 10,
                offset: Offset(0, _hovered ? 8 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
