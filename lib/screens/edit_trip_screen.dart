// edit_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _destinationController;
  late TextEditingController _budgetController;

  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedCurrency;
  bool _addCategoryBudgets = false;

  final Map<String, TextEditingController> _categoryControllers = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing trip data
    _titleController = TextEditingController(text: widget.trip.title);
    _destinationController =
        TextEditingController(text: widget.trip.destination);
    _budgetController =
        TextEditingController(text: widget.trip.totalBudget.toString());
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
    _selectedCurrency = widget.trip.homeCurrency;

    // Pre-fill category budgets if they exist
    if (widget.trip.categoryBudgets.isNotEmpty) {
      _addCategoryBudgets = true;
      for (var categoryBudget in widget.trip.categoryBudgets) {
        _categoryControllers[categoryBudget.categoryName] =
            TextEditingController(text: categoryBudget.limitAmount.toString());
      }
      // Initialize remaining categories with empty controllers
      for (var category in AppConstants.categories) {
        if (!_categoryControllers.containsKey(category)) {
          _categoryControllers[category] = TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentMint,
              onPrimary: AppTheme.background,
              surface: AppTheme.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _updateTrip() async {
    if (_formKey.currentState!.validate()) {
      List<CategoryBudget>? categoryBudgets;

      if (_addCategoryBudgets) {
        categoryBudgets = [];
        final uuid = const Uuid();
        for (var entry in _categoryControllers.entries) {
          final amount = double.tryParse(entry.value.text);
          if (amount != null && amount > 0) {
            // Keep existing ID if it exists
            final existingBudget = widget.trip.categoryBudgets
                .where((b) => b.categoryName == entry.key)
                .firstOrNull;

            categoryBudgets.add(
              CategoryBudget(
                categoryName: entry.key,
                limitAmount: amount,
              ),
            );
          }
        }
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update trip
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      final updatedTrip = widget.trip.copyWith(
        title: _titleController.text,
        destination: _destinationController.text,
        startDate: _startDate,
        endDate: _endDate,
        homeCurrency: _selectedCurrency,
        totalBudget: double.parse(_budgetController.text),
        categoryBudgets: categoryBudgets,
      );

      await tripProvider.updateTrip(widget.trip.id, updatedTrip);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Go back to trip details
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip updated successfully!'),
            backgroundColor: AppTheme.accentMint,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trip'),
        actions: [
          TextButton(
            onPressed: _updateTrip,
            child: const Text(
              'Save',
              style: TextStyle(color: AppTheme.accentMint, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Trip Title',
                hintText: 'e.g., Summer Vacation',
                prefixIcon: Icon(Icons.title, color: AppTheme.accentMint),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'e.g., Tokyo, Japan',
                prefixIcon: Icon(Icons.location_on, color: AppTheme.accentMint),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a destination';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: Icon(Icons.calendar_today,
                            color: AppTheme.accentMint),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_startDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        prefixIcon:
                            Icon(Icons.event, color: AppTheme.accentMint),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_endDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                prefixIcon:
                    Icon(Icons.attach_money, color: AppTheme.accentMint),
              ),
              dropdownColor: AppTheme.cardBackground,
              items: AppConstants.currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(
                      '$currency (${AppConstants.getCurrencySymbol(currency)})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: 'Total Budget',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.account_balance_wallet,
                    color: AppTheme.accentMint),
                prefixText:
                    '${AppConstants.getCurrencySymbol(_selectedCurrency)} ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a budget';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Category Budgets'),
              subtitle: const Text('Set budgets for specific categories'),
              value: _addCategoryBudgets,
              activeColor: AppTheme.accentMint,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _addCategoryBudgets = value;
                  if (value) {
                    for (var category in AppConstants.categories) {
                      if (!_categoryControllers.containsKey(category)) {
                        _categoryControllers[category] =
                            TextEditingController();
                      }
                    }
                  } else {
                    for (var controller in _categoryControllers.values) {
                      controller.dispose();
                    }
                    _categoryControllers.clear();
                  }
                });
              },
            ),
            if (_addCategoryBudgets) ...[
              const SizedBox(height: 16),
              Text(
                'Category Budgets',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ...AppConstants.categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _categoryControllers[category],
                    decoration: InputDecoration(
                      labelText: category,
                      hintText: 'Optional',
                      prefixText:
                          '${AppConstants.getCurrencySymbol(_selectedCurrency)} ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
