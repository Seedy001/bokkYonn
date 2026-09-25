import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Utilisateur actuellement connecté (null si personne n'est connecté)
  User? get currentUser => _auth.currentUser;

  // Flux qui notifie à chaque changement de connexion/déconnexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Étape 1 : envoyer le code SMS
  Future<void> envoyerCode({
    required String telephone, // format complet : "+221771234567"
    required void Function(String verificationId) onCodeEnvoye,
    required void Function(FirebaseAuthException e) onErreur,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: telephone,
      timeout: const Duration(seconds: 60),

      // Cas rare : Android vérifie le SMS tout seul sans que l'utilisateur tape le code
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        onErreur(e);
      },

      // Le SMS a été envoyé, on a besoin du verificationId pour l'étape 2
      codeSent: (String verificationId, int? resendToken) {
        onCodeEnvoye(verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        // Le délai auto-détection est passé, rien à faire ici,
        // l'utilisateur tape le code manuellement (étape 2)
      },
    );
  }

  // Étape 2 : vérifier le code tapé par l'utilisateur
  Future<UserCredential> verifierCode({
    required String verificationId,
    required String code,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> deconnexion() async {
    await _auth.signOut();
  }
}