/// Currency utility for CLIMATWIN.
/// Standardizes all monetary displays to Indian Rupee (₹) using a valid benchmark exchange rate.
/// Exchange rate: 1 USD = ₹83.50 (Standard Financial Benchmark).
class CurrencyFormatter {
  static const double usdToInrRate = 83.50;
  static const String exchangeRateNote = '1 USD = ₹83.50 (Benchmark FX)';

  /// Converts USD to INR and formats as human-readable string.
  static String formatUsdToInr(double usdAmount, {bool compact = true}) {
    final double inrAmount = usdAmount * usdToInrRate;
    return formatInr(inrAmount, compact: compact);
  }

  /// Formats an INR amount with Crores (Cr) or Lakhs (L) notation.
  static String formatInr(double inrAmount, {bool compact = true}) {
    final isNegative = inrAmount < 0;
    final absAmount = inrAmount.abs();

    if (!compact) {
      final formatted = absAmount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
      return '${isNegative ? "-₹" : "₹"}$formatted';
    }

    if (absAmount >= 10000000) {
      // 1 Crore = 10,000,000
      final double crores = absAmount / 10000000.0;
      return '${isNegative ? "-₹" : "₹"}${crores.toStringAsFixed(crores >= 100 ? 1 : 2)} Cr';
    } else if (absAmount >= 100000) {
      // 1 Lakh = 100,000
      final double lakhs = absAmount / 100000.0;
      return '${isNegative ? "-₹" : "₹"}${lakhs.toStringAsFixed(1)} L';
    } else if (absAmount >= 1000) {
      final double thousands = absAmount / 1000.0;
      return '${isNegative ? "-₹" : "₹"}${thousands.toStringAsFixed(1)}k';
    } else {
      return '${isNegative ? "-₹" : "₹"}${absAmount.toStringAsFixed(2)}';
    }
  }

  /// Formats raw stock price already in INR.
  static String formatPrice(double priceInr) {
    return '₹${priceInr.toStringAsFixed(2)}';
  }
}
