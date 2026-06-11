import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController();

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _allowDecimalQty = false;

  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
    if (_isEdit) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    final product = await ref.read(productByIdProvider(widget.productId!).future);
    if (product != null && mounted) {
      _nameController.text = product.name;
      _barcodeController.text = product.barcode ?? '';
      _skuController.text = product.sku ?? '';
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.price.toString();
      _costController.text = product.cost?.toString() ?? '';
      _stockController.text = product.stock.toString();
      _minStockController.text = product.minStockAlert?.toString() ?? '';
      _selectedCategoryId = product.categoryId;
      _isActive = product.isActive;
      _allowDecimalQty = product.allowDecimalQty;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: _isLoading && _isEdit
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre *',
                      hint: 'Ej: Coca Cola 600ml',
                      prefixIcon: Icons.label,
                      validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Código de barras + SKU
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _barcodeController,
                            label: 'Código de barras',
                            hint: 'Escanea o escribe',
                            prefixIcon: Icons.qr_code,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _skuController,
                            label: 'SKU',
                            hint: 'Referencia interna',
                            prefixIcon: Icons.tag,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Descripción',
                      hint: 'Detalles del producto...',
                      prefixIcon: Icons.description,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Precio + Costo
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Precio de venta *',
                            hint: '0.00',
                            prefixIcon: Icons.sell,
                            prefixText: '\$ ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              final n = double.tryParse(v.replaceAll(',', ''));
                              if (n == null || n < 0) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _costController,
                            label: 'Costo',
                            hint: '0.00',
                            prefixIcon: Icons.shopping_bag,
                            prefixText: '\$ ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock + Stock mínimo
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            label: 'Stock inicial *',
                            hint: '0',
                            prefixIcon: Icons.inventory_2,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              if (double.tryParse(v) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _minStockController,
                            label: 'Stock mínimo',
                            hint: 'Alerta',
                            prefixIcon: Icons.warning_amber,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    categoriesAsync.when(
                      data: (categories) => _buildCategoryDropdown(categories),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error cargando categorías'),
                    ),
                    const SizedBox(height: 16),

                    // Switches
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Producto activo'),
                              subtitle: const Text('Visible en catálogo y POS'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Permitir cantidad decimal'),
                              subtitle: const Text('Ej: 1.5 kg, 0.75 litros'),
                              value: _allowDecimalQty,
                              onChanged: (v) => setState(() => _allowDecimalQty = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isEdit ? 'Guardar cambios' : 'Crear producto'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<String?>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.folder),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      hint: const Text('Sin categoría'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Sin categoría')),
        ...categories.map((cat) => DropdownMenuItem(
              value: cat.localId,
              child: Text(cat.name),
            )),
      ],
      onChanged: (value) => setState(() => _selectedCategoryId = value),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text.replaceAll(',', ''));
      final cost = _costController.text.isEmpty
          ? null
          : double.tryParse(_costController.text.replaceAll(',', ''));
      final stock = double.parse(_stockController.text);
      final minStock = _minStockController.text.isEmpty
          ? null
          : double.tryParse(_minStockController.text);

      Product product;

      if (_isEdit) {
        final existing = await ref.read(productByIdProvider(widget.productId!).future);
        if (existing == null) throw Exception('Producto no encontrado');

        product = existing.copyWith(
          name: _nameController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          price: price,
          cost: cost,
          stock: stock,
          categoryId: _selectedCategoryId,
          isActive: _isActive,
          allowDecimalQty: _allowDecimalQty,
          minStockAlert: minStock,
          updatedAt: DateTime.now(),
        ).markAsModified();
      } else {
        product = Product.create(
          name: _nameController.text.trim(),
          price: price,
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          cost: cost,
          stock: stock,
          categoryId: _selectedCategoryId,
          allowDecimalQty: _allowDecimalQty,
          minStockAlert: minStock,
        );
      }

      await ref.read(productNotifierProvider.notifier).saveProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Producto actualizado' : 'Producto creado'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}