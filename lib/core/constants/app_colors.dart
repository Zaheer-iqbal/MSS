import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6C63FF); // Modern Indigo
  static const Color secondary = Color(0xFF3F3D56); // Dark Grey
  static const Color accent = Color(0xFFFF6584); // Soft Pink

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);

  // Role-specific colors (for dashboard headers/accents)
  static const Color schoolRole = Color(0xFF4834D4); // Deep Blue
  static const Color teacherRole = Color(0xFF22A6B3); // Teal
  static const Color headTeacherRole = Color(0xFFF0932B); // Orange
  static const Color parentRole = Color(0xFFEB4D4B); // Red

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1A1A2E); // Dark Navy
  static const Color cardDark = Color(0xFF16213E); // Slightly lighter navy for cards
  static const Color accentBlue = Color(0xFF4Ecca3); // Mint/Teal accent
  static const Color accentPurple = Color(0xFFBB86FC); // Light Purple
  static const Color textLight = Color(0xFFE94560); // Reddish Pink (accent) - wait, standard text should be white
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}
