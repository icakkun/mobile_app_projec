// trip_provider.dart

import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

class TripProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Trip> _trips = [];
  Map<String, List<Expense>> _expensesCache = {};
  bool _isLoading = false;

  // Getters
  List<Trip> get trips => List.unmodifiable(_trips);
  bool get isLoading => _isLoading;

  TripProvider() {
    _initializeTripsListener();
  }

  // Initialize real-time listener for trips
  void _initializeTripsListener() {
    _firestoreService.getTripsStream().listen((trips) {
      _trips = trips;
      notifyListeners();
    });
  }

  // Get expenses for a trip (uses cache or fetches from Firestore)
  List<Expense> getExpenses(String tripId) {
    return List.unmodifiable(_expensesCache[tripId] ?? []);
  }

  // Initialize expense listener for a specific trip
  void listenToExpenses(String tripId) {
    _firestoreService.getExpensesStream(tripId).listen((expenses) {
      _expensesCache[tripId] = expenses;
      notifyListeners();
    });
  }

  // Get trip by ID
  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== TRIP OPERATIONS ====================

  // Add a new trip
  Future<bool> addTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    _isLoading = true;
    notifyListeners();

    final tripId = await _firestoreService.addTrip(
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
    );

    _isLoading = false;
    notifyListeners();

    return tripId != null;
  }

  // Update trip
  Future<bool> updateTrip(String id, Trip updatedTrip) async {
    final updates = {
      'title': updatedTrip.title,
      'destination': updatedTrip.destination,
      'startDate': updatedTrip.startDate,
      'endDate': updatedTrip.endDate,
      'homeCurrency': updatedTrip.homeCurrency,
      'totalBudget': updatedTrip.totalBudget,
      'categoryBudgets': updatedTrip.categoryBudgets
          .map((cb) => {
                'id': cb.id,
                'categoryName': cb.categoryName,
                'limitAmount': cb.limitAmount,
              })
          .toList(),
    };

    return await _firestoreService.updateTrip(id, updates);
  }

  // Delete trip
  Future<bool> deleteTrip(String id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _firestoreService.deleteTrip(id);

    // Remove from cache
    _expensesCache.remove(id);

    _isLoading = false;
    notifyListeners();

    return success;
  }

  // ==================== EXPENSE OPERATIONS ====================

  // Add expense
  Future<bool> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) async {
    final expenseId = await _firestoreService.addExpense(
      tripId: tripId,
      amount: amount,
      currency: currency,
      categoryName: categoryName,
      paidBy: paidBy,
      expenseDate: expenseDate,
      note: note,
    );

    return expenseId != null;
  }

  // Update expense
  Future<bool> updateExpense(
      String tripId, String expenseId, Expense updatedExpense) async {
    final updates = {
      'amount': updatedExpense.amount,
      'currency': updatedExpense.currency,
      'categoryName': updatedExpense.categoryName,
      'paidBy': updatedExpense.paidBy,
      'expenseDate': updatedExpense.expenseDate,
      'note': updatedExpense.note,
    };

    return await _firestoreService.updateExpense(tripId, expenseId, updates);
  }

  // Delete expense
  Future<bool> deleteExpense(String tripId, String expenseId) async {
    return await _firestoreService.deleteExpense(tripId, expenseId);
  }

  // ==================== CALCULATIONS ====================

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

    // Sort by value (descending)
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
    final percentage = (getTotalSpent(tripId) / trip.totalBudget * 100);
    return percentage.clamp(0, 999); // Cap at 999% for display
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
    final percentage = (spent / categoryBudget.limitAmount * 100);
    return percentage.clamp(0, 999); // Cap at 999% for display
  }

  // Clean up
  @override
  void dispose() {
    _expensesCache.clear();
    super.dispose();
  }
}
