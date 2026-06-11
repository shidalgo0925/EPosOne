import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/customers/presentation/providers/customer_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = _searchQuery.isEmpty
        ? ref.watch(customersListProvider)
        : ref.watch(customersSearchProvider(_searchQuery));

    ref.listen(customerNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ref.invalidate(customersListProvider),
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono o documento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return _EmptyState(
              isSearch: _searchQuery.isNotEmpty,
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return _CustomerCard(
                customer: customer,
                onTap: () => context.push('/customers/${customer.localId}/edit'),
                onDelete: () => _confirmDelete(context, customer),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(customerNotifierProvider.notifier).deleteCustomer(customer.localId);
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

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = customer.name.isNotEmpty
        ? customer.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().substring(0, customer.name.split(' ').length > 1 ? 2 : 1)
        : '?';

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
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
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(customer.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.phone != null && customer.phone!.isNotEmpty)
                Text('📞 ${customer.phone}'),
              if (customer.document != null && customer.document!.isNotEmpty)
                Text('🪪 ${customer.document}'),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final VoidCallback onClearSearch;

  const _EmptyState({required this.isSearch, required this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No se encontraron clientes' : 'Sin clientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Intenta con otra búsqueda'
                : 'Agrega tu primer cliente con el botón +',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          if (isSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }
}