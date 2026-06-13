import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/router/app_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

class EPosOneApp extends ConsumerWidget {
  const EPosOneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EPOSOne',
      debugShowCheckedModeBanner: false,
      theme: EposBrand.lightTheme(),
      routerConfig: router,
    );
  }
}
