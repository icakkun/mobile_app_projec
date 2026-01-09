import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class EnhancedAnalyticsScreen extends StatefulWidget {
  const EnhancedAnalyticsScreen({super.key});

  @override
  State<EnhancedAnalyticsScreen> createState() =>
      _EnhancedAnalyticsScreenState();
}

class _EnhancedAnalyticsScreenState extends State<EnhancedAnalyticsScreen> {
  String _selectedView = 'overview'; // overview, daily, trips, categories

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, child) {
          final trips = tripProvider.trips;

          if (trips.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // View Selector
              _buildViewSelector(),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_selectedView == 'overview')
                      ..._buildOverviewView(tripProvider, trips),
                    if (_selectedView == 'daily')
                      ..._buildDailyView(tripProvider, trips),
                    if (_selectedView == 'trips')
                      ..._buildTripsComparisonView(tripProvider, trips),
                    if (_selectedView == 'categories')
                      ..._buildCategoriesView(tripProvider, trips),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildViewChip('overview', 'Overview', Icons.dashboard),
            const SizedBox(width: 8),
            _buildViewChip('daily', 'Daily Trends', Icons.show_chart),
            const SizedBox(width: 8),
            _buildViewChip('trips', 'Compare Trips', Icons.compare),
            const SizedBox(width: 8),
            _buildViewChip('categories', 'Categories', Icons.pie_chart),
          ],
        ),
      ),
    );
  }

  Widget _buildViewChip(String value, String label, IconData icon) {
    final isSelected = _selectedView == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? AppTheme.background : AppTheme.accentMint),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
      },
      backgroundColor: AppTheme.cardBackground,
      selectedColor: AppTheme.accentMint,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.background : AppTheme.textPrimary,
      ),
    );
  }

  List<Widget> _buildOverviewView(TripProvider tripProvider, List<Trip> trips) {
    double totalSpent = 0;
    double totalBudget = 0;
    int totalExpenses = 0;

    for (var trip in trips) {
      totalSpent += tripProvider.getTotalSpent(trip.id);
      totalBudget += trip.totalBudget;
      totalExpenses += tripProvider.getExpenses(trip.id).length;
    }

    final averagePerTrip = trips.isEmpty ? 0.0 : totalSpent / trips.length;
    final budgetUsagePercentage =
        totalBudget == 0 ? 0.0 : (totalSpent / totalBudget) * 100;

    return [
      Text(
        'Overall Summary',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),

      // Summary Cards
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total Spent',
              'RM ${totalSpent.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              AppTheme.accentMint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Total Budget',
              'RM ${totalBudget.toStringAsFixed(2)}',
              Icons.savings,
              Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total Expenses',
              totalExpenses.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Avg per Trip',
              'RM ${averagePerTrip.toStringAsFixed(2)}',
              Icons.trending_up,
              AppTheme.warningColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),

      // Budget Usage
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Budget Usage',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: budgetUsagePercentage / 100,
                  backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    budgetUsagePercentage > 100
                        ? AppTheme.errorColor
                        : budgetUsagePercentage > 80
                            ? AppTheme.warningColor
                            : AppTheme.accentMint,
                  ),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${budgetUsagePercentage.toStringAsFixed(1)}% of total budget used',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDailyView(TripProvider tripProvider, List<Trip> trips) {
    // Collect all expenses across all trips
    Map<DateTime, double> dailySpending = {};

    for (var trip in trips) {
      final expenses = tripProvider.getExpenses(trip.id);
      for (var expense in expenses) {
        final date = DateTime(
          expense.expenseDate.year,
          expense.expenseDate.month,
          expense.expenseDate.day,
        );
        dailySpending[date] = (dailySpending[date] ?? 0) + expense.amount;
      }
    }

    if (dailySpending.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No expenses recorded yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ),
        ),
      ];
    }

    // Sort by date
    final sortedDates = dailySpending.keys.toList()..sort();
    final avgDaily =
        dailySpending.values.reduce((a, b) => a + b) / dailySpending.length;

    return [
      Text(
        'Daily Spending Trends',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),

      // Average Daily Spending
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.accentMint,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average Daily Spending',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${avgDaily.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.accentMint,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Line Chart
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Over Time',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: avgDaily > 0 ? avgDaily / 2 : 100,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              'RM${value.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < sortedDates.length) {
                              final date = sortedDates[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('MMM d').format(date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          sortedDates.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            dailySpending[sortedDates[index]]!,
                          ),
                        ),
                        isCurved: true,
                        color: AppTheme.accentMint,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.accentMint,
                              strokeWidth: 2,
                              strokeColor: AppTheme.background,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.accentMint.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTripsComparisonView(
      TripProvider tripProvider, List<Trip> trips) {
    return [
      Text(
        'Trip Comparison',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      ...trips.map((trip) {
        final totalSpent = tripProvider.getTotalSpent(trip.id);
        final percentage = tripProvider.getBudgetPercentage(trip.id);
        final expenses = tripProvider.getExpenses(trip.id);
        final avgPerDay = _calculateAvgPerDay(trip, totalSpent);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentMint.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.accentMint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.destination,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactStat(
                        context,
                        'Spent',
                        'RM ${totalSpent.toStringAsFixed(0)}',
                        percentage > 80
                            ? AppTheme.errorColor
                            : AppTheme.accentMint,
                      ),
                    ),
                    Expanded(
                      child: _buildCompactStat(
                        context,
                        'Budget',
                        'RM ${trip.totalBudget.toStringAsFixed(0)}',
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildCompactStat(
                        context,
                        'Expenses',
                        expenses.length.toString(),
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildCompactStat(
                        context,
                        'Avg/Day',
                        'RM ${avgPerDay.toStringAsFixed(0)}',
                        AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 100
                          ? AppTheme.errorColor
                          : percentage > 80
                              ? AppTheme.warningColor
                              : AppTheme.accentMint,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}% of budget used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ];
  }

  List<Widget> _buildCategoriesView(
      TripProvider tripProvider, List<Trip> trips) {
    // Aggregate spending by category across all trips
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCount = {};

    for (var trip in trips) {
      final expenses = tripProvider.getExpenses(trip.id);
      for (var expense in expenses) {
        categoryTotals[expense.categoryName] =
            (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
        categoryCount[expense.categoryName] =
            (categoryCount[expense.categoryName] ?? 0) + 1;
      }
    }

    if (categoryTotals.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No expenses recorded yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ),
        ),
      ];
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpent = categoryTotals.values.reduce((a, b) => a + b);

    return [
      Text(
        'Spending by Category',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      ...sortedCategories.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        final count = categoryCount[category]!;
        final percentage = (amount / totalSpent) * 100;
        final avgPerExpense = amount / count;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            '$count expenses • Avg: RM ${avgPerExpense.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${amount.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(category),
                                  ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(category),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ];
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create trips and add expenses to see analytics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAvgPerDay(Trip trip, double totalSpent) {
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    return days > 0 ? totalSpent / days : totalSpent;
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

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Export Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.file_download, color: AppTheme.accentMint),
              title: const Text('Export to CSV'),
              subtitle: const Text('Download spreadsheet file'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.picture_as_pdf, color: AppTheme.accentMint),
              title: const Text('Export to PDF'),
              subtitle: const Text('Generate PDF report (Coming soon)'),
              enabled: false,
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement PDF export
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _exportToCSV(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final trips = tripProvider.trips;

    // Generate CSV content
    StringBuffer csv = StringBuffer();
    csv.writeln(
        'Trip Destination,Start Date,End Date,Total Budget,Total Spent,Expenses Count');

    for (var trip in trips) {
      final totalSpent = tripProvider.getTotalSpent(trip.id);
      final expenses = tripProvider.getExpenses(trip.id);
      csv.writeln(
          '"${trip.destination}","${DateFormat('yyyy-MM-dd').format(trip.startDate)}","${DateFormat('yyyy-MM-dd').format(trip.endDate)}",${trip.totalBudget},${totalSpent},${expenses.length}');
    }

    // Show success message with data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('CSV Export Ready'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your analytics data has been generated:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                csv.toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Copy the data above and paste it into a spreadsheet application.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
