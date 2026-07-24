import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/app.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  En1DateTimeService.ensureInitialized();
  await En1DateTimeService.hydrateFromPrefs();
  runApp(const ProviderScope(child: EPosOneApp()));
}
