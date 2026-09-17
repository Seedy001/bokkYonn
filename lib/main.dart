import 'package:bokk_yoon/features/onboarding/splash/splash-screen.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const BokkYoonApp());
}

class BokkYoonApp extends StatelessWidget {
  const BokkYoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bokk Yoon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
