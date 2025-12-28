import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart';
import 'screens/trips_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const TripMintApp());
}

class TripMintApp extends StatelessWidget {
  const TripMintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TripProvider(),
      child: MaterialApp(
        title: 'Trip Mint',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const TripsScreen(),
      ),
    );
  }
}
