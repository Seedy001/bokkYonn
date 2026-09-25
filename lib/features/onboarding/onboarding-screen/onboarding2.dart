import 'package:bokk_yoon/features/onboarding/onboarding-screen/onboarding3.dart';
import 'package:bokk_yoon/features/onboarding/onboarding-screen/onboarding_screen.dart';
import 'package:flutter/material.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      titre: 'Réservez une place',
      sousTitre:
          'Filtrez par zone, date et prix. Vous voyez la note du conducteur avant de demander votre place — c\'est gratuit pour les passagers.',
      indexActif: 1,
      labelBouton: 'Suivant',
      image: 'images/illustration_client.jpeg',
      onBouton: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const Onboarding3()),
        );
      },
    );
  }
}
