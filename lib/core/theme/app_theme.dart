import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB); // Trust Blue
  static const Color bgGradientStart = Color(0xFF0F172A); // Deep Navy
  static const Color bgGradientEnd = Color(0xFF6D28D9); // Royal Purple
  static const Color glassWhite = Colors.white;
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
}

class AppTextStyles {
  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static TextStyle subHeading = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.white70,
  );
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
