import 'package:cloud_firestore/cloud_firestore.dart';

class Trajet {
  final String id;
  final String conducteurId;

  // Infos du conducteur recopiées ici, pour afficher la carte
  // sans devoir relire son profil à chaque fois.
  final String conducteurNom;
  final String conducteurStatut;
  final double conducteurNote;
  final String? conducteurPhotoUrl;
  final String immatriculation;

  // 'versVille' (Diamniadio → Ville) ou 'versDiamniadio' (Ville → Diamniadio)
  final String sens;
  final String departZone;
  final String departPoint;
  final String arriveeZone;
  final String arriveePoint;

  final DateTime dateDepart;   // date + heure ensemble
  final int placesTotal;
  final int placesRestantes;   // diminue à chaque réservation acceptée
  final int prix;              // en FCFA

  final String? typeVehicule;
  final String? notes;
  final DateTime createdAt;

  Trajet({
    required this.id,
    required this.conducteurId,
    required this.conducteurNom,
    required this.conducteurStatut,
    required this.conducteurNote,
    required this.immatriculation,
    this.conducteurPhotoUrl,
    required this.sens,
    required this.departZone,
    required this.departPoint,
    required this.arriveeZone,
    required this.arriveePoint,
    required this.dateDepart,
    required this.placesTotal,
    required this.placesRestantes,
    required this.prix,
    this.typeVehicule,
    this.notes,
    required this.createdAt,
  });

  // Firestore -> objet Dart
  factory Trajet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trajet(
      id: doc.id,
      conducteurId: data['conducteurId'] ?? '',
      conducteurNom: data['conducteurNom'] ?? '',
      conducteurStatut: data['conducteurStatut'] ?? '',
      conducteurNote: (data['conducteurNote'] ?? 0).toDouble(),
      immatriculation: data['immatriculation'] ?? '',
      conducteurPhotoUrl: data['conducteurPhotoUrl'],
      sens: data['sens'] ?? 'versVille',
      departZone: data['departZone'] ?? '',
      departPoint: data['departPoint'] ?? '',
      arriveeZone: data['arriveeZone'] ?? '',
      arriveePoint: data['arriveePoint'] ?? '',
dateDepart: (data['dateDepart'] as Timestamp?)?.toDate() ?? DateTime.now(),      placesTotal: data['placesTotal'] ?? 0,
      placesRestantes: data['placesRestantes'] ?? 0,
      prix: data['prix'] ?? 0,
      typeVehicule: data['typeVehicule'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // objet Dart -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'conducteurId': conducteurId,
      'conducteurNom': conducteurNom,
      'conducteurStatut': conducteurStatut,
      'conducteurNote': conducteurNote,
      'immatriculation': immatriculation,
      'conducteurPhotoUrl': conducteurPhotoUrl,
      'sens': sens,
      'departZone': departZone,
      'departPoint': departPoint,
      'arriveeZone': arriveeZone,
      'arriveePoint': arriveePoint,
      'dateDepart': Timestamp.fromDate(dateDepart),
      'placesTotal': placesTotal,
      'placesRestantes': placesRestantes,
      'prix': prix,
      'typeVehicule': typeVehicule,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}