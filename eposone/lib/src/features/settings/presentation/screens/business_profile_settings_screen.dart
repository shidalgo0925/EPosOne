import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/utils/business_logo_storage.dart';
import 'package:eposone/src/core/widgets/business_logo_header.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

/// Ajustes → Negocio: nombre, contacto y logo de recibo/factura.
class BusinessProfileSettingsScreen extends ConsumerStatefulWidget {
  const BusinessProfileSettingsScreen({super.key});

  @override
  ConsumerState<BusinessProfileSettingsScreen> createState() =>
      _BusinessProfileSettingsScreenState();
}

class _BusinessProfileSettingsScreenState
    extends ConsumerState<BusinessProfileSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _headerCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  String? _logoPath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ref.read(businessConfigRepositoryProvider).getConfig();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = config.businessName;
      _rucCtrl.text = config.ruc ?? '';
      _addressCtrl.text = config.address ?? '';
      _phoneCtrl.text = config.phone ?? '';
      _emailCtrl.text = config.email ?? '';
      _headerCtrl.text = config.receiptHeader;
      _footerCtrl.text = config.receiptFooter;
      _logoPath = config.logoPath;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rucCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSourceKind kind) async {
    try {
      final path = kind == ImageSourceKind.camera
          ? await BusinessLogoStorage.pickFromCamera()
          : await BusinessLogoStorage.pickFromGallery();
      if (path == null || !mounted) return;
      final old = _logoPath;
      setState(() => _logoPath = path);
      if (old != null && old != path) {
        await BusinessLogoStorage.deleteIfExists(old);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar el logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    final old = _logoPath;
    setState(() => _logoPath = null);
    await BusinessLogoStorage.deleteIfExists(old);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del negocio es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(businessConfigRepositoryProvider);
      final config = await repo.getConfig();
      final updated = config.copyWith(
        businessName: _nameCtrl.text.trim(),
        ruc: _rucCtrl.text.trim().isEmpty ? null : _rucCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        receiptHeader: _headerCtrl.text.trim().isEmpty
            ? 'Gracias por su compra'
            : _headerCtrl.text.trim(),
        receiptFooter: _footerCtrl.text.trim().isEmpty
            ? 'Vuelva pronto'
            : _footerCtrl.text.trim(),
        logoPath: _logoPath,
        clearLogoPath: _logoPath == null,
      );
      await repo.saveConfig(updated.markAsModified());
      ref.invalidate(businessConfigAsyncProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos del negocio guardados')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = BusinessLogoStorage.exists(_logoPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Negocio'),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Logo en recibo / factura',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Se muestra arriba del nombre en PDF y en la vista del recibo. '
                  'Si no hay logo, el encabezado empieza con texto.',
                  style: TextStyle(
                    fontSize: 13,
                    color: EposBrand.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: hasLogo
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 120,
                            maxWidth: 200,
                          ),
                          child: Image.file(
                            File(_logoPath!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const BusinessLogoPlaceholder(size: 120),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _saving
                          ? null
                          : () => _pick(ImageSourceKind.camera),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Cámara'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pick(ImageSourceKind.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galería'),
                    ),
                    if (hasLogo)
                      TextButton.icon(
                        onPressed: _saving ? null : _removeLogo,
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        label: const Text('Quitar',
                            style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _rucCtrl,
                  decoration: const InputDecoration(
                    labelText: 'RUC',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _headerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Encabezado de recibo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _footerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pie de recibo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
    );
  }
}

enum ImageSourceKind { camera, gallery }
