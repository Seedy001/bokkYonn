import 'package:flutter/foundation.dart';

/// Onboarding affiché tant qu'on n'est pas connecté, une fois par lancement.
class OnboardingService {
  OnboardingService._();

  static final ValueNotifier<bool> vu = ValueNotifier<bool>(false);

  static Future<void> terminer() async {
    vu.value = true;
  }
}
