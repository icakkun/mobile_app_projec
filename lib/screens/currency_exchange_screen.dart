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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentMint.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
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
                            Text(
                              'Quick Currency Converter',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Convert between currencies with ease',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // From Currency Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.south,
                          color: AppTheme.accentMint, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'From',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _fromCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            prefixIcon: Icon(Icons.account_balance,
                                color: AppTheme.accentMint),
                          ),
                          dropdownColor: AppTheme.cardBackground,
                          items: AppConstants.currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(
                                '$currency (${AppConstants.getCurrencySymbol(currency)})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            hintText: '0.00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
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
          ),
          const SizedBox(height: 12),

          // Swap Button
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentMint, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.swap_vert, color: AppTheme.accentMint),
                onPressed: _swapCurrencies,
                tooltip: 'Swap currencies',
                iconSize: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // To Currency Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.north,
                          color: AppTheme.accentMint, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'To',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _toCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.account_balance,
                          color: AppTheme.accentMint),
                    ),
                    dropdownColor: AppTheme.cardBackground,
                    items: AppConstants.currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(
                          '$currency (${AppConstants.getCurrencySymbol(currency)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accentMint.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Converted Amount',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        Text(
                          '${AppConstants.getCurrencySymbol(_toCurrency)} ${_convertedAmount.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.accentMint,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Exchange Rate Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.percent,
                          color: AppTheme.accentMint, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Exchange Rate',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rateController,
                    decoration: InputDecoration(
                      labelText: 'Rate (1 $_fromCurrency = ? $_toCurrency)',
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.calculate,
                          color: AppTheme.accentMint),
                      helperText: 'Adjust the exchange rate manually if needed',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,4}')),
                    ],
                    onChanged: (_) => _calculate(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '1 ${AppConstants.getCurrencySymbol(_fromCurrency)} = ${_rateController.text} ${AppConstants.getCurrencySymbol(_toCurrency)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.blue,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Conversions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on,
                          color: AppTheme.warningColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Conversions',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuickConversion(10),
                  const Divider(height: 24),
                  _buildQuickConversion(50),
                  const Divider(height: 24),
                  _buildQuickConversion(100),
                  const Divider(height: 24),
                  _buildQuickConversion(500),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentMint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Calculate',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.background,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickConversion(double amount) {
    final rate = double.tryParse(_rateController.text) ?? 1;
    final converted = amount * rate;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${AppConstants.getCurrencySymbol(_fromCurrency)} ${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Icon(Icons.arrow_forward,
            color: AppTheme.textSecondary, size: 16),
        Text(
          '${AppConstants.getCurrencySymbol(_toCurrency)} ${converted.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.accentMint,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
