import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class CurrencyExchangeScreen extends StatefulWidget {
  const CurrencyExchangeScreen({super.key});

  @override
  State<CurrencyExchangeScreen> createState() => _CurrencyExchangeScreenState();
}

class _CurrencyExchangeScreenState extends State<CurrencyExchangeScreen> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController(text: '1.0');

  String _fromCurrency = 'MYR';
  String _toCurrency = 'USD';
  double _convertedAmount = 0.0;

  // Common exchange rates
  final Map<String, Map<String, double>> _commonRates = {
    'MYR': {
      'USD': 0.22,
      'EUR': 0.20,
      'GBP': 0.17,
      'SGD': 0.30,
      'JPY': 33.50,
      'THB': 7.80,
      'IDR': 3450.0,
      'AUD': 0.34,
      'CNY': 1.60,
    },
    'USD': {
      'MYR': 4.55,
      'EUR': 0.92,
      'GBP': 0.79,
      'SGD': 1.35,
      'JPY': 152.50,
      'THB': 35.50,
      'IDR': 15700.0,
      'AUD': 1.55,
      'CNY': 7.30,
    },
  };

  // ✅ Matching Dashboard theme colors
  static const Color kBgTop = Color(0xFF0A1220);
  static const Color kBgBottom = Color(0xFF070D18);
  static const Color kCard = Color(0xFF0E1B2E);
  static const Color kCard2 = Color(0xFF101F36);
  static const Color kBorder = Color(0xFF1E2C44);
  static const Color kText = Color(0xFFEAF0F7);
  static const Color kMuted = Color(0xFF9AA7B4);

  @override
  void initState() {
    super.initState();
    _updateRate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _updateRate() {
    if (_commonRates.containsKey(_fromCurrency) &&
        _commonRates[_fromCurrency]!.containsKey(_toCurrency)) {
      _rateController.text =
          _commonRates[_fromCurrency]![_toCurrency].toString();
    } else if (_fromCurrency == _toCurrency) {
      _rateController.text = '1.0';
    }
    _calculate();
  }

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 1;
    setState(() {
      _convertedAmount = amount * rate;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _updateRate();
    });
  }

  void _clearAll() {
    setState(() {
      _amountController.clear();
      _rateController.text = '1.0';
      _convertedAmount = 0.0;
      _updateRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBottom,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Currency Exchange',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: const Icon(
                  Icons.clear_all,
                  color: kText,
                  size: 20,
                ),
              ),
              onPressed: _clearAll,
              tooltip: 'Clear',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgTop, kBgBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.accentMint.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentMint.withOpacity(0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.currency_exchange,
                        color: AppTheme.accentMint,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Converter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Convert between currencies with ease',
                            style: TextStyle(
                              fontSize: 13,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 20),

              // From Section
              _buildSection(
                title: 'From',
                icon: Icons.south,
                child: Column(
                  children: [
                    _buildCurrencyDropdown(
                      value: _fromCurrency,
                      onChanged: (value) {
                        setState(() {
                          _fromCurrency = value!;
                          _updateRate();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _amountController,
                      label: 'Amount',
                      hint: '0.00',
                      icon: Icons.payments_outlined,
                      onChanged: (_) => _calculate(),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

              const SizedBox(height: 16),

              // Swap Button
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _swapCurrencies,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentMint.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentMint.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: AppTheme.accentMint,
                      size: 30,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: 16),

              // To Section
              _buildSection(
                title: 'To',
                icon: Icons.north,
                child: Column(
                  children: [
                    _buildCurrencyDropdown(
                      value: _toCurrency,
                      onChanged: (value) {
                        setState(() {
                          _toCurrency = value!;
                          _updateRate();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Result
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.accentMint.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentMint.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Converted Amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${AppConstants.getCurrencySymbol(_toCurrency)} ${_convertedAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: AppTheme.accentMint,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),

              const SizedBox(height: 20),

              // Exchange Rate Section
              _buildSection(
                title: 'Exchange Rate',
                icon: Icons.percent,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _rateController,
                      label: 'Rate (1 $_fromCurrency = ? $_toCurrency)',
                      hint: '0.00',
                      icon: Icons.calculate_outlined,
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DA3FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4DA3FF).withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF4DA3FF),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '1 ${AppConstants.getCurrencySymbol(_fromCurrency)} = ${_rateController.text} ${AppConstants.getCurrencySymbol(_toCurrency)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4DA3FF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

              const SizedBox(height: 20),

              // Quick Conversions
              _buildSection(
                title: 'Quick Conversions',
                icon: Icons.flash_on,
                iconColor: AppTheme.warningColor,
                child: Column(
                  children: [
                    _buildQuickConversion(10),
                    _buildDivider(),
                    _buildQuickConversion(50),
                    _buildDivider(),
                    _buildQuickConversion(100),
                    _buildDivider(),
                    _buildQuickConversion(500),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),

              const SizedBox(height: 24),

              // Calculate Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentMint,
                    foregroundColor: kBgBottom,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Calculate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.accentMint).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (iconColor ?? AppTheme.accentMint).withOpacity(0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.accentMint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: kText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Currency',
        labelStyle: TextStyle(color: kMuted),
        prefixIcon: const Icon(
          Icons.account_balance,
          color: AppTheme.accentMint,
        ),
        filled: true,
        fillColor: kBgBottom.withOpacity(0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentMint),
        ),
      ),
      dropdownColor: kCard2,
      style: const TextStyle(
        color: kText,
        fontWeight: FontWeight.w800,
      ),
      items: AppConstants.currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(
            '$currency (${AppConstants.getCurrencySymbol(currency)})',
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kMuted),
        hintText: hint,
        hintStyle: TextStyle(color: kMuted.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: AppTheme.accentMint),
        filled: true,
        fillColor: kBgBottom.withOpacity(0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentMint),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildQuickConversion(double amount) {
    final rate = double.tryParse(_rateController.text) ?? 1;
    final converted = amount * rate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppConstants.getCurrencySymbol(_fromCurrency)} ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),
          ),
          Icon(Icons.arrow_forward, color: kMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${AppConstants.getCurrencySymbol(_toCurrency)} ${converted.toStringAsFixed(2)}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.accentMint,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, color: kBorder),
    );
  }
}
