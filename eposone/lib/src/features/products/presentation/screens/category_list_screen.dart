import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: '#4CAF50');

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // Escuchar cambios del notifier para refrescar lista
    ref.listen(categoryNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ref.invalidate(categoriesProvider),
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return _EmptyState(onAdd: () => _showForm(context));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onEdit: () => _showForm(context, category: category),
                onDelete: () => _confirmDelete(context, category),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }

  void _showForm(BuildContext context, {Category? category}) {
    _nameController.text = category?.name ?? '';
    _colorController.text = category?.color ?? '#4CAF50';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category == null ? 'Nueva Categoría' : 'Editar Categoría',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Bebidas',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: 'Color (hex)',
                hintText: '#4CAF50',
                prefixIcon: const Icon(Icons.palette),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ColorChip(color: '#4CAF50', controller: _colorController),
                _ColorChip(color: '#2196F3', controller: _colorController),
                _ColorChip(color: '#FF9800', controller: _colorController),
                _ColorChip(color: '#f44336', controller: _colorController),
                _ColorChip(color: '#9C27B0', controller: _colorController),
                _ColorChip(color: '#009688', controller: _colorController),
                _ColorChip(color: '#795548', controller: _colorController),
                _ColorChip(color: '#607D8B', controller: _colorController),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _save(category),
                icon: const Icon(Icons.save),
                label: Text(category == null ? 'Crear categoría' : 'Guardar cambios'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _save(Category? existing) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    Category category;
    if (existing != null) {
      category = existing.copyWith(
        name: name,
        color: _colorController.text.trim(),
        updatedAt: DateTime.now(),
      ).markAsModified();
    } else {
      category = Category.create(
        name: name,
        color: _colorController.text.trim(),
      );
    }

    ref.read(categoryNotifierProvider.notifier).saveCategory(category);
    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.name}"? Los productos asociados quedarán sin categoría.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(categoryNotifierProvider.notifier).deleteCategory(category.localId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.35,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Editar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Eliminar',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(
              Icons.folder,
              color: _isLightColor(color) ? Colors.black : Colors.white,
            ),
          ),
          title: Text(category.name),
          subtitle: Text('${category.color ?? 'Sin color'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onEdit,
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  bool _isLightColor(Color color) {
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance > 0.5;
  }
}

class _ColorChip extends StatefulWidget {
  final String color;
  final TextEditingController controller;

  const _ColorChip({required this.color, required this.controller});

  @override
  State<_ColorChip> createState() => _ColorChipState();
}

class _ColorChipState extends State<_ColorChip> {
  @override
  Widget build(BuildContext context) {
    final parsed = _parseColor(widget.color);

    return GestureDetector(
      onTap: () {
        widget.controller.text = widget.color;
        setState(() {});
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: parsed,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.controller.text == widget.color ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Sin categorías', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Organiza tus productos en categorías',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Agregar categoría'),
          ),
        ],
      ),
    );
  }
}