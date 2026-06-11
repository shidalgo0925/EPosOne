import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/startup/app_startup.dart';

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

    final businessName = startupAsync.valueOrNull?.config?.businessName ?? 'EPOSOne';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'EPOSOne',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(businessName, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Easy Technology Services', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
