class AppFormatters {
  static String bdt(num value) {
    final isWhole = value % 1 == 0;
    return isWhole ? 'BDT ${value.toInt()}' : 'BDT ${value.toStringAsFixed(2)}';
  }
}

