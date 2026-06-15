import 'package:bazarnicole/Presentation/Controller/customers_controller.dart';
import 'package:bazarnicole/Presentation/Utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersController>().initialize();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<CustomersController>();
    try {
      await controller.createCustomer(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        notes: _notesController.text,
      );

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _notesController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente registrado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteOverlay,
      appBar: AppBar(
        backgroundColor: AppColors.primaryLogo,
        foregroundColor: Colors.white,
        title: const Text('Clientes · CRM'),
      ),
      body: Consumer<CustomersController>(
        builder: (context, controller, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              final formPanel = Card(
                color: AppColors.lightGray,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Registrar cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Ingresa el nombre'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Notas',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saveCustomer,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Guardar cliente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final listPanel = Card(
                color: AppColors.lightGray,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Buscar cliente por nombre, correo o teléfono',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.loadCustomers();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          controller.loadCustomers(searchValue: value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child:
                            controller.isLoading && controller.customers.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.separated(
                                itemCount: controller.customers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final customer = controller.customers[index];
                                  final isSelected =
                                      controller.selectedCustomer?['id'] ==
                                      customer['id'];
                                  return ListTile(
                                    selected: isSelected,
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person_outline),
                                    ),
                                    title: Text(
                                      customer['name']?.toString() ?? '',
                                    ),
                                    subtitle: Text(
                                      '${customer['phone'] ?? 'Sin teléfono'} · ${customer['email'] ?? 'Sin correo'}',
                                    ),
                                    onTap: () =>
                                        controller.selectCustomer(customer),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );

              final historyPanel = SizedBox(
                width: isWide ? 340 : double.infinity,
                child: Card(
                  color: AppColors.lightGray,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ver historial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (controller.selectedCustomer == null)
                          const Text(
                            'Selecciona un cliente para ver sus compras.',
                          )
                        else ...[
                          Text(
                            controller.selectedCustomer!['name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 260,
                            child: controller.history.isEmpty
                                ? const Text('Todavía no registra ventas.')
                                : ListView.separated(
                                    itemCount: controller.history.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      final sale = controller.history[index];
                                      final date = DateTime.tryParse(
                                        sale['date']?.toString() ?? '',
                                      );
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text('Venta #${sale['id']}'),
                                        subtitle: Text(
                                          '${sale['store_name']} · ${date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : ''}',
                                        ),
                                        trailing: Text(
                                          '\$${((sale['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );

              return Padding(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 320, child: formPanel)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
                          const SizedBox(width: 16),
                          Expanded(child: listPanel)
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 400.ms, curve: Curves.easeOut),
                          const SizedBox(width: 16),
                          historyPanel
                              .animate()
                              .fadeIn(delay: 250.ms, duration: 400.ms)
                              .slideX(begin: 0.1, end: 0, delay: 250.ms, duration: 400.ms, curve: Curves.easeOut),
                        ],
                      )
                    : ListView(
                        children: [
                          formPanel.animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
                          const SizedBox(height: 16),
                          SizedBox(height: 340, child: listPanel.animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 400.ms, curve: Curves.easeOut)),
                          const SizedBox(height: 16),
                          historyPanel.animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, delay: 250.ms, duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
