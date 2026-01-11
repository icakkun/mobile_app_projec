import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'trip_details_screen.dart';
import 'create_trip_screen.dart';
import 'settings_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Blue-ish background tint helpers (UI only)
    final blueTint = Colors.blue.withOpacity(0.12);
    final blueBorder = Colors.blue.withOpacity(0.22);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Trip Mint'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Blue-ish gradient background like dashboard
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.background,
                    Color.alphaBlend(blueTint, AppTheme.background),
                    AppTheme.background,
                  ],
                ),
              ),
            ),
          ),

          // ✅ subtle blue glow blobs
          Positioned(
            top: -140,
            left: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.14),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentMint.withOpacity(0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.transparent),
            ),
          ),

          Consumer<TripProvider>(
            builder: (context, tripProvider, child) {
              final trips = tripProvider.trips;

              if (trips.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Color.alphaBlend(
                              Colors.blue.withOpacity(0.10),
                              AppTheme.cardBackground,
                            ),
                            border: Border.all(color: blueBorder),
                          ),
                          child: Icon(
                            Icons.flight_takeoff,
                            size: 46,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'No trips yet',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first trip to get started',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateTripScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Trip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentMint,
                              foregroundColor: AppTheme.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  final totalSpent = tripProvider.getTotalSpent(trip.id);
                  final remaining = tripProvider.getRemainingBudget(trip.id);
                  final percentage = tripProvider.getBudgetPercentage(trip.id);

                  final spentColor = percentage > 80
                      ? AppTheme.errorColor
                      : AppTheme.accentMint;

                  final progressColor = percentage > 100
                      ? AppTheme.errorColor
                      : percentage > 80
                          ? AppTheme.warningColor
                          : AppTheme.accentMint;

                  return _TripCardBlue(
                    destination: trip.destination,
                    dateRange:
                        '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                    spentText:
                        '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${totalSpent.toStringAsFixed(2)}',
                    remainingText:
                        '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${remaining.toStringAsFixed(2)}',
                    spentColor: spentColor,
                    progressValue: (percentage / 100).clamp(0.0, 1.0),
                    progressColor: progressColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TripDetailsScreen(tripId: trip.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTripScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
        backgroundColor: AppTheme.accentMint,
        foregroundColor: AppTheme.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _TripCardBlue extends StatelessWidget {
  final String destination;
  final String dateRange;
  final String spentText;
  final String remainingText;
  final Color spentColor;
  final double progressValue;
  final Color progressColor;
  final VoidCallback onTap;

  const _TripCardBlue({
    required this.destination,
    required this.dateRange,
    required this.spentText,
    required this.remainingText,
    required this.spentColor,
    required this.progressValue,
    required this.progressColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardFill = Color.alphaBlend(
      Colors.blue.withOpacity(0.10),
      AppTheme.cardBackground,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 0,
        color: cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.blue.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.blue.withOpacity(0.16),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.22),
                        ),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppTheme.accentMint,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateRange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary),
                  ],
                ),

                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatBlue(
                        label: 'Spent',
                        value: spentText,
                        valueColor: spentColor,
                        alignEnd: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStatBlue(
                        label: 'Remaining',
                        value: remainingText,
                        valueColor: AppTheme.textPrimary,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: AppTheme.textSecondary.withOpacity(0.16),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatBlue extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  const _MiniStatBlue({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
