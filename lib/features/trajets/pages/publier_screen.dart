import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../reservations/pages/demandes_recues_screen.dart';
import '../data/trajet_repository.dart';
import '../domain/trajet.dart';

/// Écran « Publier un trajet » (maquette 1i).
/// Le conducteur remplit le formulaire, on enregistre le trajet dans Firestore.
class PublierScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> profil;

  const PublierScreen({super.key, required this.profil});

  @override
  ConsumerState<PublierScreen> createState() => _PublierScreenState();
}

class _PublierScreenState extends ConsumerState<PublierScreen> {
  // 'versVille' = Diamniadio → Ville · 'versDiamniadio' = Ville → Diamniadio
  String _sens = 'versVille';

  final _departZone = TextEditingController();
  final _departPoint = TextEditingController();
  final _arriveeZone = TextEditingController();
  final _arriveePoint = TextEditingController();
  final _prix = TextEditingController();
  final _vehicule = TextEditingController();
  final _notes = TextEditingController();
  final _immatriculation = TextEditingController();

  DateTime? _date;
  TimeOfDay? _heure;
  int _places = 3;
  bool _enCours = false;

  @override
  void dispose() {
    _departZone.dispose();
    _departPoint.dispose();
    _arriveeZone.dispose();
    _arriveePoint.dispose();
    _prix.dispose();
    _vehicule.dispose();
    _notes.dispose();
    _immatriculation.dispose();
    super.dispose();
  }

  // ── Sélecteurs date / heure ──────────────────────────────────

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final choix = await showDatePicker(
      context: context,
      initialDate: maintenant,
      firstDate: maintenant,
      lastDate: maintenant.add(const Duration(days: 365)),
    );
    if (choix != null) setState(() => _date = choix);
  }

  Future<void> _choisirHeure() async {
    final choix = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (choix != null) setState(() => _heure = choix);
  }

  String _deux(int n) => n.toString().padLeft(2, '0');

  // ── Publication ──────────────────────────────────────────────

  Future<void> _publier() async {
    // 1. Vérifications simples
    if (_departZone.text.trim().isEmpty ||
        _departPoint.text.trim().isEmpty ||
        _arriveeZone.text.trim().isEmpty ||
        _arriveePoint.text.trim().isEmpty) {
      _message('Remplis les lieux de départ et d’arrivée');
      return;
    }
    if (_date == null || _heure == null) {
      _message('Choisis la date et l’heure');
      return;
    }
    final prix = int.tryParse(_prix.text.trim()) ?? 0;
    if (prix <= 0) {
      _message('Indique un prix par place');
      return;
    }
    if (_immatriculation.text.trim().isEmpty) {
      _message('Indique l’immatriculation du véhicule');
      return;
    }
    // 2. On combine la date et l’heure en une seule valeur
    final dateDepart = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _heure!.hour,
      _heure!.minute,
    );

    // 3. On construit le trajet
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final trajet = Trajet(
      id: '', // Firestore génère l’id tout seul
      conducteurId: uid,
      conducteurNom:
          '${widget.profil['prenom'] ?? ''} ${widget.profil['nom'] ?? ''}'
              .trim(),
      conducteurStatut: (widget.profil['filiereOuService'] as String?) ?? '',
      conducteurNote: (widget.profil['noteMoyenne'] as num?)?.toDouble() ?? 5.0,
      conducteurPhotoUrl: widget.profil['photoUrl'] as String?,
      sens: _sens,
      departZone: _departZone.text.trim(),
      departPoint: _departPoint.text.trim(),
      arriveeZone: _arriveeZone.text.trim(),
      arriveePoint: _arriveePoint.text.trim(),
      dateDepart: dateDepart,
      placesTotal: _places,
      placesRestantes: _places, // au départ, toutes les places sont libres
      prix: prix,
      immatriculation: _immatriculation.text.trim(),
      typeVehicule: _vehicule.text.trim().isEmpty
          ? null
          : _vehicule.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: DateTime.now(),
    );

    // 4. On enregistre dans Firestore
    setState(() => _enCours = true);
    try {
      await ref.read(trajetRepositoryProvider).publierTrajet(trajet);
      if (!mounted) return;
      _message('Trajet publié ✓');
      _reinitialiser();
    } catch (e) {
      if (!mounted) return;
      _message('Erreur, réessaie');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _reinitialiser() {
    _departZone.clear();
    _departPoint.clear();
    _arriveeZone.clear();
    _arriveePoint.clear();
    _prix.clear();
    _vehicule.clear();
    _notes.clear();
    setState(() {
      _date = null;
      _heure = null;
      _places = 3;
      _sens = 'versVille';
    });
    _immatriculation.clear();
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  // ── Interface ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête
        Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(18, 12, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Publier un trajet',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                ),
              ),
              // Accès à l'espace conducteur : mes trajets + demandes reçues
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DemandesRecuesScreen(),
                  ),
                ),
                icon: const Icon(Icons.inbox_outlined, size: 18),
                label: const Text('Mes trajets'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              _toggleSens(),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: _champ('Zone de départ', _departZone)),
                  const SizedBox(width: 8),
                  Expanded(child: _champ('Point de rendez-vous', _departPoint)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _champ('Zone d’arrivée', _arriveeZone)),
                  const SizedBox(width: 8),
                  Expanded(child: _champ('Point de dépôt', _arriveePoint)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _selecteur(
                      'Date de départ',
                      _date == null
                          ? 'Choisir'
                          : '${_deux(_date!.day)}/${_deux(_date!.month)}/${_date!.year}',
                      _choisirDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _selecteur(
                      'Heure',
                      _heure == null
                          ? 'Choisir'
                          : '${_deux(_heure!.hour)}h${_deux(_heure!.minute)}',
                      _choisirHeure,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _compteurPlaces()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _champ(
                      'Prix par place (FCFA)',
                      _prix,
                      nombre: true,
                      hint: 'ex. 1500',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _champ(
                'Immatriculation',
                _immatriculation,
                hint: 'ex. DK-1234-AB',
              ),
              const SizedBox(height: 12),
              _champ(
                'Véhicule (optionnel)',
                _vehicule,
                hint: 'ex. Toyota Corolla',
              ),
              const SizedBox(height: 12),
              _champ(
                'Notes (optionnel)',
                _notes,
                hint: 'ex. départ à l’heure, un bagage',
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _enCours ? null : _publier,
                  child: _enCours
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Publier le trajet'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bouton à deux positions pour le sens du trajet
  Widget _toggleSens() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment('Diamniadio → Ville', 'versVille'),
          _segment('Ville → Diamniadio', 'versDiamniadio'),
        ],
      ),
    );
  }

  Widget _segment(String label, String valeur) {
    final actif = _sens == valeur;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sens = valeur),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: actif ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: actif ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Champ texte avec son petit label au-dessus
  Widget _champ(
    String label,
    TextEditingController controller, {
    bool nombre = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: nombre ? TextInputType.number : TextInputType.text,
          inputFormatters: nombre
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  // Case cliquable qui ouvre un sélecteur (date ou heure)
  Widget _selecteur(String label, String valeur, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              valeur,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Compteur de places avec les boutons − et +
  Widget _compteurPlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Places',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _places > 1 ? () => setState(() => _places--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$_places', style: AppTextStyles.titleMedium),
              IconButton(
                onPressed: _places < 6 ? () => setState(() => _places++) : null,
                icon: const Icon(Icons.add, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
