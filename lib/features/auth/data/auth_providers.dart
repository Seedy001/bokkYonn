import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// Expose une seule instance d'AuthRepository à toute l'app
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Flux qui notifie à chaque connexion/déconnexion
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});