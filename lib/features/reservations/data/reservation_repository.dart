import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reservation.dart';

/// Levée quand le conducteur accepte alors que le trajet est plein.
class PlusDePlaceException implements Exception {}

class ReservationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Enregistre une nouvelle demande de réservation (état "en_attente").
  // On ne touche PAS aux places du trajet ici : elles seront décomptées
  // quand le conducteur acceptera la demande.
  // Renvoie l'id du document créé, pour pouvoir suivre la réservation ensuite.
  Future<String> creerReservation(Reservation r) async {
    final doc = await _db.collection('reservations').add(r.toMap());
    return doc.id;
  }

  // Lit en direct toutes les réservations faites par un passager,
  // la plus récente en premier (tri en Dart, pas d'index à créer).
  Stream<List<Reservation>> reservationsDuPassager(String passagerId) {
    return _db
        .collection('reservations')
        .where('passagerId', isEqualTo: passagerId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Reservation.fromFirestore(doc)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Suit UNE réservation en direct (son état change quand le conducteur répond).
  Stream<Reservation> suivreReservation(String id) {
    return _db
        .collection('reservations')
        .doc(id)
        .snapshots()
        .map((doc) => Reservation.fromFirestore(doc));
  }

  // Lit en direct toutes les demandes reçues par un conducteur.
  // Pas de orderBy (sinon Firestore exige un index composite) :
  // on trie en Dart, la plus récente en premier.
  Stream<List<Reservation>> demandesPourConducteur(String conducteurId) {
    return _db
        .collection('reservations')
        .where('conducteurId', isEqualTo: conducteurId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Reservation.fromFirestore(doc)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Accepter = 2 écritures liées, faites dans une TRANSACTION :
  // soit les deux réussissent, soit aucune n'est enregistrée.
  Future<void> accepterReservation(Reservation r) async {
    final resaRef = _db.collection('reservations').doc(r.id);
    final trajetRef = _db.collection('trajets').doc(r.trajetId);

    await _db.runTransaction((tx) async {
      // 1. On relit les données À JOUR (pas celles affichées à l'écran)
      final resaSnap = await tx.get(resaRef);
      final trajetSnap = await tx.get(trajetRef);

      // Sécurité : si la demande a déjà été traitée (double tap,
      // 2 téléphones...), on ne décompte pas une 2e place.
      if (resaSnap.data()?['etat'] != 'en_attente') {
        throw Exception('Demande déjà traitée');
      }

      final places =
          (trajetSnap.data()?['placesRestantes'] as num?)?.toInt() ?? 0;
      if (places <= 0) throw PlusDePlaceException();

      // 2. Les deux écritures
      tx.update(resaRef, {'etat': 'confirmee'});
      tx.update(trajetRef, {'placesRestantes': places - 1});
    });
  }

  // Refuser : on change juste l'état, les places ne bougent pas.
  // (Avance simulée : pas de vrai remboursement.)
  Future<void> refuserReservation(Reservation r) async {
    await _db.collection('reservations').doc(r.id).update({'etat': 'refusee'});
  }

  // Annuler (côté passager) : on change juste l'état.
  // Règle du cahier des charges : l'avance reste acquise au conducteur,
  // pas de remboursement, pas de règle des 12 h.
  Future<void> annulerReservation(Reservation r) async {
    await _db.collection('reservations').doc(r.id).update({'etat': 'annulee'});
  }
}

// Provider : permet aux écrans d'utiliser le repository
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository();
});

// Fournit en direct les réservations du passager connecté.
final mesReservationsProvider = StreamProvider.autoDispose<List<Reservation>>((
  ref,
) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]); // personne de connecté
  return ref.watch(reservationRepositoryProvider).reservationsDuPassager(uid);
});

// Fournit en direct UNE réservation à partir de son id.
// family : on passe l'id en paramètre -> ref.watch(reservationProvider(id))
final reservationProvider = StreamProvider.autoDispose
    .family<Reservation, String>((ref, id) {
      return ref.watch(reservationRepositoryProvider).suivreReservation(id);
    });

// Fournit en direct les demandes reçues par le conducteur connecté.
// autoDispose : le flux est fermé quand on quitte l'écran, et relu à la
// prochaine ouverture (utile si on change de compte sur le même téléphone).
final demandesConducteurProvider =
    StreamProvider.autoDispose<List<Reservation>>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return Stream.value([]); // personne de connecté
      return ref
          .watch(reservationRepositoryProvider)
          .demandesPourConducteur(uid);
    });
