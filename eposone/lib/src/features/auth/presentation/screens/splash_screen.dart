import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/startup/app_startup.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_navigate);
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final session = ref.read(posSessionProvider);
    if (session != null) {
      if (session.cashRegisterId != null) {
        context.go('/pos');
      } else {
        context.go('/cash/open');
      }
      return;
    }

    final startup = await ref.read(appStartupProvider.future);
    if (!mounted) return;

    switch (startup.route) {
      case StartupRoute.onboarding:
        context.go('/onboarding');
      case StartupRoute.pin:
        context.go('/pin');
      case StartupRoute.cashOpen:
        context.go('/cash/open');
      case StartupRoute.pos:
        context.go('/pin');
      case StartupRoute.splash:
        context.go('/pin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final startupAsync = ref.watch(appStartupProvider);
    final businessName = startupAsync.valueOrNull?.config?.businessName;

    return Scaffold(
      backgroundColor: EposBrand.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EposBrandIcon(size: 88),
            const SizedBox(height: 24),
            const EposOneLogo(fontSize: 36),
            const SizedBox(height: 8),
            if (businessName != null && businessName != 'Mi Negocio')
              Text(businessName, style: const TextStyle(color: EposBrand.textSecondary, fontSize: 16))
            else
              const Text(
                'Punto de Venta Simple, Rápido y Poderoso',
                style: TextStyle(color: EposBrand.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            const Text(
              'EasyTech Services',
              style: TextStyle(fontSize: 12, color: EposBrand.navy, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
