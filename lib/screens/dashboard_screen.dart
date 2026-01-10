import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:trip_mint/screens/trip_details_screen.dart';
import '../providers/trip_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'create_trip_screen.dart';
import 'enhanced_analytics_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ✅ Local UI palette (does NOT change your AppTheme values)
  static const Color kBgTop = Color(0xFF0A1220); // bluish-navy
  static const Color kBgBottom = Color(0xFF070D18);
  static const Color kCard = Color(0xFF0E1B2E); // navy surface
  static const Color kCard2 = Color(0xFF101F36);
  static const Color kBorder = Color(0xFF1E2C44);
  static const Color kText = Color(0xFFEAF0F7);
  static const Color kMuted = Color(0xFF9AA7B4);

  @override
  Widget build(BuildContext context) {
    // ✅ Use Firebase Auth directly instead of AuthProvider
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'Traveler';

    return Scaffold(
      backgroundColor: kBgTop,

      // ✅ Bluish AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $displayName! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Ready for your next adventure?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kMuted,
                  ),
            ),
          ],
        ),
        toolbarHeight: 80,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppTheme.accentMint,
              child: Text(
                user?.displayName?.substring(0, 1).toUpperCase() ??
                    user?.email?.substring(0, 1).toUpperCase() ??
                    'U',
                style: const TextStyle(
                  color: AppTheme.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Container(
        // ✅ Make whole page more “blue-ish”
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgTop, kBgBottom],
          ),
        ),
        child: Consumer<TripProvider>(
          builder: (context, tripProvider, child) {
            final trips = tripProvider.trips;

            // Calculate stats
            final totalTrips = trips.length;
            final activeTrips = trips
                .where((trip) => trip.endDate.isAfter(DateTime.now()))
                .length;

            double totalSpent = 0;
            double totalBudget = 0;
            for (var trip in trips) {
              totalSpent += tripProvider.getTotalSpent(trip.id);
              totalBudget += trip.totalBudget;
            }

            // Get recent trips (max 3)
            final recentTrips = trips.take(3).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ Quick Stats Cards (fixed height so they stay same size)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.flight_takeoff,
                        title: 'Total Trips',
                        value: totalTrips.toString(),
                        color: AppTheme.accentMint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.explore,
                        title: 'Active',
                        value: activeTrips.toString(),
                        color: const Color(0xFF4DA3FF),
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
                        icon: Icons.account_balance_wallet,
                        title: 'Total Spent',
                        value: 'RM ${totalSpent.toStringAsFixed(0)}',
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.savings,
                        title: 'Total Budget',
                        value: 'RM ${totalBudget.toStringAsFixed(0)}',
                        color: const Color(0xFF2EE59D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ✅ Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: kText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.add_circle,
                        title: 'New Trip',
                        subtitle: 'Plan your next adventure',
                        color: AppTheme.accentMint,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateTripScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.analytics,
                        title: 'Analytics',
                        subtitle: 'View detailed insights',
                        color: const Color(0xFF4DA3FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EnhancedAnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ✅ Recent Trips
                if (recentTrips.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Trips',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: kText,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tap "Trips" tab at the bottom'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(color: AppTheme.accentMint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...recentTrips.map((trip) {
                    final totalSpent = tripProvider.getTotalSpent(trip.id);
                    final percentage =
                        tripProvider.getBudgetPercentage(trip.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: kCard,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: kBorder, width: 1),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TripDetailsScreen(tripId: trip.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentMint.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppTheme.accentMint.withOpacity(0.22),
                                  ),
                                ),
                                child: Icon(
                                  Icons.location_on,
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
                                      trip.destination,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: kText,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d').format(trip.endDate)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: kMuted),
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.10),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          percentage > 100
                                              ? AppTheme.errorColor
                                              : percentage > 80
                                                  ? AppTheme.warningColor
                                                  : AppTheme.accentMint,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${AppConstants.getCurrencySymbol(trip.homeCurrency)}${totalSpent.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: percentage > 80
                                              ? AppTheme.errorColor
                                              : AppTheme.accentMint,
                                        ),
                                  ),
                                  Text(
                                    'of ${trip.totalBudget.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: kMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ] else ...[
                  // Empty state
                  Card(
                    color: kCard,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: kBorder, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flight_takeoff,
                            size: 64,
                            color: kMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No trips yet',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: kText,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first trip to get started!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: kMuted,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      height: 124, // ✅ was 110 (this is the main cause)
      child: Card(
        color: kCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.22)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kMuted,
                    ),
              ),

              const SizedBox(height: 6),

              // ✅ value will scale down instead of overflowing
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 140, // ✅ forces same size for both action cards
      child: Card(
        color: kCard2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorder, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.22)),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: kText,
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
