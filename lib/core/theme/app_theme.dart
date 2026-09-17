import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Couleur principale — génère automatiquement toute la ColorScheme Material
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.danger,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: AppColors.background,

        // Applique DM Sans à TOUT le texte de l'app
        textTheme: GoogleFonts.dmSansTextTheme().apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),

        // ---- AppBar (barre du haut avec bouton retour + titre) ----
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),

        // ---- Bouton principal vert (ElevatedButton) ----
        // Utilisé pour "Recevoir le code", "Confirmer", "Réserver ma place"...
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.borderStrong,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        // ---- Bouton secondaire avec bordure (OutlinedButton) ----
        // Utilisé pour "Garder ma réservation", "Renvoyer par SMS"...
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.border, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ---- Bouton texte (TextButton) ----
        // Utilisé pour les liens "Modifier", "Se connecter", "Tout voir"...
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),

        // ---- Champs de saisie (TextField) ----
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          labelStyle: AppTextStyles.bodySmall,

          // État par défaut (pas focus)
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),

          // État focus (curseur dans le champ)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),

          // État erreur
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),

        // ---- Cartes (Card) ----
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),

        // ---- Diviseurs (Divider) ----
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),

        // ---- Bottom navigation bar ----
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // ---- Icônes par défaut ----
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      );
}