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
  bool _isInitialized = false;

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

  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      print('⚠️ TripProvider: Already initialized for this user, skipping');
      return;
    }

    if (_isInitialized && _currentUserId != userId) {
      print('🔄 TripProvider: Switching user, cleaning up old data');
      await dispose();
    }

    print('🔥 TripProvider: Initializing with userId: $userId');
    _currentUserId = userId;
    _firestoreService.setUserId(userId);
    _isInitialized = true;

    _startTripsListener();
  }

  void _startTripsListener() {
    print('🔥 TripProvider: Starting trips listener');

    _tripsSubscription?.cancel();
    _tripsSubscription = _firestoreService.getTripsStream().listen(
      (trips) async {
        print('🔥 TripProvider: Received ${trips.length} trips from Firestore');
        _trips = trips;

        for (var trip in _trips) {
          final categoryBudgets =
              await _firestoreService.getCategoryBudgets(trip.id);
          final index = _trips.indexWhere((t) => t.id == trip.id);
          if (index != -1) {
            _trips[index] = trip.copyWith(categoryBudgets: categoryBudgets);
          }
        }

        for (var trip in trips) {
          if (!_expenseSubscriptions.containsKey(trip.id)) {
            _startExpenseListener(trip.id);
          }
        }

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

  Future<void> updateTrip(String id, Trip updatedTrip) async {
    await _firestoreService.updateTrip(id, updatedTrip);
  }

  Future<void> deleteTrip(String id) async {
    _expenseSubscriptions[id]?.cancel();
    _expenseSubscriptions.remove(id);
    _expenses.remove(id);
    await _firestoreService.deleteTrip(id);
  }

  // ✅ FIXED: Now passing receiptImageUrl to FirestoreService
  Future<void> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
    String? receiptImageUrl, // ← Parameter exists
  }) async {
    await _firestoreService.addExpense(
      tripId: tripId,
      amount: amount,
      currency: currency,
      categoryName: categoryName,
      paidBy: paidBy,
      expenseDate: expenseDate,
      note: note,
      receiptImageUrl: receiptImageUrl, // ← NOW PASSING IT!
    );
  }

  Future<void> updateExpense(
      String tripId, String expenseId, Expense updatedExpense) async {
    await _firestoreService.updateExpense(tripId, expenseId, updatedExpense);
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestoreService.deleteExpense(tripId, expenseId);
  }

  double getTotalSpent(String tripId) {
    final expenses = _expenses[tripId] ?? [];
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getSpentByCategory(String tripId) {
    final expenses = _expenses[tripId] ?? [];
    final Map<String, double> categorySpent = {};

    for (final expense in expenses) {
      categorySpent[expense.categoryName] =
          (categorySpent[expense.categoryName] ?? 0) + expense.amount;
    }

    final sortedEntries = categorySpent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  double getRemainingBudget(String tripId) {
    final trip = getTripById(tripId);
    if (trip == null) return 0;
    return trip.totalBudget - getTotalSpent(tripId);
  }

  double getBudgetPercentage(String tripId) {
    final trip = getTripById(tripId);
    if (trip == null || trip.totalBudget == 0) return 0;
    return (getTotalSpent(tripId) / trip.totalBudget * 100);
  }

  double getCategoryRemaining(String tripId, CategoryBudget categoryBudget) {
    final spent = getSpentByCategory(tripId)[categoryBudget.categoryName] ?? 0;
    return categoryBudget.limitAmount - spent;
  }

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
    _isInitialized = false;
    super.dispose();
  }
}
