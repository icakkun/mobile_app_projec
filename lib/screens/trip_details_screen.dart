import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/trip_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
import 'analytics_screen.dart';
import 'edit_trip_screen.dart';
import '../services/pdf_service.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  // ✅ Matching Dashboard theme colors
  static const Color kBgTop = Color(0xFF0A1220);
  static const Color kBgBottom = Color(0xFF070D18);
  static const Color kCard = Color(0xFF0E1B2E);
  static const Color kCard2 = Color(0xFF101F36);
  static const Color kBorder = Color(0xFF1E2C44);
  static const Color kText = Color(0xFFEAF0F7);
  static const Color kMuted = Color(0xFF9AA7B4);

  void _showDeleteConfirmation(
      BuildContext context, TripProvider tripProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kBorder, width: 1),
        ),
        title: const Text(
          'Delete Trip?',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This will permanently delete this trip and all its expenses. This action cannot be undone.',
          style: TextStyle(color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: kMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await tripProvider.deleteTrip(tripId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Trip deleted'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                context,
                icon: Icons.edit,
                title: 'Edit Trip',
                color: AppTheme.accentMint,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTripScreen(trip: trip),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.bar_chart,
                title: 'View Analytics',
                color: const Color(0xFF4DA3FF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalyticsScreen(tripId: tripId),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Export PDF Report',
                color: AppTheme.warningColor,
                onTap: () {
                  Navigator.pop(context);
                  _exportTripReport(context, tripId);
                },
              ),
              const Divider(height: 1, color: kBorder),
              _buildMenuItem(
                context,
                icon: Icons.delete,
                title: 'Delete Trip',
                color: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  final tripProvider =
                      Provider.of<TripProvider>(context, listen: false);
                  _showDeleteConfirmation(context, tripProvider);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: title.contains('Delete') ? AppTheme.errorColor : kText,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }

  void _exportTripReport(BuildContext context, String tripId) async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final trip = tripProvider.getTripById(tripId);

    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trip not found'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentMint),
      ),
    );

    try {
      final expenses = tripProvider.getExpenses(tripId);
      final totalSpent = tripProvider.getTotalSpent(tripId);
      final remaining = tripProvider.getRemainingBudget(tripId);
      final percentage = tripProvider.getBudgetPercentage(tripId);
      final categorySpent = tripProvider.getSpentByCategory(tripId);

      if (context.mounted) Navigator.pop(context);

      await PdfService.generateTripReport(
        trip: trip,
        expenses: expenses,
        totalSpent: totalSpent,
        remaining: remaining,
        percentage: percentage,
        categorySpent: categorySpent,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: kBgBottom),
                SizedBox(width: 12),
                Text('PDF generated successfully!'),
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
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final trip = tripProvider.getTripById(tripId);
        if (trip == null) {
          return Scaffold(
            backgroundColor: kBgBottom,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Trip Not Found'),
            ),
            body: const Center(child: Text('Trip not found')),
          );
        }

        final expenses = tripProvider.getExpenses(tripId);
        final totalSpent = tripProvider.getTotalSpent(tripId);
        final remaining = tripProvider.getRemainingBudget(tripId);
        final percentage = tripProvider.getBudgetPercentage(tripId);
        final categorySpent = tripProvider.getSpentByCategory(tripId);

        return Scaffold(
          backgroundColor: kBgBottom,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destination,
                  style: const TextStyle(
                    color: kText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            toolbarHeight: 80,
            actions: [
              if (percentage >= 80)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    percentage >= 100 ? Icons.error : Icons.warning_amber,
                    color: percentage >= 100
                        ? AppTheme.errorColor
                        : AppTheme.warningColor,
                  ),
                ).animate().scale().shake(),
              IconButton(
                icon: const Icon(Icons.more_vert, color: kText),
                onPressed: () => _showOptionsMenu(context, trip),
                tooltip: 'More options',
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
                  // Budget Summary Card
                  _buildBudgetCard(
                    context,
                    trip,
                    totalSpent,
                    remaining,
                    percentage,
                  )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 20),

                  // Category Budgets
                  if (trip.categoryBudgets.isNotEmpty) ...[
                    Text(
                      'Category Budgets',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: kText,
                                fontWeight: FontWeight.w900,
                              ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    ...trip.categoryBudgets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final categoryBudget = entry.value;
                      final spent =
                          categorySpent[categoryBudget.categoryName] ?? 0;
                      final catPercentage = tripProvider.getCategoryPercentage(
                          tripId, categoryBudget);

                      return _buildCategoryCard(
                        context,
                        trip,
                        categoryBudget,
                        spent,
                        catPercentage,
                      )
                          .animate()
                          .fadeIn(delay: (250 + index * 50).ms)
                          .slideX(begin: -0.1);
                    }).toList(),
                    const SizedBox(height: 20),
                  ],

                  // Recent Expenses
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Expenses',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: kText,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentMint.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentMint.withOpacity(0.22),
                          ),
                        ),
                        child: Text(
                          '${expenses.length} total',
                          style: TextStyle(
                            color: AppTheme.accentMint,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                  const SizedBox(height: 12),

                  if (expenses.isEmpty)
                    _buildEmptyState(context)
                        .animate()
                        .fadeIn(delay: 350.ms)
                        .scale(begin: const Offset(0.9, 0.9))
                  else
                    ...expenses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final expense = entry.value;
                      return _buildExpenseCard(context, expense)
                          .animate()
                          .fadeIn(delay: (350 + index * 50).ms)
                          .slideX(begin: 0.1);
                    }).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddExpenseScreen(tripId: tripId),
              );
            },
            backgroundColor: AppTheme.accentMint,
            icon: const Icon(Icons.add, color: kBgBottom),
            label: const Text(
              'Add Expense',
              style: TextStyle(
                color: kBgBottom,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        );
      },
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    trip,
    double totalSpent,
    double remaining,
    double percentage,
  ) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Warning Banner
            if (percentage >= 100) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error,
                      color: AppTheme.errorColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Budget exceeded by ${AppConstants.getCurrencySymbol(trip.homeCurrency)}${(totalSpent - trip.totalBudget).toStringAsFixed(2)}!',
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ] else if (percentage >= 80) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppTheme.warningColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'ve used ${percentage.toStringAsFixed(1)}% of your budget. ${AppConstants.getCurrencySymbol(trip.homeCurrency)}${remaining.toStringAsFixed(2)} remaining.',
                        style: const TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Spent vs Remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: percentage > 80
                                ? AppTheme.errorColor
                                : AppTheme.accentMint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: kBorder,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${remaining.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 100
                      ? AppTheme.errorColor
                      : percentage > 80
                          ? AppTheme.warningColor
                          : AppTheme.accentMint,
                ),
                minHeight: 12,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '${percentage.toStringAsFixed(1)}% of budget used',
              style: TextStyle(
                color: kMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Total Budget
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBgBottom.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Budget:',
                    style: TextStyle(
                      color: kMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${trip.totalBudget.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    trip,
    categoryBudget,
    double spent,
    double catPercentage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(categoryBudget.categoryName)
                            .withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getCategoryColor(categoryBudget.categoryName)
                              .withOpacity(0.22),
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(categoryBudget.categoryName),
                        color: _getCategoryColor(categoryBudget.categoryName),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      categoryBudget.categoryName,
                      style: const TextStyle(
                        color: kText,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (catPercentage > 100) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.error,
                        color: AppTheme.errorColor,
                        size: 16,
                      ),
                    ] else if (catPercentage > 80) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.warning_amber,
                        color: AppTheme.warningColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${spent.toStringAsFixed(0)} / ${categoryBudget.limitAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: kMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (catPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  catPercentage > 100
                      ? AppTheme.errorColor
                      : catPercentage > 80
                          ? AppTheme.warningColor
                          : AppTheme.accentMint,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EditExpenseScreen(
              tripId: tripId,
              expense: expense,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon or Receipt
              if (expense.receiptImageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    expense.receiptImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 56,
                        height: 56,
                        color: kBgBottom,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kBgBottom,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.broken_image,
                          size: 24,
                          color: kMuted,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.categoryName)
                        .withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(expense.categoryName)
                          .withOpacity(0.22),
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.categoryName),
                    color: _getCategoryColor(expense.categoryName),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          expense.categoryName,
                          style: const TextStyle(
                            color: kText,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kBorder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.paidBy,
                            style: TextStyle(
                              fontSize: 11,
                              color: kMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (expense.receiptImageUrl != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.receipt,
                            size: 14,
                            color: AppTheme.accentMint,
                          ),
                        ],
                      ],
                    ),
                    if (expense.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.note,
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(expense.expenseDate),
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppConstants.getCurrencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: _getCategoryColor(expense.categoryName),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: kMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentMint.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentMint.withOpacity(0.22),
                ),
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 40,
                color: AppTheme.accentMint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No expenses yet',
              style: TextStyle(
                color: kText,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first expense',
              style: TextStyle(
                color: kMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
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
