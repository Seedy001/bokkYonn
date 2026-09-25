import 'package:bokk_yoon/features/onboarding/onboarding-screen/onboarding_screen.dart';
import 'package:flutter/material.dart';
import '../onboarding_service.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      titre: 'Payez a l\'avance',
      sousTitre:
          '15 à 20 % à la confirmation via Wave ou Orange Money. Le solde se règle de la main à la main en fin de trajet. Aucune commission.',
      indexActif: 2,
      labelBouton: 'commencer',
      image: 'images/illustration_OM-Wave.jpeg',
      afficherPasser: false,
      onBouton: () async {
        await OnboardingService.terminer();
        if (!context.mounted) return;
        // L'AuthGate (racine) décide de la suite
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
