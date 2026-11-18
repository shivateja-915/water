import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'splash/splash_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services BEFORE launching the app
  await SplashInitializer.initializeApp();

  runApp(
    const ProviderScope(
      child: SiplyApp(),
    ),
  );
}
