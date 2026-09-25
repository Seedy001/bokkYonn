import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../onboarding/splash_screen.dart'; 
import '../../onboarding/onboarding_service.dart';
import '../../onboarding/onboarding-screen/onboarding1.dart';
import 'inscription_screen.dart';
import 'profil_screen.dart';
import '../../accueil/accueil_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder écoute en continu l'état de connexion Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. On attend encore la réponse de Firebase -> splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;

        // 2. Personne n'est connecté -> onboarding (1re fois) puis inscription
        if (user == null) {
          return ValueListenableBuilder<bool>(
            valueListenable: OnboardingService.vu,
            builder: (context, vu, _) {
              return vu ? const InscriptionScreen() : const Onboarding1();
            },
          );
        }

        // 3. Connecté : reste à savoir si le profil existe dans Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profilSnapshot) {
            // On attend la réponse de Firestore -> splash
            if (profilSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final profilExiste =
                profilSnapshot.hasData && profilSnapshot.data!.exists;

            if (profilExiste) {
              return AccueilScreen(
                profil: profilSnapshot.data!.data() as Map<String, dynamic>,
              );
            } else {
              return const ProfilScreen();
            }
          },
        );
      },
    );
  }
}