import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutUam { etudiant, enseignant, personnel }

class AppUser {
  final String uid;
  final String telephone;
  final String prenom;
  final String nom;
  final StatutUam statut;
  final String filiereOuService;
  final String? photoUrl;
  final bool estConducteur;
  final double noteMoyenne;
  final int nbTrajets;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.telephone,
    required this.prenom,
    required this.nom,
    required this.statut,
    required this.filiereOuService, 
    this.photoUrl,
    this.estConducteur = false,
    this.noteMoyenne = 0.0,
    this.nbTrajets = 0,
    required this.createdAt,
  });

  // Firestore -> objet Dart
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      telephone: data['telephone'] as String,
      prenom: data['prenom'] as String,
      nom: data['nom'] as String,
      statut: StatutUam.values.byName(data['statut']),
      photoUrl: data['photoUrl'] as String?,
      estConducteur: data['estConducteur'] as bool,
      noteMoyenne: (data['noteMoyenne'] as num).toDouble(),
      nbTrajets: data['nbTrajets'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      filiereOuService: data['filiereOuService'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'telephone': telephone,
      'prenom': prenom,
      'nom': nom,
      'statut': statut.name,
      'photoUrl': photoUrl,
      'estConducteur': estConducteur,
      'noteMoyenne': noteMoyenne,
      'nbTrajets': nbTrajets,
      'createdAt': Timestamp.fromDate(createdAt),
      'filiereOuService': filiereOuService,
    };
  }
}

