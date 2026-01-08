// main.dart - FIRESTORE VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/trip_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'widgets/app_shell.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TripMintApp());
}

class TripMintApp extends StatelessWidget {
  const TripMintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => TripProvider()),
      ],
      child: MaterialApp(
        title: 'Trip Mint',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer2<AuthProvider, TripProvider>(
          builder: (context, authProvider, tripProvider, _) {
            // Show loading
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Show login if not authenticated
            if (authProvider.user == null) {
              return const LoginScreen();
            }

            // Initialize TripProvider with user ID
            final userId = authProvider.user!.uid;
            tripProvider.initialize(userId);

            // Show app shell with bottom nav
            return const AppShell();
          },
        ),
      ),
    );
  }
}
