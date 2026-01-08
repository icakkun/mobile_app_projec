import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_mint/screens/dashboard_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/Auth/login_screen.dart';

/// AuthGate decides whether to show LoginScreen or TripsScreen
/// based on authentication state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show login screen if user is not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Show main app if user is authenticated
        return const DashboardScreen();
      },
    );
  }
}
