import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/pdf_service.dart';
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

  // Local-only UI palette (keeps app theme colors, adds blue-ish surfaces)
  static const Color _kNavy1 = Color(0xFF0B1422);
  static const Color _kNavy2 = Color(0xFF0F1B2E);
  static const Color _kCard = Color(0xFF111F33);
  static const Color _kBorder = Color(0xFF233A57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Enhanced Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _IconChipButton(
              tooltip: 'Export Data',
              icon: Icons.download,
              onPressed: () => _showExportDialog(context),
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
            // subtle blue glow blobs (UI only)
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
                  color: const Color(0xFF4DA3FF).withOpacity(0.10),
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
              child: Consumer<TripProvider>(
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
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            if (_selectedView == 'overview')
                              ..._buildOverviewView(tripProvider, trips),
                            if (_selectedView == 'daily')
                              ..._buildDailyView(tripProvider, trips),
                            if (_selectedView == 'trips')
                              ..._buildTripsComparisonView(tripProvider, trips),
                            if (_selectedView == 'categories')
                              ..._buildCategoriesView(tripProvider, trips),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _GlassCard(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildViewChip('overview', 'Overview', Icons.dashboard_outlined),
              const SizedBox(width: 10),
              _buildViewChip('daily', 'Daily Trends', Icons.show_chart),
              const SizedBox(width: 10),
              _buildViewChip('trips', 'Compare Trips', Icons.compare_arrows),
              const SizedBox(width: 10),
              _buildViewChip(
                  'categories', 'Categories', Icons.pie_chart_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewChip(String value, String label, IconData icon) {
    final isSelected = _selectedView == value;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _selectedView = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentMint.withOpacity(0.16)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentMint.withOpacity(0.42)
                : Colors.white.withOpacity(0.10),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.accentMint.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.accentMint : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
      ),
      const SizedBox(height: 14),

      // Summary Cards (consistent size)
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total Spent',
              'RM ${totalSpent.toStringAsFixed(2)}',
              Icons.account_balance_wallet_outlined,
              AppTheme.accentMint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Total Budget',
              'RM ${totalBudget.toStringAsFixed(2)}',
              Icons.savings_outlined,
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
              Icons.receipt_long_outlined,
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
      const SizedBox(height: 18),

      // Budget Usage
      _GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Budget Usage',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (budgetUsagePercentage / 100).clamp(0.0, 1.0),
                backgroundColor: AppTheme.textSecondary.withOpacity(0.16),
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
            const SizedBox(height: 10),
            Text(
              '${budgetUsagePercentage.toStringAsFixed(1)}% of total budget used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildDailyView(TripProvider tripProvider, List<Trip> trips) {
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
        _GlassCard(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Text(
              'No expenses recorded yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ];
    }

    final sortedDates = dailySpending.keys.toList()..sort();
    final avgDaily =
        dailySpending.values.reduce((a, b) => a + b) / dailySpending.length;

    return [
      Text(
        'Daily Spending Trends',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
      ),
      const SizedBox(height: 14),
      _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentMint.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accentMint.withOpacity(0.22),
                ),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppTheme.accentMint,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average Daily Spending',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${avgDaily.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.accentMint,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Over Time',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: avgDaily > 0 ? avgDaily / 2 : 100,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.textSecondary.withOpacity(0.10),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'RM${value.toInt()}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                DateFormat('MMM d').format(date),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                            strokeColor: _kCard,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accentMint.withOpacity(0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildTripsComparisonView(
      TripProvider tripProvider, List<Trip> trips) {
    return [
      Text(
        'Trip Comparison',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
      ),
      const SizedBox(height: 14),
      ...trips.map((trip) {
        final totalSpent = tripProvider.getTotalSpent(trip.id);
        final percentage = tripProvider.getBudgetPercentage(trip.id);
        final expenses = tripProvider.getExpenses(trip.id);
        final avgPerDay = _calculateAvgPerDay(trip, totalSpent);

        return _GlassCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentMint.withOpacity(0.22),
                      ),
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
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.textSecondary.withOpacity(0.16),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 100
                        ? AppTheme.errorColor
                        : percentage > 80
                            ? AppTheme.warningColor
                            : AppTheme.accentMint,
                  ),
                  minHeight: 9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(1)}% of budget used',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    ];
  }

  List<Widget> _buildCategoriesView(
      TripProvider tripProvider, List<Trip> trips) {
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
        _GlassCard(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Text(
              'No expenses recorded yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
      ),
      const SizedBox(height: 14),
      ...sortedCategories.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        final count = categoryCount[category]!;
        final percentage = (amount / totalSpent) * 100;
        final avgPerExpense = amount / count;

        final catColor = _getCategoryColor(category);

        return _GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: catColor.withOpacity(0.22)),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: catColor,
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
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count expenses • Avg: RM ${avgPerExpense.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: catColor,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.textSecondary.withOpacity(0.16),
                  valueColor: AlwaysStoppedAnimation<Color>(catColor),
                  minHeight: 7,
                ),
              ),
            ],
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
    return SizedBox(
      height: 108, // ✅ consistent height to prevent overflow / uneven rows
      child: _GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.22)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
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

  Widget _buildCompactStat(
      BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _GlassCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                'No Data Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
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

  void _exportToPDF(BuildContext context) async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final trips = tripProvider.trips;

    if (trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Collect data
      Map<String, double> tripSpent = {};
      Map<String, int> tripExpenseCount = {};
      Map<String, double> categoryTotals = {};

      for (var trip in trips) {
        final totalSpent = tripProvider.getTotalSpent(trip.id);
        final expenses = tripProvider.getExpenses(trip.id);

        tripSpent[trip.id] = totalSpent;
        tripExpenseCount[trip.id] = expenses.length;

        // Aggregate categories
        for (var expense in expenses) {
          categoryTotals[expense.categoryName] =
              (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
        }
      }

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Generate PDF
      await PdfService.generateAnalyticsReport(
        trips: trips,
        tripSpent: tripSpent,
        tripExpenseCount: tripExpenseCount,
        categoryTotals: categoryTotals,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.background),
                SizedBox(width: 12),
                Text('Analytics PDF generated!'),
              ],
            ),
            backgroundColor: AppTheme.accentMint,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _GlassCard(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Export Analytics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                const Divider(height: 18, color: _kBorder),

                // ✅ PDF Export (NOW FUNCTIONAL!)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentMint.withOpacity(0.22),
                      ),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: AppTheme.accentMint),
                  ),
                  title: Text(
                    'Export to PDF',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Generate professional report',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToPDF(context);
                  },
                ),

                // CSV Export (existing)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.22),
                      ),
                    ),
                    child: const Icon(Icons.file_download, color: Colors.blue),
                  ),
                  title: Text(
                    'Export to CSV',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Copy spreadsheet-ready data',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToCSV(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportToCSV(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final trips = tripProvider.trips;

    StringBuffer csv = StringBuffer();
    csv.writeln(
        'Trip Destination,Start Date,End Date,Total Budget,Total Spent,Expenses Count');

    for (var trip in trips) {
      final totalSpent = tripProvider.getTotalSpent(trip.id);
      final expenses = tripProvider.getExpenses(trip.id);
      csv.writeln(
          '"${trip.destination}","${DateFormat('yyyy-MM-dd').format(trip.startDate)}","${DateFormat('yyyy-MM-dd').format(trip.endDate)}",${trip.totalBudget},${totalSpent},${expenses.length}');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'CSV Export Ready',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your analytics data has been generated:',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kNavy1.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: SelectableText(
                  csv.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Copy the data above and paste it into a spreadsheet application.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.accentMint,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------------------------------
/// UI helpers (visual only)
/// --------------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    const border = _EnhancedAnalyticsScreenState._kBorder;
    const card = _EnhancedAnalyticsScreenState._kCard;

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: card.withOpacity(0.70),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border.withOpacity(0.9)),
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

    if (margin == null) return content;
    return Padding(padding: margin!, child: content);
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
