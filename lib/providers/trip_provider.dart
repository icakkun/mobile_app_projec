import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

class TripProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Trip> _trips = [];
  Map<String, List<Expense>> _expensesCache = {};
  StreamSubscription? _tripsSubscription;
  final Map<String, StreamSubscription> _expenseSubscriptions = {};

  List<Trip> get trips => List.unmodifiable(_trips);

  List<Expense> getExpenses(String tripId) {
    return List.unmodifiable(_expensesCache[tripId] ?? []);
  }

  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  // Initialize with user ID and start listening to Firestore
  void initialize(String userId) {
    print('🔥 TripProvider: Initializing with userId: $userId');
    _firestoreService.setUserId(userId);
    _listenToTrips();
  }

  // Listen to trips stream from Firestore
  void _listenToTrips() {
    print('🔥 TripProvider: Starting trips listener');
    _tripsSubscription?.cancel();
    _tripsSubscription = _firestoreService.getTripsStream().listen(
      (trips) {
        print('🔥 TripProvider: Received ${trips.length} trips from Firestore');
        _trips = trips;
        notifyListeners();
      },
      onError: (error) {
        print('❌ TripProvider: Error listening to trips: $error');
      },
    );
  }

  // Listen to expenses for a specific trip
  void _listenToExpenses(String tripId) {
    _expenseSubscriptions[tripId]?.cancel();
    _expenseSubscriptions[tripId] =
        _firestoreService.getExpensesStream(tripId).listen(
      (expenses) {
        _expensesCache[tripId] = expenses;
        notifyListeners();
      },
      onError: (error) {
        print(
            '❌ TripProvider: Error listening to expenses for trip $tripId: $error');
      },
    );
  }

  // Add a new trip (saves to Firestore)
  Future<void> addTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    print('🔥 TripProvider: Adding trip to Firestore');
    await _firestoreService.addTrip(
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
    );
    // No need to call notifyListeners() - the stream will update automatically
  }

  // Update an existing trip (updates in Firestore)
  Future<void> updateTrip(String tripId, Trip updatedTrip) async {
    print('🔥 TripProvider: Updating trip $tripId in Firestore');
    await _firestoreService.updateTrip(tripId, updatedTrip);
    // No need to call notifyListeners() - the stream will update automatically
  }

  // Delete a trip (deletes from Firestore)
  Future<void> deleteTrip(String tripId) async {
    print('🔥 TripProvider: Deleting trip $tripId from Firestore');

    // Cancel expense subscription for this trip
    _expenseSubscriptions[tripId]?.cancel();
    _expenseSubscriptions.remove(tripId);
    _expensesCache.remove(tripId);

    await _firestoreService.deleteTrip(tripId);
    // No need to call notifyListeners() - the stream will update automatically
  }

  // Add expense (saves to Firestore)
  Future<void> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) async {
    // Start listening to expenses for this trip if not already
    if (!_expenseSubscriptions.containsKey(tripId)) {
      _listenToExpenses(tripId);
    }

    await _firestoreService.addExpense(
      tripId: tripId,
      amount: amount,
      currency: currency,
      categoryName: categoryName,
      paidBy: paidBy,
      expenseDate: expenseDate,
      note: note,
    );
    // No need to call notifyListeners() - the stream will update automatically
  }

  // Update expense (updates in Firestore)
  Future<void> updateExpense(
      String tripId, String expenseId, Expense updatedExpense) async {
    await _firestoreService.updateExpense(tripId, expenseId, updatedExpense);
    // No need to call notifyListeners() - the stream will update automatically
  }

  // Delete expense (deletes from Firestore)
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestoreService.deleteExpense(tripId, expenseId);
    // No need to call notifyListeners() - the stream will update automatically
  }

  // Calculate total spent for a trip
  double getTotalSpent(String tripId) {
    final expenses = _expensesCache[tripId] ?? [];
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Calculate spent by category
  Map<String, double> getSpentByCategory(String tripId) {
    final expenses = _expensesCache[tripId] ?? [];
    final Map<String, double> categorySpent = {};

    for (final expense in expenses) {
      categorySpent[expense.categoryName] =
          (categorySpent[expense.categoryName] ?? 0) + expense.amount;
    }

    // Sort by amount (highest first)
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
  void dispose() {
    _tripsSubscription?.cancel();
    for (var subscription in _expenseSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
