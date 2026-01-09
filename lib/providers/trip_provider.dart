import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import 'dart:async';

class TripProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Trip> _trips = [];
  final Map<String, List<Expense>> _expenses = {};
  final Map<String, StreamSubscription> _expenseSubscriptions = {};

  StreamSubscription? _tripsSubscription;
  String? _currentUserId;
  bool _isInitialized = false; // ✅ Track initialization state

  List<Trip> get trips => List.unmodifiable(_trips);

  List<Expense> getExpenses(String tripId) {
    return List.unmodifiable(_expenses[tripId] ?? []);
  }

  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ FIX: Prevent duplicate initialization
  Future<void> initialize(String userId) async {
    // If already initialized for this user, skip
    if (_isInitialized && _currentUserId == userId) {
      print('⚠️ TripProvider: Already initialized for this user, skipping');
      return;
    }

    // If initialized for different user, clean up first
    if (_isInitialized && _currentUserId != userId) {
      print('🔄 TripProvider: Switching user, cleaning up old data');
      await dispose();
    }

    print('🔥 TripProvider: Initializing with userId: $userId');
    _currentUserId = userId;
    _firestoreService.setUserId(userId);
    _isInitialized = true; // ✅ Mark as initialized

    _startTripsListener();
  }

  void _startTripsListener() {
    print('🔥 TripProvider: Starting trips listener');

    _tripsSubscription?.cancel();
    _tripsSubscription = _firestoreService.getTripsStream().listen(
      (trips) async {
        print('🔥 TripProvider: Received ${trips.length} trips from Firestore');
        _trips = trips;

        // Load category budgets for each trip
        for (var trip in _trips) {
          final categoryBudgets =
              await _firestoreService.getCategoryBudgets(trip.id);
          final index = _trips.indexWhere((t) => t.id == trip.id);
          if (index != -1) {
            _trips[index] = trip.copyWith(categoryBudgets: categoryBudgets);
          }
        }

        // Start expense listeners for new trips
        for (var trip in trips) {
          if (!_expenseSubscriptions.containsKey(trip.id)) {
            _startExpenseListener(trip.id);
          }
        }

        // Cancel expense listeners for removed trips
        final tripIds = trips.map((t) => t.id).toSet();
        final subscriptionIds = _expenseSubscriptions.keys.toList();
        for (var id in subscriptionIds) {
          if (!tripIds.contains(id)) {
            _expenseSubscriptions[id]?.cancel();
            _expenseSubscriptions.remove(id);
            _expenses.remove(id);
          }
        }

        notifyListeners();
      },
      onError: (error) {
        print('❌ TripProvider: Error listening to trips: $error');
      },
    );
  }

  void _startExpenseListener(String tripId) {
    _expenseSubscriptions[tripId]?.cancel();
    _expenseSubscriptions[tripId] =
        _firestoreService.getExpensesStream(tripId).listen(
      (expenses) {
        _expenses[tripId] = expenses;
        notifyListeners();
      },
      onError: (error) {
        print(
            '❌ TripProvider: Error listening to expenses for trip $tripId: $error');
      },
    );
  }

  // Add a new trip
  Future<void> addTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    await _firestoreService.addTrip(
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
    );
  }

  // Update trip
  Future<void> updateTrip(String id, Trip updatedTrip) async {
    await _firestoreService.updateTrip(id, updatedTrip);
  }

  // Delete trip
  Future<void> deleteTrip(String id) async {
    // Cancel expense subscription
    _expenseSubscriptions[id]?.cancel();
    _expenseSubscriptions.remove(id);
    _expenses.remove(id);

    // Delete from Firestore
    await _firestoreService.deleteTrip(id);
  }

  // Add expense
  Future<void> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) async {
    await _firestoreService.addExpense(
      tripId: tripId,
      amount: amount,
      currency: currency,
      categoryName: categoryName,
      paidBy: paidBy,
      expenseDate: expenseDate,
      note: note,
    );
  }

  // Update expense
  Future<void> updateExpense(
      String tripId, String expenseId, Expense updatedExpense) async {
    await _firestoreService.updateExpense(tripId, expenseId, updatedExpense);
  }

  // Delete expense
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestoreService.deleteExpense(tripId, expenseId);
  }

  // Calculate total spent for a trip
  double getTotalSpent(String tripId) {
    final expenses = _expenses[tripId] ?? [];
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Calculate spent by category
  Map<String, double> getSpentByCategory(String tripId) {
    final expenses = _expenses[tripId] ?? [];
    final Map<String, double> categorySpent = {};

    for (final expense in expenses) {
      categorySpent[expense.categoryName] =
          (categorySpent[expense.categoryName] ?? 0) + expense.amount;
    }

    // Sort by amount (descending)
    final sortedEntries = categorySpent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // Get remaining budget
  double getRemainingBudget(String tripId) {
    final trip = getTripById(tripId);
    if (trip == null) return 0;
    return trip.totalBudget - getTotalSpent(tripId);
  }

  // Get budget percentage used
  double getBudgetPercentage(String tripId) {
    final trip = getTripById(tripId);
    if (trip == null || trip.totalBudget == 0) return 0;
    return (getTotalSpent(tripId) / trip.totalBudget * 100);
  }

  // Get remaining for category budget
  double getCategoryRemaining(String tripId, CategoryBudget categoryBudget) {
    final spent = getSpentByCategory(tripId)[categoryBudget.categoryName] ?? 0;
    return categoryBudget.limitAmount - spent;
  }

  // Get category percentage
  double getCategoryPercentage(String tripId, CategoryBudget categoryBudget) {
    if (categoryBudget.limitAmount == 0) return 0;
    final spent = getSpentByCategory(tripId)[categoryBudget.categoryName] ?? 0;
    return (spent / categoryBudget.limitAmount * 100);
  }

  @override
  Future<void> dispose() async {
    print('🔥 TripProvider: Disposing');
    await _tripsSubscription?.cancel();
    for (var subscription in _expenseSubscriptions.values) {
      await subscription.cancel();
    }
    _expenseSubscriptions.clear();
    _expenses.clear();
    _trips.clear();
    _isInitialized = false; // ✅ Reset initialization flag
    super.dispose();
  }
}
