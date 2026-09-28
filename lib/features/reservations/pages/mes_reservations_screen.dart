import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formats.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';

/// Écran passager « Mes réservations » (maquette 1l).
/// Une carte par réservation, colorée selon son état.
class MesReservationsScreen extends ConsumerWidget {
  const MesReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(mesReservationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes réservations'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(texte: 'Erreur : $e'),
        data: (reservations) {
          if (reservations.isEmpty) {
            return const _Message(texte: 'Aucune réservation pour l’instant');
          }

          // Tri par date de départ : la plus lointaine en haut
          // (toList() = copie, on ne modifie pas la liste du provider)
          final triees = reservations.toList()
            ..sort((a, b) => b.dateDepart.compareTo(a.dateDepart));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            itemCount: triees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _CarteReservation(reservation: triees[i]),
          );
        },
      ),
    );
  }
}

// ── Style selon l'état ────────────────────────────────────────────

/// Regroupe le texte du badge et ses couleurs pour un état donné.
class _StyleEtat {
  final String badge;
  final Color couleur; // barre de gauche + texte du badge
  final Color fond; // fond du badge

  const _StyleEtat(this.badge, this.couleur, this.fond);

  factory _StyleEtat.depuis(String etat) {
    switch (etat) {
      case 'confirmee':
        return const _StyleEtat(
          'CONFIRMÉE',
          AppColors.primary,
          AppColors.primarySoft,
        );
      case 'annulee':
        return const _StyleEtat(
          'ANNULÉE',
          AppColors.danger,
          AppColors.dangerSoft,
        );
      case 'refusee':
        return const _StyleEtat(
          'REFUSÉE',
          AppColors.danger,
          AppColors.dangerSoft,
        );
      case 'terminee':
        return const _StyleEtat(
          'TERMINÉE',
          AppColors.textSecondary,
          AppColors.neutralSoft,
        );
      default: // en_attente
        return const _StyleEtat(
          'EN ATTENTE',
          AppColors.accentDark,
          AppColors.accentSoft,
        );
    }
  }
}

// ── Carte d'une réservation ───────────────────────────────────────

class _CarteReservation extends ConsumerWidget {
  final Reservation reservation;

  const _CarteReservation({required this.reservation});

  // Boîte de confirmation avant d'annuler
  Future<void> _annuler(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: Text(
          'L’avance de ${prixFr(reservation.avance)} F reste acquise '
          'au conducteur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Confirmer l’annulation'),
          ),
        ],
      ),
    );

    if (confirme != true) return; // "Garder" ou tap à côté

    try {
      await ref
          .read(reservationRepositoryProvider)
          .annulerReservation(reservation);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Réservation annulée')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur, réessaie')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reservation;
    final style = _StyleEtat.depuis(r.etat);
    final peutAnnuler = r.etat == 'en_attente' || r.etat == 'confirmee';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      // ClipRRect : la barre de couleur suit les coins arrondis
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barre de couleur à gauche
              Container(width: 5, color: style.couleur),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trajet + badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.trajetResume,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: style.fond,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              style.badge,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: style.couleur,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFr(r.dateDepart)} · ${heureFr(r.dateDepart)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avance versée : ${prixFr(r.avance)} F '
                        '(${r.moyenPaiement})',
                        style: AppTextStyles.bodySmall,
                      ),

                      // Confirmée -> nom + vrai numéro du conducteur
                      if (r.etat == 'confirmee') ...[
                        const Divider(height: 20),
                        _ContactConducteur(conducteurId: r.conducteurId),
                      ],

                      // Terminée -> lien pour noter
                      if (r.etat == 'terminee')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            // TODO : écran de notation plus tard
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notation bientôt disponible',
                                    ),
                                  ),
                                ),
                            child: const Text('Noter le trajet'),
                          ),
                        ),

                      // En attente / confirmée -> bouton Annuler
                      if (peutAnnuler) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _annuler(context, ref),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(
                              color: AppColors.dangerBorder,
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact du conducteur (réservation confirmée) ─────────────────
// StatefulWidget : on lit le profil UNE seule fois (dans initState),
// sinon le FutureBuilder relancerait la lecture à chaque rebuild.

class _ContactConducteur extends StatefulWidget {
  final String conducteurId;

  const _ContactConducteur({required this.conducteurId});

  @override
  State<_ContactConducteur> createState() => _ContactConducteurState();
}

class _ContactConducteurState extends State<_ContactConducteur> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _profil;

  @override
  void initState() {
    super.initState();
    // Lecture ponctuelle (get, pas un stream) du profil du conducteur
    _profil = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.conducteurId)
        .get();
  }

  // TODO : remplacer par url_launcher -> launchUrl(Uri.parse('tel:$numero'))
  void _appeler(String numero) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Appeler le conducteur : $numero')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _profil,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        }

        final data = snapshot.data?.data();
        final numero = (data?['telephone'] as String?) ?? '';
        final nom = '${data?['prenom'] ?? ''} ${data?['nom'] ?? ''}'.trim();

        if (snapshot.hasError || numero.isEmpty) {
          return Text(
            'Numéro du conducteur indisponible',
            style: AppTextStyles.bodySmall,
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom.isEmpty ? 'Conducteur' : nom,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(numero, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _appeler(numero),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Appeler'),
            ),
          ],
        );
      },
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
