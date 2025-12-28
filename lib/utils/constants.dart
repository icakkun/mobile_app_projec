class AppConstants {
  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Accommodation',
    'Entertainment',
    'Others',
  ];

  static const List<String> currencies = [
    'MYR',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'SGD',
    'THB',
    'IDR',
    'AUD',
    'CNY',
  ];

  static const Map<String, String> currencySymbols = {
    'MYR': 'RM',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'SGD': 'S\$',
    'THB': '฿',
    'IDR': 'Rp',
    'AUD': 'A\$',
    'CNY': '¥',
  };

  static String getCurrencySymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }
}
