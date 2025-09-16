import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
    bodyMedium: GoogleFonts.poppins(fontSize: 16),
    bodySmall: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
  );
}
