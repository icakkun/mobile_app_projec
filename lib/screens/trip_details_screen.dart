import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final trip = tripProvider.getTripById(tripId);
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Not Found')),
            body: const Center(child: Text('Trip not found')),
          );
        }

        final expenses = tripProvider.getExpenses(tripId);
        final totalSpent = tripProvider.getTotalSpent(tripId);
        final remaining = tripProvider.getRemainingBudget(tripId);
        final percentage = tripProvider.getBudgetPercentage(tripId);
        final categorySpent = tripProvider.getSpentByCategory(tripId);

        return Scaffold(
          appBar: AppBar(
            title: Text(trip.destination),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalyticsScreen(tripId: tripId),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Budget Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spent',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${totalSpent.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: percentage > 80
                                          ? AppTheme.errorColor
                                          : AppTheme.accentMint,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Remaining',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${remaining.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor:
                              AppTheme.textSecondary.withOpacity(0.2),
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
                      const SizedBox(height: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of budget used',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Budget:',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${trip.totalBudget.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Budgets
              if (trip.categoryBudgets.isNotEmpty) ...[
                Text(
                  'Category Budgets',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ...trip.categoryBudgets.map((categoryBudget) {
                  final spent = categorySpent[categoryBudget.categoryName] ?? 0;
                  final catRemaining = tripProvider.getCategoryRemaining(tripId, categoryBudget);
                  final catPercentage = tripProvider.getCategoryPercentage(tripId, categoryBudget);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                categoryBudget.categoryName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${spent.toStringAsFixed(0)} / ${categoryBudget.limitAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: catPercentage / 100,
                              backgroundColor:
                                  AppTheme.textSecondary.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                catPercentage > 100
                                    ? AppTheme.errorColor
                                    : catPercentage > 80
                                        ? AppTheme.warningColor
                                        : AppTheme.accentMint,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],

              // Recent Expenses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${expenses.length} total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No expenses yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...expenses.map((expense) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentMint.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(expense.categoryName),
                          color: AppTheme.accentMint,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        expense.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (expense.note.isNotEmpty)
                            Text(expense.note),
                          Text(
                            DateFormat('MMM dd, yyyy').format(expense.expenseDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${AppConstants.getCurrencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentMint,
                                ),
                          ),
                          Text(
                            expense.paidBy,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddExpenseScreen(tripId: tripId),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
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
}
