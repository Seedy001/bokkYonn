import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formats.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';

/// Écran « Ma réservation » : suit l'état EN DIRECT.
/// - en attente -> on attend la réponse du conducteur
/// - acceptée   -> compte à rebours jusqu'au départ (jour + heure)
/// - refusée    -> message + retour à l'accueil
class MaReservationScreen extends ConsumerWidget {
  final String reservationId;

  const MaReservationScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationProvider(reservationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ma réservation'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: reservationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur : $e',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        data: (r) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          children: [
            _BlocEtat(reservation: r),
            const SizedBox(height: 16),
            _Recap(reservation: r),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: OutlinedButton(
            // Retour à la racine (l'AuthGate affiche l'accueil)
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Retour à l’accueil'),
          ),
        ),
      ),
    );
  }
}

// ── Gros bloc qui change selon l'état ─────────────────────────────

class _BlocEtat extends StatelessWidget {
  final Reservation reservation;

  const _BlocEtat({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;

    // Icône, couleurs et textes selon l'état
    IconData icone;
    Color couleur;
    Color fond;
    Color bordure;
    String titre;
    String texte;

    switch (r.etat) {
      case 'confirmee':
        icone = Icons.check_circle;
        couleur = AppColors.primary;
        fond = AppColors.primarySoft;
        bordure = AppColors.primaryBorder;
        titre = 'Réservation acceptée';
        texte = 'Le conducteur t’attend au point de départ.';
        break;
      case 'refusee':
        icone = Icons.cancel;
        couleur = AppColors.danger;
        fond = AppColors.dangerSoft;
        bordure = AppColors.dangerBorder;
        titre = 'Réservation refusée';
        texte =
            'Le conducteur n’a pas pu accepter ta demande. '
            'Tu peux chercher un autre trajet.';
        break;
      case 'annulee':
        icone = Icons.block;
        couleur = AppColors.textSecondary;
        fond = AppColors.neutralSoft;
        bordure = AppColors.border;
        titre = 'Réservation annulée';
        texte = 'Tu as annulé cette demande.';
        break;
      case 'terminee':
        icone = Icons.flag;
        couleur = AppColors.textSecondary;
        fond = AppColors.neutralSoft;
        bordure = AppColors.border;
        titre = 'Trajet terminé';
        texte = 'Merci d’avoir voyagé avec Bokk Yoon !';
        break;
      default: // en_attente
        icone = Icons.hourglass_top;
        couleur = AppColors.accentDark;
        fond = AppColors.accentSoft;
        bordure = AppColors.accentBorder;
        titre = 'En attente du conducteur';
        texte =
            'Le conducteur a 24 h pour accepter. '
            'Cet écran se met à jour tout seul.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bordure),
      ),
      child: Column(
        children: [
          Icon(icone, color: couleur, size: 48),
          const SizedBox(height: 10),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 20,
              color: couleur,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texte,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // Acceptée -> compte à rebours jusqu'au départ
          if (r.etat == 'confirmee') ...[
            const SizedBox(height: 16),
            _CompteARebours(depart: r.dateDepart),
          ],
        ],
      ),
    );
  }
}

// ── Compte à rebours ──────────────────────────────────────────────
// StatefulWidget : un Timer le rafraîchit toutes les 30 secondes.

class _CompteARebours extends StatefulWidget {
  final DateTime depart;

  const _CompteARebours({required this.depart});

  @override
  State<_CompteARebours> createState() => _CompteAReboursState();
}

class _CompteAReboursState extends State<_CompteARebours> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}), // on redessine avec la nouvelle heure
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // important : sinon le Timer tourne encore
    super.dispose();
  }

  // Ex : "2 j 5 h 30 min", "3 h 12 min", "8 min"
  String _texteRestant(Duration d) {
    final jours = d.inDays;
    final heures = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (jours > 0) return '$jours j $heures h $minutes min';
    if (heures > 0) return '$heures h $minutes min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final restant = widget.depart.difference(DateTime.now());
    final dejaParti = restant.isNegative;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        children: [
          Text(
            dejaParti ? 'DÉPART' : 'DÉPART DANS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dejaParti ? 'C’est l’heure !' : _texteRestant(restant),
            style: AppTextStyles.priceLarge.copyWith(
              color: AppColors.primary,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${dateFr(widget.depart)} à ${heureFr(widget.depart)}',
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }
}

// ── Récap du trajet et du paiement ────────────────────────────────

class _Recap extends StatelessWidget {
  final Reservation reservation;

  const _Recap({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Container(
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
          _ligne('Avance versée (${r.moyenPaiement})', '${prixFr(r.avance)} F'),
          const SizedBox(height: 8),
          _ligne('Solde à régler au conducteur', '${prixFr(r.solde)} F'),
        ],
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
