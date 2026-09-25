import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profil_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/data/auth_providers.dart'; 

class VerificationScreen extends ConsumerStatefulWidget {
  final String telephone; // format complet : "+221771234567"
  final String verificationId;

  const VerificationScreen({
    super.key,
    required this.telephone,
    required this.verificationId,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  static const _longueurCode = 6;
  static const _delaiRenvoi = 60; // secondes, identique au timeout de verifyPhoneNumber

  final _controllers =
      List.generate(_longueurCode, (_) => TextEditingController());
  final _focusNodes = List.generate(_longueurCode, (_) => FocusNode());

  late String _verificationId; // peut changer si on renvoie le code
  Timer? _timer;
  int _secondesRestantes = _delaiRenvoi;
  bool _chargement = false;
  bool _renvoiEnCours = false;

  String get _code => _controllers.map((c) => c.text).join();

  String get _minuteurLabel =>
      '00:${_secondesRestantes.toString().padLeft(2, '0')}';

  String get _telephoneAffiche {
    final n = widget.telephone.replaceFirst('+221', '');
    if (n.length != 9) return widget.telephone;
    return '+221 ${n.substring(0, 2)} ${n.substring(2, 5)} '
        '${n.substring(5, 7)} ${n.substring(7)}';
  }

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _demarrerMinuteur();
    // Ouvre le clavier sur la première case dès l'affichage
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes.first.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _demarrerMinuteur() {
    _timer?.cancel();
    _secondesRestantes = _delaiRenvoi;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondesRestantes == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondesRestantes--);
    });
  }

  void _onChiffreChange(int index, String valeur) {
    if (valeur.length > 1) {
      // Collage d'un code (ou autofill SMS) : on répartit les chiffres
      for (var i = 0; i < valeur.length && index + i < _longueurCode; i++) {
        _controllers[index + i].text = valeur[i];
      }
      final suivant =
          (index + valeur.length).clamp(0, _longueurCode - 1);
      _focusNodes[suivant].requestFocus();
    } else if (valeur.isNotEmpty && index < _longueurCode - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (valeur.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
    if (_code.length == _longueurCode) _verifier(); // vérif auto à 6 chiffres
  }

  void _viderCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  Future<void> _verifier() async {
    if (_code.length != _longueurCode || _chargement) return;

    FocusScope.of(context).unfocus();
    setState(() => _chargement = true);

    try {
      await ref.read(authRepositoryProvider).verifierCode(
            verificationId: _verificationId,
            code: _code,
          );

      if (!mounted) return;
      
      Navigator.popUntil(context, (route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _viderCode();
      _afficherMessage(_messageErreur(e));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _renvoyerCode() async {
    setState(() => _renvoiEnCours = true);

    await ref.read(authRepositoryProvider).envoyerCode(
          telephone: widget.telephone,
          onCodeEnvoye: (nouvelId) {
            if (!mounted) return;
            setState(() {
              _verificationId = nouvelId;
              _renvoiEnCours = false;
              _demarrerMinuteur();
            });
            _viderCode();
            _afficherMessage('Nouveau code envoyé');
          },
          onErreur: (e) {
            if (!mounted) return;
            setState(() => _renvoiEnCours = false);
            _afficherMessage(_messageErreur(e));
          },
        );
  }

  String _messageErreur(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Code incorrect, vérifiez et réessayez';
      case 'session-expired':
        return 'Le code a expiré, demandez-en un nouveau';
      case 'too-many-requests':
        return 'Trop de tentatives, réessayez plus tard';
      default:
        return 'Une erreur est survenue, réessayez';
    }
  }

  void _afficherMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final peutRenvoyer = _secondesRestantes == 0 && !_renvoiEnCours;

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SafeArea(
        // SliverFillRemaining permet d'utiliser Spacer tout en restant
        // scrollable quand le clavier est ouvert
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ÉTAPE 2 SUR 2', style: textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text('Entrez le code reçu',
                        style: textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Code envoyé au ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(_telephoneAffiche,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Modifier',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Les 6 cases
                    Row(
                      children: List.generate(_longueurCode, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: i < _longueurCode - 1 ? 8 : 0),
                            child: SizedBox(
                              height: 60,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                enabled: !_chargement,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                expands: true,
                                maxLines: null,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) => _onChiffreChange(i, v),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Minuteur
                    Center(
                      child: _secondesRestantes > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Renvoyer le code dans ',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                                Text(_minuteurLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            )
                          : const Text(
                              'Vous pouvez demander un nouveau code',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                    ),
                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _code.length == _longueurCode && !_chargement
                            ? _verifier
                            : null,
                        child: _chargement
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Vérifier'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: peutRenvoyer ? _renvoyerCode : null,
                        child: _renvoiEnCours
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Renvoyer par SMS'),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Rien reçu ? Vérifiez votre réseau, puis demandez un '
                        'nouveau code. Le code expire après 10 minutes.',
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}