import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import 'verification_screen.dart';

class InscriptionScreen extends ConsumerStatefulWidget {
  // NOUVEAU : false = inscription (par défaut), true = connexion
  final bool estConnexion;

  const InscriptionScreen({super.key, this.estConnexion = false});

  @override
  ConsumerState<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends ConsumerState<InscriptionScreen> {
  // Sert à lire ce que l'utilisateur tape
  final telephoneController = TextEditingController();

  // true = on attend Firebase (le bouton affiche un rond qui tourne)
  bool chargement = false;

  // Message d'erreur sous le champ (null = pas d'erreur)
  String? erreur;

  // Appelée quand on appuie sur le bouton
  void envoyerCode() {
    final numero = telephoneController.text.replaceAll(' ', '');

    // 1. Vérifier le numéro
    if (numero.length != 9 || !numero.startsWith('7')) {
      setState(() {
        erreur = 'Numéro invalide (9 chiffres, commence par 7)';
      });
      return; // on s'arrête là
    }

    // 2. Afficher le chargement
    setState(() {
      erreur = null;
      chargement = true;
    });

    // 3. Demander à Firebase d'envoyer le SMS
    final telephone = '+221$numero';

    ref
        .read(authRepositoryProvider)
        .envoyerCode(
          telephone: telephone,

          // Si le SMS est parti : on va à l'écran suivant
          onCodeEnvoye: (verificationId) {
            if (!mounted) return; // l'écran a été fermé entre-temps
            setState(() {
              chargement = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  telephone: telephone,
                  verificationId: verificationId,
                ),
              ),
            );
          },

          // Si ça a raté : on affiche une erreur
          onErreur: (e) {
            if (!mounted) return;
            print('ERREUR FIREBASE : ${e.code} - ${e.message}');
            setState(() {
              chargement = false;
              erreur = e.code;
            });
          },
        );
  }

  // Libère le controller quand on quitte l'écran
  @override
  void dispose() {
    telephoneController.dispose();
    super.dispose();
  }

  // Ce qu'on voit à l'écran
  @override
  Widget build(BuildContext context) {
    // NOUVEAU : on choisit les textes selon le mode
    final titre = widget.estConnexion ? 'Se connecter' : 'Créer un compte';
    final sousTitre = widget.estConnexion
        ? 'Entrez le numéro de votre compte pour recevoir un code.'
        : "Votre numéro de téléphone est votre identifiant. "
              "Aucun numéro étudiant n'est demandé.";

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // NOUVEAU : "ÉTAPE 1 SUR 2" seulement en mode inscription
              if (!widget.estConnexion) const Text('ÉTAPE 1 SUR 2'),
              if (!widget.estConnexion) const SizedBox(height: 8),

              // NOUVEAU : titre selon le mode
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // NOUVEAU : sous-titre selon le mode
              Text(sousTitre),
              const SizedBox(height: 28),

              const Text('Numéro de téléphone'),
              const SizedBox(height: 8),

              // +221 à gauche, le champ à droite
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('+221'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '77 123 45 67',
                        errorText: erreur, // s'affiche en rouge si pas null
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Text('Un code à 6 chiffres vous sera envoyé par SMS.'),
              const SizedBox(height: 24),

              // Le bouton
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: chargement ? null : envoyerCode,
                  child: chargement
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Recevoir le code'),
                ),
              ),
              const SizedBox(height: 16),

              // NOUVEAU : lien qui bascule inscription <-> connexion
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InscriptionScreen(
                          estConnexion: !widget.estConnexion,
                        ),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: widget.estConnexion
                          ? 'Pas encore de compte ? '
                          : 'Déjà inscrit ? ',
                      children: [
                        TextSpan(
                          text: widget.estConnexion
                              ? "S'inscrire"
                              : 'Se connecter',
                          style: const TextStyle(
                            color: Color(0xFF0F6B5C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
