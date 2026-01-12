import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/trip_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/currency_exchange_screen.dart';
import 'screens/auth_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ PLATFORM-SPECIFIC FIREBASE INITIALIZATION
  if (kIsWeb) {
    // WEB: Use explicit options
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCj29Fu3EbDXiJ9TwLmMLh8wmOgyfOPYBQ",
        authDomain: "trip-mint.firebaseapp.com",
        projectId: "trip-mint",
        storageBucket: "trip-mint.firebasestorage.app",
        messagingSenderId: "754069301016",
        appId: "1:754069301016:web:03c28b3f7ef99c7c66e06d",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const TripMintApp());
}

class TripMintApp extends StatelessWidget {
  const TripMintApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Provider created ONCE at app level - prevents spam
    return ChangeNotifierProvider(
      create: (_) => TripProvider(),
      lazy: false,
      child: MaterialApp(
        title: 'Trip Mint',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && !_initialized) {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        tripProvider.initialize(user.uid);
        _initialized = true;
        print('✅ Provider initialized once for user: ${user.uid}');
      } else if (user == null) {
        _initialized = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentMint,
              ),
            ),
          );
        }

        // ✅ User logged in - go to main app shell with bottom navigation
        if (snapshot.hasData) {
          return const AppShell();
        }

        // Not logged in - show auth screen
        return const AuthScreen();
      },
    );
  }
}

// ✅ Main app shell with bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TripsScreen(),
    const CurrencyExchangeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Exchange',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
