import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/data/auth_providers.dart';
import '../../core/utils/formats.dart';
import '../reservations/data/reservation_repository.dart';
import '../reservations/domain/reservation.dart';
import '../reservations/pages/ma_reservation_screen.dart';
import '../reservations/pages/mes_reservations_screen.dart';
import '../trajets/pages/detail_trajet_screen.dart';
import '../trajets/pages/publier_screen.dart';
import '../trajets/domain/trajet.dart';
import '../trajets/data/trajet_repository.dart';

/// Accueil (maquette 1d) : en-tête, prochain trajet, trajets suggérés,
/// barre de navigation Accueil / Rechercher / Publier / Profil.
class AccueilScreen extends StatefulWidget {
  final Map<String, dynamic> profil;

  const AccueilScreen({super.key, required this.profil});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final onglets = [
      _AccueilTab(profil: widget.profil),
      const _Bientot(icone: Icons.search, message: 'Recherche de trajets'),
      PublierScreen(profil: widget.profil),
      _ProfilTab(profil: widget.profil),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: onglets[_index]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _NavItem(
                  icone: Icons.home_outlined,
                  iconeActive: Icons.home,
                  label: 'Accueil',
                  actif: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icone: Icons.search,
                  iconeActive: Icons.search,
                  label: 'Rechercher',
                  actif: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icone: Icons.add_circle_outline,
                  iconeActive: Icons.add_circle,
                  label: 'Publier',
                  actif: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icone: Icons.person_outline,
                  iconeActive: Icons.person,
                  label: 'Profil',
                  actif: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icone;
  final IconData iconeActive;
  final String label;
  final bool actif;
  final VoidCallback onTap;

  const _NavItem({
    required this.icone,
    required this.iconeActive,
    required this.label,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(actif ? iconeActive : icone, color: couleur, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: couleur,
                fontSize: 11,
                fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet Accueil ──────────────────────────────────────────────

class _AccueilTab extends ConsumerWidget {
  final Map<String, dynamic> profil;

  const _AccueilTab({required this.profil});

  static const _jours = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
  ];
  static const _mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
    'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String get _dateDuJour {
    final now = DateTime.now();
    return '${_jours[now.weekday - 1]} ${now.day} ${_mois[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prenom = (profil['prenom'] as String?) ?? '';
final trajetsAsync = ref.watch(trajetsProvider);
    // Ma réservation la plus récente pour un trajet à venir
    // (la liste est déjà triée : la plus récente en premier)
    final mesReservations = ref.watch(mesReservationsProvider).valueOrNull ?? [];
    final maReservation = mesReservations
        .where((r) =>
            r.etat != 'annulee' && r.dateDepart.isAfter(DateTime.now()))
        .firstOrNull;
    // TODO : remplacer ces exemples par les trajets Firestore
    const suggeres = [
      _Trajet(
        conducteur: 'Fatou Sarr',
        note: '4,9',
        profil: 'Personnel administratif',
        prix: '1 500 F',
        places: '3 places',
        depart: 'Diamniadio',
        arrivee: 'Pikine',
        detail: '17h45 · Rond-point UAM → Tally Boubess',
      ),
      _Trajet(
        conducteur: 'Cheikh Fall',
        note: '4,7',
        profil: 'Étudiant · Master 1',
        prix: '2 000 F',
        places: '1 place',
        depart: 'Diamniadio',
        arrivee: 'Dakar-Plateau',
        detail: "18h00 · Entrée principale UAM → Place de l'Indépendance",
      ),
      _Trajet(
        conducteur: 'Ndèye Bâ',
        note: '4,8',
        profil: 'Enseignante',
        prix: '1 000 F',
        places: '2 places',
        depart: 'Diamniadio',
        arrivee: 'Rufisque',
        detail: '18h15 · Rond-point UAM → Gare de Rufisque',
      ),
    ];

    return Column(
      children: [
        // En-tête
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateDuJour,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bonjour, $prenom',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: AppColors.textPrimary, size: 22),
                  ),
                  Positioned(
                    top: 8,
                    right: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              _Avatar(
                taille: 38,
                initiale: prenom.isEmpty ? '?' : prenom[0].toUpperCase(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            children: [
              // Ma réservation à venir (cachée si je n'en ai pas)
              if (maReservation != null) ...[
                _ProchainTrajet(reservation: maReservation),
                const SizedBox(height: 14),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trajets suggérés',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 20)),
                  Text(
                    'Tout voir',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
trajetsAsync.when(
  loading: () => const Padding(
    padding: EdgeInsets.all(20),
    child: Center(child: CircularProgressIndicator()),
  ),
  error: (e, _) => Padding(
    padding: const EdgeInsets.all(20),
    child: Text(
'Erreur : $e',     
 style: AppTextStyles.bodyMedium
          .copyWith(color: AppColors.textSecondary),
    ),
  ),
  data: (trajets) {
    // On retire MES propres trajets : on ne se réserve pas soi-même
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final visibles = trajets.where((t) => t.conducteurId != uid).toList();

    if (visibles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Aucun trajet publié pour le moment',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        for (final t in visibles) ...[
          _CarteTrajet(
            trajet: _versUi(t),
            // On passe le vrai Trajet (pas le modèle d'affichage) au détail
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DetailTrajetScreen(trajet: t, profil: profil),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  },
),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carte verte en haut de l'accueil : MA dernière réservation (vraie donnée
/// Firestore). Cliquable -> écran de suivi « Ma réservation ».
class _ProchainTrajet extends StatelessWidget {
  final Reservation reservation;

  const _ProchainTrajet({required this.reservation});

  // Libellé du badge selon l'état
  String get _badge {
    switch (reservation.etat) {
      case 'confirmee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final blanc85 = Colors.white.withValues(alpha: 0.85);
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MaReservationScreen(reservationId: r.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MA RÉSERVATION',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: blanc85,
                      letterSpacing: 0.7,
                    ),
                  ),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // Refusée -> badge rouge pour bien la voir
                      color: r.etat == 'refusee'
                          ? AppColors.danger
                          : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _badge,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                r.trajetResume,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${dateFr(r.dateDepart)} · ${heureFr(r.dateDepart)}',
                style: AppTextStyles.bodyMedium.copyWith(color: blanc85),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Avance versée : ${_prixFr(r.avance)} F',
                      style: AppTextStyles.bodySmall.copyWith(color: blanc85),
                    ),
                  ),
                  Text(
                    'Voir',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Trajet {
  final String conducteur;
  final String note;
  final String profil;
  final String prix;
  final String places;
  final String depart;
  final String arrivee;
  final String detail;

  const _Trajet({
    required this.conducteur,
    required this.note,
    required this.profil,
    required this.prix,
    required this.places,
    required this.depart,
    required this.arrivee,
    required this.detail,
  });
}

/// Carte-trajet (réutilisée sur l'accueil, la recherche et les listes).
class _CarteTrajet extends StatelessWidget {
  final _Trajet trajet;
  final VoidCallback? onTap; // action au tap sur la carte (ouvrir le détail)

  const _CarteTrajet({required this.trajet, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Material + InkWell : la carte devient cliquable avec l'effet d'onde
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(taille: 44, initiale: trajet.conducteur[0]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trajet.conducteur,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text('★',
                            style: TextStyle(color: AppColors.accent)),
                        const SizedBox(width: 6),
                        Text(
                          trajet.note,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${trajet.profil}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(trajet.prix,
                      style:
                          AppTextStyles.price.copyWith(color: AppColors.accent)),
                  const SizedBox(height: 2),
                  Text(
                    trajet.places,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  trajet.depart,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text('→',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  trajet.arrivee,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trajet.detail,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double taille;
  final String initiale;

  const _Avatar({required this.taille, required this.initiale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        initiale,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Autres onglets ──────────────────────────────────────────────

class _Bientot extends StatelessWidget {
  final IconData icone;
  final String message;

  const _Bientot({required this.icone, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 40, color: AppColors.borderStrong),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Bientôt disponible',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfilTab extends ConsumerWidget {
  final Map<String, dynamic> profil;

  const _ProfilTab({required this.profil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nom = '${profil['prenom'] ?? ''} ${profil['nom'] ?? ''}'.trim();
    final detail = (profil['filiereOuService'] as String?) ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: _Avatar(
            taille: 72,
            initiale: nom.isEmpty ? '?' : nom[0].toUpperCase(),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(nom, style: AppTextStyles.titleMedium)),
        if (detail.isNotEmpty)
          Center(
            child: Text(
              detail,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        const SizedBox(height: 32),
        // Accès à l'historique de mes réservations (passager)
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MesReservationsScreen()),
          ),
          icon: const Icon(Icons.confirmation_number_outlined),
          label: const Text('Mes réservations'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ref.read(authRepositoryProvider).deconnexion(),
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: Text(
            'Se déconnecter',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.dangerBorder),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}


// Transforme un Trajet (Firestore) en _Trajet (affichage de la carte).
_Trajet _versUi(Trajet t) {
  return _Trajet(
    conducteur: t.conducteurNom.isEmpty ? 'Conducteur' : t.conducteurNom,
    note: _noteFr(t.conducteurNote),
    profil: t.conducteurStatut,
    prix: '${_prixFr(t.prix)} F',
    places: '${t.placesRestantes} place${t.placesRestantes > 1 ? 's' : ''}',
    depart: t.departZone,
    arrivee: t.arriveeZone,
    detail: '${_heureFr(t.dateDepart)} · ${t.departPoint} → ${t.arriveePoint}',
  );
}

String _prixFr(int prix) {
  final s = prix.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString(); // 1500 -> "1 500"
}

String _noteFr(double note) => note.toStringAsFixed(1).replaceAll('.', ',');

String _heureFr(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';