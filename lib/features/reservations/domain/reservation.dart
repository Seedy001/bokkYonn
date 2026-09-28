import 'package:cloud_firestore/cloud_firestore.dart';

/// Part du prix versée à l'avance par le passager (20 %).
/// C'est la SEULE valeur à changer pour modifier le taux (ex. 0.15 pour 15 %).
const double tauxAvance = 0.20;

/// Calcule l'avance arrondie à l'entier. Ex : 1500 F -> 300 F.
int calculerAvance(int prix) => (prix * tauxAvance).round();

class Reservation {
  final String id;
  final String trajetId;
  final String passagerId;
  final String passagerNom;
  final String conducteurId;

  // Résumé recopié ici pour afficher la réservation sans relire le trajet
  // Ex : "Diamniadio → Guédiawaye"
  final String trajetResume;
  final DateTime dateDepart;

  final int prix; // prix total de la place, en FCFA
  final int avance; // part déjà payée (simulée), en FCFA

  // "Wave" ou "Orange Money"
  final String moyenPaiement;

  // "en_attente" | "confirmee" | "refusee" | "annulee" | "terminee"
  // refusee = le conducteur a dit non · annulee = le passager s'est désisté
  final String etat;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.trajetId,
    required this.passagerId,
    required this.passagerNom,
    required this.conducteurId,
    required this.trajetResume,
    required this.dateDepart,
    required this.prix,
    required this.avance,
    required this.moyenPaiement,
    required this.etat,
    required this.createdAt,
  });

  // Reste à payer en espèces au conducteur
  int get solde => prix - avance;

  // Firestore -> objet Dart
  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      trajetId: data['trajetId'] ?? '',
      passagerId: data['passagerId'] ?? '',
      passagerNom: data['passagerNom'] ?? '',
      conducteurId: data['conducteurId'] ?? '',
      trajetResume: data['trajetResume'] ?? '',
      dateDepart:
          (data['dateDepart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prix: data['prix'] ?? 0,
      avance: data['avance'] ?? 0,
      moyenPaiement: data['moyenPaiement'] ?? 'Wave',
      etat: data['etat'] ?? 'en_attente',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // objet Dart -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'trajetId': trajetId,
      'passagerId': passagerId,
      'passagerNom': passagerNom,
      'conducteurId': conducteurId,
      'trajetResume': trajetResume,
      'dateDepart': Timestamp.fromDate(dateDepart),
      'prix': prix,
      'avance': avance,
      'moyenPaiement': moyenPaiement,
      'etat': etat,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
