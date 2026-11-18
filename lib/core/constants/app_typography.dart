import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLg => GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.02 * 48,
      );

  static TextStyle get headlineLg => GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.01 * 32,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
      );

  static TextStyle get headlineMd => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get bodyLg => GoogleFonts.archivoNarrow(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get bodyMd => GoogleFonts.archivoNarrow(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get labelSm => GoogleFonts.archivoNarrow(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // Numbers/progress - heavy Montserrat
  static TextStyle get numberLg => GoogleFonts.montserrat(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        height: 1.1,
      );

  static TextStyle get numberMd => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
      );

  static TextStyle get numberSm => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
}
