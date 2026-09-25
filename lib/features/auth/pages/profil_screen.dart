import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  // NOUVEAU : la liste des filières (à remplacer par les vraies)
  final filieres = [
    'Génie informatique',
    'Génie civil',
    'Mines et géologie',
    'Urbanisme et aménagement',
    'Économie et gestion',
  ];

  // NOUVEAU : la liste des niveaux possibles
  final niveaux = [
    'Licence 1',
    'Licence 2',
    'Licence 3',
    'Master 1',
    'Master 2',
    'Doctorat',
  ];

  final prenomController = TextEditingController();
  final nomController = TextEditingController();
  final serviceController = TextEditingController(); // pour enseignants et personnel

  String statut = 'etudiant';

  // NOUVEAU : ce que l'étudiant a choisi (null = rien choisi)
  String? filiere;
  String? niveau;

  bool estConducteur = false;
  bool chargement = false;
  String? erreur;

  Future<void> enregistrer() async {
    // 1. Vérifier les champs
    if (prenomController.text.trim().isEmpty ||
        nomController.text.trim().isEmpty) {
      setState(() {
        erreur = 'Entrez votre prénom et votre nom';
      });
      return;
    }

    // NOUVEAU : un étudiant doit choisir sa filière et son niveau
    if (statut == 'etudiant' && (filiere == null || niveau == null)) {
      setState(() {
        erreur = 'Choisissez votre filière et votre niveau';
      });
      return;
    }

    // 2. Afficher le chargement
    setState(() {
      erreur = null;
      chargement = true;
    });

    // NOUVEAU : on prépare le texte à enregistrer
    // Étudiant   -> "Génie informatique — Licence 3"
    // Les autres -> ce qu'ils ont tapé
    String filiereOuService;
    if (statut == 'etudiant') {
      filiereOuService = '$filiere — $niveau';
    } else {
      filiereOuService = serviceController.text.trim();
    }

    final user = FirebaseAuth.instance.currentUser!;

    // 3. Enregistrer dans Firestore
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'telephone': user.phoneNumber,
        'prenom': prenomController.text.trim(),
        'nom': nomController.text.trim(),
        'statut': statut,
        'filiereOuService': filiereOuService,
        'estConducteur': estConducteur,
        'noteMoyenne': 0,
        'nbTrajets': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré')),
      );
     Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('ERREUR FIRESTORE : $e');
      if (!mounted) return;
      setState(() {
        erreur = "Impossible d'enregistrer, réessayez";
      });
    }

    if (!mounted) return;
    setState(() {
      chargement = false;
    });
  }

  @override
  void dispose() {
    prenomController.dispose();
    nomController.dispose();
    serviceController.dispose();
    super.dispose();
  }

  Widget choixStatut(String valeur, String texte) {
    final estChoisi = statut == valeur;

    return GestureDetector(
      onTap: () {
        setState(() {
          statut = valeur;
        });
      },
      child: Container(
        height: 52,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: estChoisi ? const Color(0xFFF1F7F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: estChoisi ? const Color(0xFF0F6B5C) : const Color(0xFFE3E6E4),
            width: estChoisi ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              estChoisi ? Icons.radio_button_checked : Icons.radio_button_off,
              color: estChoisi ? const Color(0xFF0F6B5C) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(texte),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votre profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: prenomController,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: nomController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text("Votre statut à l'UAM"),
              const SizedBox(height: 8),
              choixStatut('etudiant', 'Étudiant'),
              choixStatut('enseignant', 'Enseignant'),
              choixStatut('personnel', 'Personnel administratif et technique'),
              const SizedBox(height: 12),

              // NOUVEAU : si étudiant -> liste des filières
              if (statut == 'etudiant')
                DropdownButtonFormField<String>(
                  initialValue: filiere,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Filière'),
                  items: filieres
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (choix) {
                    setState(() {
                      filiere = choix;
                    });
                  },
                ),

              if (statut == 'etudiant') const SizedBox(height: 12),

              // NOUVEAU : si étudiant -> liste des niveaux
              if (statut == 'etudiant')
                DropdownButtonFormField<String>(
                  initialValue: niveau,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: niveaux
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (choix) {
                    setState(() {
                      niveau = choix;
                    });
                  },
                ),

              // Si enseignant ou personnel -> champ texte libre
              if (statut != 'etudiant')
                TextField(
                  controller: serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Département ou service',
                  ),
                ),

              const SizedBox(height: 20),

              SwitchListTile(
                title: const Text('Je suis aussi conducteur'),
                subtitle: const Text(
                    'Publier des trajets nécessite un abonnement conducteur.'),
                value: estConducteur,
                onChanged: (nouvelleValeur) {
                  setState(() {
                    estConducteur = nouvelleValeur;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (erreur != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(erreur!, style: const TextStyle(color: Colors.red)),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: chargement ? null : enregistrer,
                  child: chargement
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer et continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}