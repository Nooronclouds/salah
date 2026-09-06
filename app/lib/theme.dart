import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "summer garden" palette (parchment / pistachio / melon / fern).
abstract final class GardenColors {
  static const parchment = Color(0xFFF7EFDA);
  static const paper = Color(0xFFFFFDF6); // card surface, a touch lighter
  static const pistachio = Color(0xFFBADD7F);
  static const melon = Color(0xFFEFACA5);
  static const fern = Color(0xFF3E8440);
  static const fernDeep = Color(0xFF2F6733);
  static const ink = Color(0xFF33432F); // primary text
  static const line = Color(0xFFD8CCA8); // dotted rules / dividers
  static const muted = Color(0xFF93A081); // times, secondary text
}

/// A warm garden-journal theme. Headings use a characterful serif; body text a
/// readable serif, both from Google Fonts.
ThemeData buildGardenTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: GardenColors.parchment,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GardenColors.fern,
      primary: GardenColors.fern,
      surface: GardenColors.parchment,
      brightness: Brightness.light,
    ),
  );

  final serif = GoogleFonts.loraTextTheme(base.textTheme).apply(
    bodyColor: GardenColors.ink,
    displayColor: GardenColors.fernDeep,
  );

  return base.copyWith(
    textTheme: serif.copyWith(
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: GardenColors.fernDeep,
      ),
      titleSmall: GoogleFonts.fraunces(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: GardenColors.fern,
      ),
    ),
  );
}
