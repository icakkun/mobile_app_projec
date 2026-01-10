import 'dart:ui';

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

  // Common exchange rates (can be updated manually)
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

  // Local-only UI palette (blue-ish dashboard vibe)
  static const Color _kNavy1 = Color(0xFF0B1422);
  static const Color _kNavy2 = Color(0xFF0F1B2E);
  static const Color _kCard = Color(0xFF111F33);
  static const Color _kBorder = Color(0xFF233A57);
  static const Color _kInfoBlue = Color(0xFF4DA3FF);

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
    // Auto-fill exchange rate if available
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
    final theme = Theme.of(context);

    OutlineInputBorder outline(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 1.1),
        );

    InputDecoration fieldDeco({
      required String label,
      String? hint,
      IconData? icon,
      String? helper,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                color: AppTheme.accentMint,
              ),
        floatingLabelStyle: TextStyle(
          color: AppTheme.accentMint.withOpacity(0.95),
          fontWeight: FontWeight.w700,
        ),
        labelStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.9)),
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.55)),
        helperStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.75)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: outline(Colors.white.withOpacity(0.12)),
        focusedBorder: outline(AppTheme.accentMint.withOpacity(0.65)),
        errorBorder: outline(AppTheme.errorColor.withOpacity(0.70)),
        focusedErrorBorder: outline(AppTheme.errorColor.withOpacity(0.85)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Currency Exchange',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _IconChipButton(
              tooltip: 'Clear',
              icon: Icons.clear_all,
              onPressed: _clearAll,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kNavy2, _kNavy1],
          ),
        ),
        child: Stack(
          children: [
            // subtle glows
            Positioned(
              top: -120,
              left: -120,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentMint.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -160,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kInfoBlue.withOpacity(0.10),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(color: Colors.transparent),
              ),
            ),

            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Header Card
                  _GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.accentMint.withOpacity(0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.currency_exchange,
                            color: AppTheme.accentMint,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Currency Converter',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Convert between currencies with ease',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // From Section
                  _GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.south,
                                color: AppTheme.accentMint,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'From',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _fromCurrency,
                                decoration: fieldDeco(
                                  label: 'Currency',
                                  icon: Icons.account_balance,
                                ),
                                dropdownColor: _kCard,
                                iconEnabledColor: AppTheme.textSecondary,
                                items: AppConstants.currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency,
                                    child: Text(
                                      '$currency (${AppConstants.getCurrencySymbol(currency)})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _fromCurrency = value!;
                                    _updateRate();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                decoration: fieldDeco(
                                  label: 'Amount',
                                  hint: '0.00',
                                  icon: Icons.payments_outlined,
                                ),
                                style: TextStyle(color: AppTheme.textPrimary),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                onChanged: (_) => _calculate(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Swap
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _swapCurrencies,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentMint.withOpacity(0.45),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentMint.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          color: AppTheme.accentMint,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // To Section
                  _GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.north,
                                color: AppTheme.accentMint,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'To',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _toCurrency,
                          decoration: fieldDeco(
                            label: 'Currency',
                            icon: Icons.account_balance,
                          ),
                          dropdownColor: _kCard,
                          iconEnabledColor: AppTheme.textSecondary,
                          items: AppConstants.currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(
                                '$currency (${AppConstants.getCurrencySymbol(currency)})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _toCurrency = value!;
                              _updateRate();
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Result pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.accentMint.withOpacity(0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Converted Amount',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${AppConstants.getCurrencySymbol(_toCurrency)} ${_convertedAmount.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
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

                  const SizedBox(height: 14),

                  // Exchange Rate
                  _GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.percent,
                                color: AppTheme.accentMint,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Exchange Rate',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _rateController,
                          decoration: fieldDeco(
                            label: 'Rate (1 $_fromCurrency = ? $_toCurrency)',
                            hint: '0.00',
                            icon: Icons.calculate_outlined,
                            helper:
                                'Adjust the exchange rate manually if needed',
                          ),
                          style: TextStyle(color: AppTheme.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,4}')),
                          ],
                          onChanged: (_) => _calculate(),
                        ),
                        const SizedBox(height: 12),

                        // Info row (blue-ish)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kInfoBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: _kInfoBlue.withOpacity(0.22)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: _kInfoBlue, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '1 ${AppConstants.getCurrencySymbol(_fromCurrency)} = ${_rateController.text} ${AppConstants.getCurrencySymbol(_toCurrency)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _kInfoBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Conversions
                  _GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppTheme.warningColor.withOpacity(0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.flash_on,
                                color: AppTheme.warningColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Quick Conversions',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildQuickConversion(10),
                        const SizedBox(height: 12),
                        Divider(
                            height: 1, color: Colors.white.withOpacity(0.10)),
                        const SizedBox(height: 12),
                        _buildQuickConversion(50),
                        const SizedBox(height: 12),
                        Divider(
                            height: 1, color: Colors.white.withOpacity(0.10)),
                        const SizedBox(height: 12),
                        _buildQuickConversion(100),
                        const SizedBox(height: 12),
                        Divider(
                            height: 1, color: Colors.white.withOpacity(0.10)),
                        const SizedBox(height: 12),
                        _buildQuickConversion(500),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Calculate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentMint,
                        foregroundColor: AppTheme.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calculate, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Calculate',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.background,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickConversion(double amount) {
    final rate = double.tryParse(_rateController.text) ?? 1;
    final converted = amount * rate;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${AppConstants.getCurrencySymbol(_fromCurrency)} ${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
        Icon(Icons.arrow_forward, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${AppConstants.getCurrencySymbol(_toCurrency)} ${converted.toStringAsFixed(2)}',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentMint,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

/// --------------------------------------------
/// UI helpers (visual only — no function changes)
/// --------------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _CurrencyExchangeScreenState._kCard.withOpacity(0.70),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _CurrencyExchangeScreenState._kBorder.withOpacity(0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconChipButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _IconChipButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
