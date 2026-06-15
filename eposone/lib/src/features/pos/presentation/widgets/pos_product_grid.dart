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
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Sin productos'));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
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

  static const _fallbackColors = [
    EposBrand.orange,
    EposBrand.navy,
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFC62828),
  ];

  Color _tileColor(String name) => _fallbackColors[name.hashCode.abs() % _fallbackColors.length];

  @override
  Widget build(BuildContext context) {
    final out = trackInventory && product.stock <= 0;
    final hasImage = _hasImage(product.imagePath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: out ? null : onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              _ProductImage(imagePath: product.imagePath!)
            else
              ColoredBox(
                color: out ? EposBrand.divider : _tileColor(product.name),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: out ? EposBrand.textSecondary : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
            if (hasImage)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: out ? Colors.white70 : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            if (out)
              Container(color: Colors.white.withValues(alpha: 0.45)),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$symbol${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasImage(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}

class _ProductImage extends StatelessWidget {
  final String imagePath;

  const _ProductImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Image.file(File(imagePath), fit: BoxFit.cover);
  }
}
