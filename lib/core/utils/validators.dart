import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Centralized validation logic for the BuildMatch app.
/// Dibagi per section dengan komentar pemisah agar mudah ditemukan.
class AppValidators {
  AppValidators._();

  // ════════════════════════════════════════════════════
  // SECTION 1: Email Validation
  // ════════════════════════════════════════════════════

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  static bool isValidEmail(String email) => _emailRegex.hasMatch(email);

  // ════════════════════════════════════════════════════
  // SECTION 2: Password Strength
  // ════════════════════════════════════════════════════

  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  static String getStrengthLabel(int score) {
    switch (score) {
      case 1:
        return 'Lemah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat';
      default:
        return '';
    }
  }

  static Color getStrengthColor(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.successDark;
      default:
        return Colors.grey.shade300;
    }
  }

  static List<Map<String, dynamic>> getPasswordChecklist(String password) {
    return [
      {'label': 'Minimal 8 karakter', 'valid': password.length >= 8},
      {
        'label': 'Mengandung huruf besar',
        'valid': RegExp(r'[A-Z]').hasMatch(password),
      },
      {
        'label': 'Mengandung angka',
        'valid': RegExp(r'[0-9]').hasMatch(password),
      },
      {
        'label': 'Mengandung karakter khusus',
        'valid': RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password),
      },
    ];
  }

  // ════════════════════════════════════════════════════
  // SECTION 3: Building Specs Validation
  //
  // Aturan logika bangunan:
  //   • Maks 4 kamar tidur per lantai
  //   • Maks kamar mandi = kamar tidur + 1 (WC tamu)
  //   • Maks lantai bergantung luas tanah (m²)
  //   • Luas bangunan ≤ luas tanah × jumlah lantai
  //   • Minimal 1 kamar tidur
  // ════════════════════════════════════════════════════

  /// Batas maksimal lantai berdasarkan luas tanah (m²).
  /// Referensi tipe rumah Indonesia:
  ///   ≤ 60 m²  → maks 2 lantai  (Tipe 36, lahan terbatas)
  ///   ≤ 96 m²  → maks 3 lantai  (Tipe 45)
  ///   ≤ 150 m² → maks 4 lantai  (Tipe 60)
  ///   > 150 m² → maks 5 lantai  (Custom Mansion & lainnya)
  static int maxFloors(double landSizeM2) {
    if (landSizeM2 <= 60) return 2;
    if (landSizeM2 <= 96) return 3;
    if (landSizeM2 <= 150) return 4;
    return 5;
  }

  /// Batas maksimal kamar tidur untuk sejumlah lantai.
  /// Asumsi: 4 kamar tidur per lantai (standar rumah keluarga Indonesia).
  static int maxBedroomsForFloors(int floors) => floors * 4;

  /// Batas maksimal kamar mandi untuk sejumlah kamar tidur.
  /// +1 = WC tamu/bersama di lantai bawah.
  static int maxBathroomsForBedrooms(int bedrooms) {
    // Minimal 1 kamar mandi meski belum ada kamar tidur yang dipilih
    return (bedrooms + 1).clamp(1, 999);
  }

  /// Validasi luas bangunan terhadap luas tanah dan jumlah lantai.
  /// Mengembalikan pesan error, atau null jika valid.
  static String? validateBuildingSize({
    required double buildingSize,
    required double landSizeM2,
    required int floors,
  }) {
    if (buildingSize <= 0) return 'Luas bangunan wajib diisi';
    final double maxBuildable = landSizeM2 * floors;
    if (buildingSize > maxBuildable) {
      return 'Luas bangunan maks ${maxBuildable.toStringAsFixed(0)} m² '
          '(${landSizeM2.toStringAsFixed(0)} m² tanah × $floors lantai)';
    }
    return null;
  }

  /// Validasi semua spesifikasi bangunan sekaligus.
  /// Mengembalikan daftar pesan error (kosong = semua valid).
  static List<String> validateBuildingSpecs({
    required int floors,
    required int bedrooms,
    required int bathrooms,
    required double buildingSize,
    double? landSizeM2, // Nullable: bisa belum dipilih di step 3
  }) {
    final List<String> errors = [];

    // — Minimal 1 kamar tidur —
    if (bedrooms < 1) {
      errors.add('Minimal 1 kamar tidur diperlukan');
    }

    // — Kamar tidur vs lantai —
    final int maxBR = maxBedroomsForFloors(floors);
    if (bedrooms > maxBR) {
      errors.add(
        'Terlalu banyak kamar tidur untuk $floors lantai '
        '(maks $maxBR kamar tidur)',
      );
    }

    // — Kamar mandi vs kamar tidur —
    final int maxBath = maxBathroomsForBedrooms(bedrooms);
    if (bathrooms > maxBath) {
      errors.add(
        'Kamar mandi terlalu banyak '
        '(maks $maxBath untuk $bedrooms kamar tidur)',
      );
    }

    // — Lantai vs luas tanah (hanya jika tanah sudah dipilih) —
    if (landSizeM2 != null) {
      final int maxF = maxFloors(landSizeM2);
      if (floors > maxF) {
        errors.add(
          'Terlalu banyak lantai untuk luas tanah '
          '${landSizeM2.toStringAsFixed(0)} m² (maks $maxF lantai)',
        );
      }

      // — Luas bangunan vs luas tanah × lantai —
      if (buildingSize > 0) {
        final String? sizeError = validateBuildingSize(
          buildingSize: buildingSize,
          landSizeM2: landSizeM2,
          floors: floors,
        );
        if (sizeError != null) errors.add(sizeError);
      }
    }

    return errors;
  }

  // ════════════════════════════════════════════════════
  // SECTION 4: General Form Validators (FormField use)
  // ════════════════════════════════════════════════════

  /// Validator untuk field wajib isi (dipakai di TextFormField).
  static String? requiredField(String? value, {String label = 'Field ini'}) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  /// Validator untuk angka positif (dipakai di TextFormField).
  static String? positiveNumber(String? value, {String label = 'Nilai'}) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    final num? parsed = num.tryParse(value);
    if (parsed == null || parsed <= 0) return '$label harus berupa angka positif';
    return null;
  }
}