import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formats.dart';
import '../domain/reservation.dart';
import 'ma_reservation_screen.dart';

/// Écran « Réservation en attente » (maquette 1h).
/// Affiché juste après une réservation réussie.
class ReservationAttenteScreen extends StatelessWidget {
  final Reservation reservation;
  final String reservationId; // id Firestore, pour suivre l'état en direct

  const ReservationAttenteScreen({
    super.key,
    required this.reservation,
    required this.reservationId,
  });

  @override
  Widget build(BuildContext context) {
    final r = reservation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Réservation'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          // ── Gros rond ocre ──
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentBorder, width: 2),
              ),
              child: const Icon(
                Icons.hourglass_top,
                color: AppColors.accent,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Réservation en attente',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ta demande a été envoyée. Le conducteur a 24 h pour accepter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ── Récap ──
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
                  r.trajetResume,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFr(r.dateDepart)} · ${heureFr(r.dateDepart)}',
                  style: AppTextStyles.bodySmall,
                ),
                const Divider(height: 24),
                _ligne(
                  'Avance versée (${r.moyenPaiement})',
                  '${prixFr(r.avance)} F',
                ),
                const SizedBox(height: 8),
                _ligne('Solde à régler au conducteur', '${prixFr(r.solde)} F'),
              ],
            ),
          ),
        ],
      ),

      // ── Boutons ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                // Ouvre le suivi de la réservation. On retire les écrans
                // intermédiaires : le retour ramènera à l'accueil.
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) =>
                        MaReservationScreen(reservationId: reservationId),
                  ),
                  (route) => route.isFirst,
                ),
                child: const Text('Voir ma réservation'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  // TODO : vraie annulation plus tard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Annulation bientôt disponible'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.dangerBorder),
                ),
                child: const Text('Annuler la demande'),
              ),
            ],
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
}
