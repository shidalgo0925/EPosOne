import 'dart:io';

import 'package:flutter/material.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/utils/business_logo_storage.dart';

/// Logo centrado para preview de recibo / encabezado (sin hueco si no hay archivo).
class BusinessLogoHeader extends StatelessWidget {
  const BusinessLogoHeader({
    super.key,
    required this.logoPath,
    this.maxHeight = 72,
    this.maxWidth = 160,
  });

  final String? logoPath;
  final double maxHeight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!BusinessLogoStorage.exists(logoPath)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: maxWidth,
          ),
          child: Image.file(
            File(logoPath!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Placeholder visual cuando aún no hay logo (solo en ajustes).
class BusinessLogoPlaceholder extends StatelessWidget {
  const BusinessLogoPlaceholder({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EposBrand.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EposBrand.divider),
      ),
      child: Icon(
        Icons.storefront_outlined,
        size: size * 0.4,
        color: EposBrand.navy.withValues(alpha: 0.35),
      ),
    );
  }
}
