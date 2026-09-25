import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
         child: SizedBox(
              width: double.infinity,              // <-- AJOUTE

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,   // <-- AJOUTE CETTE LIGNE
            children: [
              const Spacer(), // pousse tout vers le centre
              // Le bloc "logo + titre + sous-titre" collé ensemble
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'BY',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24), // juste sous le logo

              Text(
                'Bokk Yoon',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Partageons la route',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),

              const Spacer(), // pousse la barre ocre vers le bas
              // Barre ocre
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Université Amadou Mahtar Mbow · Diamniadio',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
