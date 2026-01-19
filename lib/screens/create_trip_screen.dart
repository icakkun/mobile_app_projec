import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedCurrency = 'MYR';
  bool _addCategoryBudgets = false;

  final Map<String, TextEditingController> _categoryControllers = {};

  // ✅ Matching Dashboard theme colors
  static const Color kBgTop = Color(0xFF0A1220);
  static const Color kBgBottom = Color(0xFF070D18);
  static const Color kCard = Color(0xFF0E1B2E);
  static const Color kCard2 = Color(0xFF101F36);
  static const Color kBorder = Color(0xFF1E2C44);
  static const Color kText = Color(0xFFEAF0F7);
  static const Color kMuted = Color(0xFF9AA7B4);

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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentMint,
              onPrimary: kBgBottom,
              surface: kCard,
              onSurface: kText,
            ),
            dialogBackgroundColor: kCard,
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

  void _createTrip() async {
    if (_formKey.currentState!.validate()) {
      List<CategoryBudget>? categoryBudgets;

      if (_addCategoryBudgets) {
        categoryBudgets = [];
        final uuid = const Uuid();
        for (var entry in _categoryControllers.entries) {
          final amount = double.tryParse(entry.value.text);
          if (amount != null && amount > 0) {
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
          child: CircularProgressIndicator(color: AppTheme.accentMint),
        ),
      );

      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);

        await tripProvider.addTrip(
          title: _titleController.text,
          destination: _destinationController.text,
          startDate: _startDate,
          endDate: _endDate,
          homeCurrency: _selectedCurrency,
          totalBudget: double.parse(_budgetController.text),
          categoryBudgets: categoryBudgets,
        );

        if (mounted) {
          Navigator.pop(context); // Close loading
          Navigator.pop(context); // Go back

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: kBgBottom),
                  SizedBox(width: 12),
                  Text('Trip created successfully!'),
                ],
              ),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating trip: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
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
          'Create Trip',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _createTrip,
              icon:
                  const Icon(Icons.check, color: AppTheme.accentMint, size: 20),
              label: const Text(
                'Create',
                style: TextStyle(
                  color: AppTheme.accentMint,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header
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
                          Icons.flight_takeoff,
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
                              'Plan Your Adventure',
                              style: TextStyle(
                                color: kText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set your budget and track expenses',
                              style: TextStyle(
                                color: kMuted,
                                fontSize: 13,
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

                const SizedBox(height: 24),

                // Trip Details Section
                _buildSectionHeader('TRIP DETAILS')
                    .animate()
                    .fadeIn(delay: 150.ms)
                    .slideX(begin: -0.1),

                const SizedBox(height: 12),

                _buildInputCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'Trip Title',
                        hint: 'e.g., Summer Vacation',
                        icon: Icons.title,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _destinationController,
                        label: 'Destination',
                        hint: 'e.g., Tokyo, Japan',
                        icon: Icons.location_on,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a destination';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: 24),

                // Dates Section
                _buildSectionHeader('DATES')
                    .animate()
                    .fadeIn(delay: 250.ms)
                    .slideX(begin: -0.1),

                const SizedBox(height: 12),

                _buildInputCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Start Date',
                          date: _startDate,
                          icon: Icons.calendar_today,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: kBorder,
                      ),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'End Date',
                          date: _endDate,
                          icon: Icons.event,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: 24),

                // Budget Section
                _buildSectionHeader('BUDGET')
                    .animate()
                    .fadeIn(delay: 350.ms)
                    .slideX(begin: -0.1),

                const SizedBox(height: 12),

                _buildInputCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          labelText: 'Currency',
                          labelStyle: TextStyle(color: kMuted),
                          prefixIcon: const Icon(
                            Icons.attach_money,
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
                        style: const TextStyle(color: kText),
                        items: AppConstants.currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(
                              '$currency (${AppConstants.getCurrencySymbol(currency)})',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _budgetController,
                        label: 'Total Budget',
                        hint: '0.00',
                        icon: Icons.account_balance_wallet,
                        prefixText:
                            '${AppConstants.getCurrencySymbol(_selectedCurrency)} ',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
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
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                const SizedBox(height: 24),

                // Category Budgets Toggle
                Container(
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder, width: 1),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: const Text(
                      'Add Category Budgets',
                      style: TextStyle(
                        color: kText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Optional: Set budgets for specific categories',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 12,
                      ),
                    ),
                    value: _addCategoryBudgets,
                    activeColor: AppTheme.accentMint,
                    onChanged: (value) {
                      setState(() {
                        _addCategoryBudgets = value;
                        if (value) {
                          for (var category in AppConstants.categories) {
                            _categoryControllers[category] =
                                TextEditingController();
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
                ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1),

                if (_addCategoryBudgets) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('CATEGORY BUDGETS')
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  ...AppConstants.categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInputCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category)
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getCategoryColor(category)
                                      .withOpacity(0.22),
                                ),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _categoryControllers[category],
                                style: const TextStyle(color: kText),
                                decoration: InputDecoration(
                                  labelText: category,
                                  labelStyle: TextStyle(color: kMuted),
                                  hintText: 'Optional',
                                  hintStyle:
                                      TextStyle(color: kMuted.withOpacity(0.6)),
                                  prefixText:
                                      '${AppConstants.getCurrencySymbol(_selectedCurrency)} ',
                                  prefixStyle: const TextStyle(color: kText),
                                  filled: true,
                                  fillColor: kBgBottom.withOpacity(0.6),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: kBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _getCategoryColor(category),
                                    ),
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (500 + index * 50).ms)
                          .slideX(begin: -0.1),
                    );
                  }).toList(),
                ],

                const SizedBox(height: 32),

                // Create Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.accentMint,
                        Color(0xFF2EE59D),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentMint.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _createTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: kBgBottom),
                        SizedBox(width: 12),
                        Text(
                          'Create Trip',
                          style: TextStyle(
                            color: kBgBottom,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: kMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
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
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: kText),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgBottom.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.accentMint, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(
                color: kText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Accommodation':
        return Icons.hotel;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFEF4444);
      case 'Transport':
        return const Color(0xFF3B82F6);
      case 'Shopping':
        return const Color(0xFFF59E0B);
      case 'Accommodation':
        return const Color(0xFF8B5CF6);
      case 'Entertainment':
        return const Color(0xFFEC4899);
      default:
        return AppTheme.accentMint;
    }
  }
}
