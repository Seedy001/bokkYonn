import 'package:flutter/material.dart';
import '../onboarding_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final int indexActif;
  final String labelBouton;
  final VoidCallback onBouton;
  final String image;
  final bool afficherPasser;

  const OnboardingScreen({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.indexActif,
    required this.labelBouton,
    required this.onBouton,
    required this.image,
    this.afficherPasser = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "Passer" en haut à droite
              if (afficherPasser)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await OnboardingService.terminer();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: Text(
                      'Passer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 28),

              const SizedBox(height: 4),

              // Cadre illustration
              Container(
                width: double.infinity,
                height: 480,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(image, fit: BoxFit.cover),
              ),

              const SizedBox(height: 14),

              // Titre
              Text(
                titre,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.left,
              ),

              const SizedBox(height: 12),

              // Sous-titre
              Text(
                sousTitre,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const Spacer(),

              // Les 3 dots de progression
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final actif = index == indexActif;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: actif ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: actif ? AppColors.primary : AppColors.border,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Bouton principal pleine largeur
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onBouton,
                  child: Text(labelBouton),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
