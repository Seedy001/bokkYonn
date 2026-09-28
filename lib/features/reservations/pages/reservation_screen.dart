import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formats.dart';
import '../../trajets/domain/trajet.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';
import 'reservation_attente_screen.dart';

/// Écran « Réserver avec avance » (maquette 1g).
/// Le passager voit le récap, l'avance à verser, choisit Wave ou Orange Money,
/// puis confirme. Le paiement est SIMULÉ : on enregistre juste la demande.
class ReservationScreen extends ConsumerStatefulWidget {
  final Trajet trajet;
  final Map<String, dynamic> profil;

  const ReservationScreen({
    super.key,
    required this.trajet,
    required this.profil,
  });

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  String _moyen = 'Wave'; // Wave sélectionné par défaut
  bool _enCours = false;

  Future<void> _confirmer() async {
    final t = widget.trajet;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. On construit la réservation
    final reservation = Reservation(
      id: '', // Firestore génère l'id tout seul
      trajetId: t.id,
      passagerId: uid,
      passagerNom:
          '${widget.profil['prenom'] ?? ''} ${widget.profil['nom'] ?? ''}'
              .trim(),
      conducteurId: t.conducteurId,
      trajetResume: '${t.departZone} → ${t.arriveeZone}',
      dateDepart: t.dateDepart,
      prix: t.prix,
      avance: calculerAvance(t.prix),
      moyenPaiement: _moyen,
      etat: 'en_attente',
      createdAt: DateTime.now(),
    );

    // 2. Paiement simulé : pas de vraie API, on enregistre la demande
    setState(() => _enCours = true);
    try {
      final id = await ref
          .read(reservationRepositoryProvider)
          .creerReservation(reservation);
      if (!mounted) return;
      // 3. On remplace cet écran par la confirmation (retour = détail)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReservationAttenteScreen(
            reservation: reservation,
            reservationId: id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur, réessaie')));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trajet;
    final avance = calculerAvance(t.prix);
    final solde = t.prix - avance;
    final pourcentage = (tauxAvance * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Réserver'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        children: [
          // ── Récap du trajet ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.departZone} → ${t.arriveeZone}',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFr(t.dateDepart)} · ${heureFr(t.dateDepart)}'
                  '${t.departPoint.isEmpty ? '' : ' · ${t.departPoint}'}',
                  style: AppTextStyles.bodySmall,
                ),
                const Divider(height: 24),
                _ligne(
                  'Conducteur',
                  t.conducteurNom.isEmpty ? 'Conducteur' : t.conducteurNom,
                ),
                const SizedBox(height: 8),
                _ligne('Places', '1 place'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Encadré ocre : avance ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avance à verser maintenant ($pourcentage %)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${prixFr(avance)} FCFA', style: AppTextStyles.priceLarge),
                Divider(height: 24, color: AppColors.accentBorder),
                _ligne('Prix total de la place', '${prixFr(t.prix)} F'),
                const SizedBox(height: 8),
                _ligne('Solde à régler au conducteur', '${prixFr(solde)} F'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Moyen de paiement ──
          Text(
            'MOYEN DE PAIEMENT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _optionPaiement('Wave', 'W', const Color(0xFF1DC3F0)),
          const SizedBox(height: 8),
          _optionPaiement('Orange Money', 'OM', const Color(0xFFFF7900)),
          const SizedBox(height: 12),
          Text(
            'Paiement simulé : aucun argent n’est réellement débité.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),

      // ── Bouton Confirmer ──
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: ElevatedButton(
              onPressed: _enCours ? null : _confirmer,
              child: _enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Confirmer et payer ${prixFr(avance)} FCFA'),
            ),
          ),
        ),
      ),
    );
  }

  // Ligne « label ........ valeur »
  Widget _ligne(String label, String valeur) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(valeur, style: AppTextStyles.bodyLarge),
      ],
    );
  }

  // Carte cliquable avec « logo » texte + nom + case radio
  Widget _optionPaiement(String nom, String logo, Color couleurLogo) {
    final actif = _moyen == nom;
    return GestureDetector(
      onTap: () => setState(() => _moyen = nom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: actif ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: actif ? AppColors.primary : AppColors.border,
            width: actif ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Logo en placeholder : pastille de couleur + initiales
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: couleurLogo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                logo,
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(nom, style: AppTextStyles.bodyLarge)),
            Icon(
              actif ? Icons.radio_button_checked : Icons.radio_button_off,
              color: actif ? AppColors.primary : AppColors.borderStrong,
            ),
          ],
        ),
      ),
    );
  }
}
