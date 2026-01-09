import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class BudgetAlerts {
  // Store shown alerts per session to prevent duplicates
  static final Set<String> _shownAlerts = {};

  /// Main function to check all budget thresholds after adding/updating expense
  static Future<void> checkBudgetStatus(
      BuildContext context, String tripId) async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final trip = tripProvider.getTripById(tripId);

    if (trip == null) return;

    final percentage = tripProvider.getBudgetPercentage(tripId);

    // Check total budget alerts
    if (percentage >= 100) {
      await _show100PercentAlert(context, trip, tripProvider);
    } else if (percentage >= 80) {
      await _show80PercentAlert(context, trip, tripProvider);
    }

    // Check category budget alerts
    await _checkCategoryBudgets(context, trip, tripProvider);
  }

  /// Warning alert when 80% of budget is used
  static Future<void> _show80PercentAlert(
    BuildContext context,
    Trip trip,
    TripProvider tripProvider,
  ) async {
    final alertKey = 'trip_${trip.id}_80';
    if (_shownAlerts.contains(alertKey)) return;

    _shownAlerts.add(alertKey);

    final totalSpent = tripProvider.getTotalSpent(trip.id);
    final remaining = tripProvider.getRemainingBudget(trip.id);
    final percentage = tripProvider.getBudgetPercentage(trip.id);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppTheme.warningColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Budget Warning!',
                style: TextStyle(color: AppTheme.warningColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve used ${percentage.toStringAsFixed(1)}% of your ${trip.destination} trip budget!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Spent',
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${totalSpent.toStringAsFixed(2)}',
                    AppTheme.warningColor,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Budget',
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${trip.totalBudget.toStringAsFixed(2)}',
                    AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Remaining',
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${remaining.toStringAsFixed(2)}',
                    remaining > 0 ? AppTheme.accentMint : AppTheme.errorColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Consider reviewing your expenses to stay within budget.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.accentMint),
            ),
          ),
        ],
      ),
    );
  }

  /// Danger alert when 100% of budget is exceeded
  static Future<void> _show100PercentAlert(
    BuildContext context,
    Trip trip,
    TripProvider tripProvider,
  ) async {
    final alertKey = 'trip_${trip.id}_100';
    if (_shownAlerts.contains(alertKey)) return;

    _shownAlerts.add(alertKey);

    final totalSpent = tripProvider.getTotalSpent(trip.id);
    final overBudget = totalSpent - trip.totalBudget;
    final percentage = tripProvider.getBudgetPercentage(trip.id);

    // Stronger haptic feedback
    HapticFeedback.heavyImpact();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error,
                color: AppTheme.errorColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Budget Exceeded!',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve exceeded your ${trip.destination} trip budget by ${AppConstants.getCurrencySymbol(trip.homeCurrency)}${overBudget.toStringAsFixed(2)}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Spent',
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${totalSpent.toStringAsFixed(2)}',
                    AppTheme.errorColor,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Budget',
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${trip.totalBudget.toStringAsFixed(2)}',
                    AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Over Budget',
                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${overBudget.toStringAsFixed(2)}',
                    AppTheme.errorColor,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Usage',
                    '${percentage.toStringAsFixed(1)}%',
                    AppTheme.errorColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Consider adjusting your budget or reducing expenses.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppTheme.accentMint),
            ),
          ),
        ],
      ),
    );
  }

  /// Check all category budgets and show alerts if exceeded
  static Future<void> _checkCategoryBudgets(
    BuildContext context,
    Trip trip,
    TripProvider tripProvider,
  ) async {
    for (var categoryBudget in trip.categoryBudgets) {
      final percentage =
          tripProvider.getCategoryPercentage(trip.id, categoryBudget);

      if (percentage > 100) {
        await _showCategoryExceededAlert(
          context,
          trip,
          categoryBudget,
          tripProvider,
        );
      }
    }
  }

  /// Alert when a category budget is exceeded
  static Future<void> _showCategoryExceededAlert(
    BuildContext context,
    Trip trip,
    CategoryBudget categoryBudget,
    TripProvider tripProvider,
  ) async {
    final alertKey = 'category_${trip.id}_${categoryBudget.categoryName}';
    if (_shownAlerts.contains(alertKey)) return;

    _shownAlerts.add(alertKey);

    final spent =
        tripProvider.getSpentByCategory(trip.id)[categoryBudget.categoryName] ??
            0;
    final overBudget = spent - categoryBudget.limitAmount;
    final percentage =
        tripProvider.getCategoryPercentage(trip.id, categoryBudget);

    // Light haptic feedback
    HapticFeedback.lightImpact();

    // Show as SnackBar (less intrusive for category alerts)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(categoryBudget.categoryName),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${categoryBudget.categoryName} Budget Exceeded!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Over by ${AppConstants.getCurrencySymbol(trip.homeCurrency)}${overBudget.toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // User can see the details in trip details screen
            },
          ),
        ),
      );
    }
  }

  /// Helper to build info rows in dialogs
  static Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Get icon for category
  static IconData _getCategoryIcon(String category) {
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
        return Icons.category;
    }
  }

  /// Clear all shown alerts (useful when starting new session)
  static void clearAlerts() {
    _shownAlerts.clear();
  }

  /// Clear alerts for specific trip (useful after editing trip budget)
  static void clearTripAlerts(String tripId) {
    _shownAlerts.removeWhere((alert) => alert.contains(tripId));
  }
}
