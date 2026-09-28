import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/trajet.dart';

class TrajetRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Enregistre un nouveau trajet dans la collection 'trajets'.
  // Firestore génère tout seul l'id du document.
  Future<void> publierTrajet(Trajet trajet) async {
    await _db.collection('trajets').add(trajet.toMap());

  }
  // Lit en direct tous les trajets, le plus récent en premier.
Stream<List<Trajet>> tousLesTrajets() {
  return _db
      .collection('trajets')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => Trajet.fromFirestore(doc)).toList());
}
}

// Provider : permet aux écrans d'utiliser le repository,
final trajetRepositoryProvider = Provider<TrajetRepository>((ref) {
  return TrajetRepository();
});
// Fournit en direct la liste des trajets aux écrans.
final trajetsProvider = StreamProvider<List<Trajet>>((ref) {
  return ref.watch(trajetRepositoryProvider).tousLesTrajets();
});