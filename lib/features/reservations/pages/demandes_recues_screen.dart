import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formats.dart';
import '../../trajets/data/trajet_repository.dart';
import '../../trajets/domain/trajet.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';

/// Écran conducteur « Mes trajets & demandes reçues » (maquette 1k).
/// Pour chaque trajet à venir du conducteur, on liste les demandes reçues.
class DemandesRecuesScreen extends ConsumerWidget {
  const DemandesRecuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final trajetsAsync = ref.watch(trajetsProvider);
    final demandesAsync = ref.watch(demandesConducteurProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes trajets & demandes'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      // On attend les DEUX flux (trajets + demandes) avant d'afficher
      body: trajetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(texte: 'Erreur : $e'),
        data: (tousLesTrajets) => demandesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(texte: 'Erreur : $e'),
          data: (demandes) {
            // Mes trajets à venir, du plus proche au plus lointain
            final maintenant = DateTime.now();
            final mesTrajets =
                tousLesTrajets
                    .where(
                      (t) =>
                          t.conducteurId == uid &&
                          t.dateDepart.isAfter(maintenant),
                    )
                    .toList()
                  ..sort((a, b) => a.dateDepart.compareTo(b.dateDepart));

            if (mesTrajets.isEmpty) {
              return const _Message(
                texte: 'Tu n’as aucun trajet à venir pour l’instant',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              children: [
                for (final t in mesTrajets) ...[
                  _CarteTrajet(
                    trajet: t,
                    // Les demandes qui concernent CE trajet
                    demandes: demandes
                        .where((d) => d.trajetId == t.id)
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Un trajet + ses demandes ──────────────────────────────────────

class _CarteTrajet extends StatelessWidget {
  final Trajet trajet;
  final List<Reservation> demandes;

  const _CarteTrajet({required this.trajet, required this.demandes});

  @override
  Widget build(BuildContext context) {
    final t = trajet;
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
          // En-tête du trajet
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.departZone} → ${t.arriveeZone}',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
                ),
              ),
              Text('${prixFr(t.prix)} F', style: AppTextStyles.price),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${dateFr(t.dateDepart)} · ${heureFr(t.dateDepart)}'
            ' · ${t.placesRestantes}/${t.placesTotal} places libres',
            style: AppTextStyles.bodySmall,
          ),
          const Divider(height: 24),

          Text(
            'DEMANDES REÇUES',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          if (demandes.isEmpty)
            Text(
              'Aucune demande pour l’instant',
              style: AppTextStyles.bodySmall,
            )
          else
            for (final d in demandes) ...[
              _CarteDemande(demande: d),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

// ── Une demande (avec ses boutons) ────────────────────────────────
// StatefulWidget car chaque demande a son propre état de chargement.

class _CarteDemande extends ConsumerStatefulWidget {
  final Reservation demande;

  const _CarteDemande({required this.demande});

  @override
  ConsumerState<_CarteDemande> createState() => _CarteDemandeState();
}

class _CarteDemandeState extends ConsumerState<_CarteDemande> {
  bool _enCours = false;

  Future<void> _accepter() async {
    setState(() => _enCours = true);
    try {
      await ref
          .read(reservationRepositoryProvider)
          .accepterReservation(widget.demande);
      _message('Demande acceptée');
    } on PlusDePlaceException {
      _message('Plus de place disponible');
    } catch (e) {
      _message('Erreur, réessaie');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _refuser() async {
    setState(() => _enCours = true);
    try {
      await ref
          .read(reservationRepositoryProvider)
          .refuserReservation(widget.demande);
      _message('Demande refusée');
    } catch (e) {
      _message('Erreur, réessaie');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;
    final nom = d.passagerNom.isEmpty ? 'Passager' : d.passagerNom;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar avec l'initiale du passager
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  nom[0].toUpperCase(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Avance ${prixFr(d.avance)} F · ${d.moyenPaiement}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              _Badge(etat: d.etat),
            ],
          ),

          // En attente -> boutons Accepter / Refuser
          if (d.etat == 'en_attente') ...[
            const SizedBox(height: 10),
            if (_enCours)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _refuser,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.dangerBorder),
                      ),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _accepter,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                      child: const Text('Accepter'),
                    ),
                  ),
                ],
              ),
          ],

          // Confirmée -> info (le vrai numéro viendra avec le profil passager)
          if (d.etat == 'confirmee') ...[
            const SizedBox(height: 8),
            Text(
              'Réservation confirmée · avance reçue : ${prixFr(d.avance)} F',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Badge d'état ──────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String etat;

  const _Badge({required this.etat});

  @override
  Widget build(BuildContext context) {
    // Texte + couleurs selon l'état de la réservation
    String texte;
    Color fond;
    Color couleur;
    switch (etat) {
      case 'en_attente':
        texte = 'En attente';
        fond = AppColors.accentSoft;
        couleur = AppColors.accentDark;
        break;
      case 'confirmee':
        texte = 'Acceptée';
        fond = AppColors.primarySoft;
        couleur = AppColors.primary;
        break;
      case 'refusee':
        texte = 'Refusée';
        fond = AppColors.neutralSoft;
        couleur = AppColors.textSecondary;
        break;
      case 'annulee':
        texte = 'Annulée';
        fond = AppColors.neutralSoft;
        couleur = AppColors.textSecondary;
        break;
      default:
        texte = 'Terminée';
        fond = AppColors.neutralSoft;
        couleur = AppColors.textSecondary;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texte,
        style: AppTextStyles.labelSmall.copyWith(color: couleur),
      ),
    );
  }
}

// Message centré (erreur ou liste vide)
class _Message extends StatelessWidget {
  final String texte;

  const _Message({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
