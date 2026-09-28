import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../reservations/data/reservation_repository.dart';
import '../../reservations/domain/reservation.dart';
import '../../reservations/pages/ma_reservation_screen.dart';
import '../../reservations/pages/reservation_screen.dart';
import '../domain/trajet.dart';

/// Écran « Détail d'un trajet » (maquette 1f).
/// On affiche seulement les infos du trajet reçu : aucune écriture Firestore.
class DetailTrajetScreen extends ConsumerWidget {
  final Trajet trajet;
  final Map<String, dynamic> profil; // profil du passager, pour la réservation

  const DetailTrajetScreen({
    super.key,
    required this.trajet,
    required this.profil,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = trajet;
    final nom = t.conducteurNom.isEmpty ? 'Conducteur' : t.conducteurNom;
    // true si l'utilisateur connecté est le conducteur de ce trajet
    final estMonTrajet =
        t.conducteurId == FirebaseAuth.instance.currentUser?.uid;

    // Ma réservation sur CE trajet, si j'en ai déjà fait une
    // (on ignore celles que j'ai moi-même annulées)
    final mesReservations =
        ref.watch(mesReservationsProvider).valueOrNull ?? [];
    final maReservation = mesReservations
        .where((r) => r.trajetId == t.id && r.etat != 'annulee')
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail du trajet'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        children: [
          // ── Conducteur ──
          _Bloc(
            child: Row(
              children: [
                _Avatar(initiale: nom[0].toUpperCase()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nom, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text(
                            '★',
                            style: TextStyle(color: AppColors.accent),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _noteFr(t.conducteurNote),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '· ${t.conducteurStatut}',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Itinéraire départ → arrivée ──
          _Bloc(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ITINÉRAIRE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _Etape(
                  heure: _heureFr(t.dateDepart),
                  zone: t.departZone,
                  point: t.departPoint,
                  estDepart: true,
                ),
                // Petit trait vertical qui relie le départ et l'arrivée
                Container(
                  margin: const EdgeInsets.only(left: 57, top: 2, bottom: 2),
                  width: 2,
                  height: 22,
                  color: AppColors.primaryBorder,
                ),
                _Etape(
                  heure: '',
                  zone: t.arriveeZone,
                  point: t.arriveePoint,
                  estDepart: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Infos pratiques ──
          _Bloc(
            child: Column(
              children: [
                _Ligne(
                  icone: Icons.calendar_today_outlined,
                  label: 'Date',
                  valeur: _dateFr(t.dateDepart),
                ),
                const Divider(height: 20),
                _Ligne(
                  icone: Icons.event_seat_outlined,
                  label: 'Places restantes',
                  valeur: '${t.placesRestantes} / ${t.placesTotal}',
                ),
                const Divider(height: 20),
                _Ligne(
                  icone: Icons.directions_car_outlined,
                  label: 'Véhicule',
                  valeur: _vehicule(t),
                ),
              ],
            ),
          ),

          // ── Notes du conducteur (seulement s'il y en a) ──
          if (t.notes != null && t.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Bloc(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTES DU CONDUCTEUR',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t.notes!, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // ── Encadré ocre : numéro masqué ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.accentDark,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+221 77 •• •• ••',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Le numéro du conducteur sera visible une fois '
                        'votre réservation acceptée.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Barre du bas : prix + bouton Réserver ──
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prix par place', style: AppTextStyles.bodySmall),
                    Text(
                      '${_prixFr(t.prix)} F',
                      style: AppTextStyles.price.copyWith(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  // Mon trajet → badge non cliquable à la place du bouton
                  child: estMonTrajet
                      ? Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_car_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "C'est votre trajet",
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      // Déjà réservé → on montre l'état au lieu de Réserver
                      : maReservation != null
                      ? _EtatMaReservation(reservation: maReservation)
                      : ElevatedButton(
                          // Pas de place → bouton désactivé
                          onPressed: t.placesRestantes > 0
                              ? () {
                                  // Ouvre l'écran de réservation avec avance
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReservationScreen(
                                        trajet: t,
                                        profil: profil,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            t.placesRestantes > 0
                                ? 'Réserver ma place'
                                : 'Complet',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Petits widgets de l'écran ─────────────────────────────────────

/// Remplace le bouton « Réserver » quand j'ai déjà réservé ce trajet.
/// Cliquable : ouvre le suivi de ma réservation.
class _EtatMaReservation extends StatelessWidget {
  final Reservation reservation;

  const _EtatMaReservation({required this.reservation});

  @override
  Widget build(BuildContext context) {
    // Texte et couleurs selon l'état
    String texte;
    Color couleur;
    Color fond;
    Color bordure;
    switch (reservation.etat) {
      case 'confirmee':
        texte = 'Réservation acceptée';
        couleur = AppColors.primary;
        fond = AppColors.primarySoft;
        bordure = AppColors.primaryBorder;
        break;
      case 'refusee':
        texte = 'Demande refusée';
        couleur = AppColors.danger;
        fond = AppColors.dangerSoft;
        bordure = AppColors.dangerBorder;
        break;
      default: // en_attente (ou terminee)
        texte = 'Demande en attente';
        couleur = AppColors.accentDark;
        fond = AppColors.accentSoft;
        bordure = AppColors.accentBorder;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MaReservationScreen(reservationId: reservation.id),
        ),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bordure),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                texte,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: couleur),
          ],
        ),
      ),
    );
  }
}

/// Carte blanche avec bordure, utilisée pour chaque section.
class _Bloc extends StatelessWidget {
  final Widget child;

  const _Bloc({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Une étape de l'itinéraire : heure, pastille, zone + point de rendez-vous.
class _Etape extends StatelessWidget {
  final String heure;
  final String zone;
  final String point;
  final bool estDepart;

  const _Etape({
    required this.heure,
    required this.zone,
    required this.point,
    required this.estDepart,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            heure,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Pastille pleine pour le départ, vide pour l'arrivée
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: estDepart ? AppColors.primary : AppColors.surface,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zone, style: AppTextStyles.titleMedium),
              if (point.isNotEmpty) Text(point, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ligne « icône · label ........ valeur ».
class _Ligne extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const _Ligne({
    required this.icone,
    required this.label,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            valeur,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initiale;

  const _Avatar({required this.initiale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        initiale,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primary,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ── Fonctions de mise en forme ────────────────────────────────────

const _jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

// Ex : "Lundi 28 septembre"
String _dateFr(DateTime d) =>
    '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';

// Ex : "17h45"
String _heureFr(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

// Ex : 4.8 -> "4,8"
String _noteFr(double note) => note.toStringAsFixed(1).replaceAll('.', ',');

// Ex : 1500 -> "1 500"
String _prixFr(int prix) {
  final s = prix.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

// Ex : "Toyota Corolla · DK-1234-AB" (on n'affiche que ce qui est rempli)
String _vehicule(Trajet t) {
  final morceaux = [
    if (t.typeVehicule != null && t.typeVehicule!.trim().isNotEmpty)
      t.typeVehicule!,
    if (t.immatriculation.isNotEmpty) t.immatriculation,
  ];
  return morceaux.isEmpty ? 'Non précisé' : morceaux.join(' · ');
}
