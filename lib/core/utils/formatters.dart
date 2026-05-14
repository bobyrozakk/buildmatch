/// Utility class for formatting values across the app.
class AppFormatters {
  AppFormatters._();

  /// Formats a double amount into Indonesian Rupiah format.
  /// Example: 350000000 → "Rp 350.000.000"
  static String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}
