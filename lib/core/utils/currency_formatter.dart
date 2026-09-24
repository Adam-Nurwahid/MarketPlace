class CurrencyFormatter {
  const CurrencyFormatter._();

  static String rupiah(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    final rounded = amount.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(rounded[i]);
    }

    return 'Rp ${buffer.toString()}';
  }
}