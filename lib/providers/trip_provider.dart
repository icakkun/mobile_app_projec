// trip_provider.dart - FIRESTORE VERSION

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import 'dart:async';

class TripProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Trip> _trips = [];
  final Map<String, List<Expense>> _expensesCache = {};
  final Map<String, StreamSubscription> _expenseSubscriptions = {};
  StreamSubscription? _tripsSubscription;

  List<Trip> get trips => List.unmodifiable(_trips);

  // Initialize with user ID and start listening
  void initialize(String userId) {
    _firestoreService.setUserId(userId);
    _listenToTrips();
  }

  // Listen to trips stream
  void _listenToTrips() {
    _tripsSubscription?.cancel();
    _tripsSubscription = _firestoreService.getTripsStream().listen((trips) {
      _trips = trips;
      notifyListeners();
    });
  }

  // Listen to expenses for a specific trip
  void listenToExpenses(String tripId) {
    if (_expenseSubscriptions.containsKey(tripId)) {
      return; // Already listening
    }

    final subscription =
        _firestoreService.getExpensesStream(tripId).listen((expenses) {
      _expensesCache[tripId] = expenses;
      notifyListeners();
    });

    _expenseSubscriptions[tripId] = subscription;
  }

  // Get expenses from cache
  List<Expense> getExpenses(String tripId) {
    return List.unmodifiable(_expensesCache[tripId] ?? []);
  }

  // Get trip by ID
  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add a new trip
  Future<void> addTrip({
    required String userId,
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    await _firestoreService.addTrip(
      userId: userId,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
    );
    // No need to notifyListeners() - stream will update automatically!
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
    // Stream will update automatically!
  }

  // Update trip
  Future<void> updateTrip(String id, Trip updatedTrip) async {
    // Convert to map for Firestore
    final updates = {
      'title': updatedTrip.title,
      'destination': updatedTrip.destination,
      'startDate': updatedTrip.startDate,
      'endDate': updatedTrip.endDate,
      'homeCurrency': updatedTrip.homeCurrency,
      'totalBudget': updatedTrip.totalBudget,
    };
    await _firestoreService.updateTrip(id, updates);
  }

  // Delete trip
  Future<void> deleteTrip(String id) async {
    await _firestoreService.deleteTrip(id);
    _expenseSubscriptions[id]?.cancel();
    _expenseSubscriptions.remove(id);
    _expensesCache.remove(id);
  }

  // Update expense
  Future<void> updateExpense(
      String tripId, String expenseId, Expense updatedExpense) async {
    final updates = {
      'amount': updatedExpense.amount,
      'currency': updatedExpense.currency,
      'categoryName': updatedExpense.categoryName,
      'paidBy': updatedExpense.paidBy,
      'expenseDate': updatedExpense.expenseDate,
      'note': updatedExpense.note,
    };
    await _firestoreService.updateExpense(tripId, expenseId, updates);
  }

  // Delete expense
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestoreService.deleteExpense(tripId, expenseId);
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

    // Sort by amount descending
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
