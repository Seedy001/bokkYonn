import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Titre principal — 24px 700
  // Ex : "Créer un compte", "Réservation en attente"
  static TextStyle displayLarge = GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  // Titre d'écran — 20px 700
  // Ex : "Rechercher un trajet", "Trajets suggérés", "Mes réservations"
  static TextStyle titleLarge = GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Titre de carte — 15px 700
  // Ex : nom du conducteur sur une carte trajet, "Diamniadio → Guédiawaye"
  static TextStyle titleMedium = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Texte principal — 15px 500
  // Ex : contenu des inputs, labels de boutons, texte dans les cartes
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Texte courant — 15px 400
  // Ex : paragraphes explicatifs
  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Texte secondaire — 13px 400
  // Ex : "Enseignant · Toyota Corolla", hints, dates, meta
  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  // Badges et labels de section — 12px 600
  // Ex : "EN ATTENTE", "CONFIRMÉE", "ÉTAPE 1 SUR 2", "DEMANDES REÇUES"
  static TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.06 * 12, // équivalent CSS letter-spacing: .06em
  );

  // Prix — 15px 700, couleur ocre
  // Ex : "1 500 F", "2 000 F"
  static TextStyle price = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  // Bonus : prix grande taille (écran de paiement)
  // Ex : le "300 FCFA" au centre de l'écran de réservation
  static TextStyle priceLarge = GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
}