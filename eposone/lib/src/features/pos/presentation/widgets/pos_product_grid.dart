import 'dart:io';

import 'package:flutter/material.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

class PosProductGrid extends StatelessWidget {
  final List<Product> products;
  final String symbol;
  final bool trackInventory;
  final ValueChanged<Product> onProductTap;
  final int crossAxisCount;

  const PosProductGrid({
    super.key,
    required this.products,
    required this.symbol,
    required this.trackInventory,
    required this.onProductTap,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Sin productos'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductTile(
        product: products[i],
        symbol: symbol,
        trackInventory: trackInventory,
        onTap: () => onProductTap(products[i]),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final String symbol;
  final bool trackInventory;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.symbol,
    required this.trackInventory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final out = trackInventory && product.stock <= 0;

    return Material(
      color: out ? EposBrand.background : EposBrand.surface,
      elevation: out ? 0 : 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: out ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: out ? EposBrand.divider : EposBrand.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: _ProductImage(imagePath: product.imagePath, outOfStock: out),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: out ? EposBrand.textSecondary : EposBrand.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (trackInventory)
                        Text(
                          out ? 'Sin stock' : 'Stock: ${product.stock.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: out ? Colors.red.shade400 : EposBrand.textSecondary,
                          ),
                        ),
                      Text(
                        '$symbol${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: out ? EposBrand.textSecondary : EposBrand.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imagePath;
  final bool outOfStock;

  const _ProductImage({this.imagePath, required this.outOfStock});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            if (outOfStock)
              Container(color: Colors.white.withValues(alpha: 0.55)),
          ],
        );
      }
    }

    return Container(
      color: EposBrand.background,
      child: Icon(
        Icons.inventory_2_outlined,
        size: 36,
        color: outOfStock ? EposBrand.textSecondary : EposBrand.navy.withValues(alpha: 0.35),
      ),
    );
  }
}
