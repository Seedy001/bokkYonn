import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'onboarding2.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      titre: 'Publiez votre trajet',
      sousTitre:
          'Vous rentrez à Rufisque le vendredi soir ? Indiquez votre sens, votre point de rendez-vous et le nombre de places libres.',
      indexActif: 0,
      labelBouton: 'Suivant',
      image: 'images/illustration_Conducteur.jpeg',
      onBouton: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const Onboarding2()),
        );
      },
    );
  }
}