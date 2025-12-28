import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class TripProvider with ChangeNotifier {
  final List<Trip> _trips = [];
  final Map<String, List<Expense>> _expenses = {};
  final _uuid = const Uuid();

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

  // Add a new trip
  void addTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) {
    final trip = Trip(
      id: _uuid.v4(),
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
    );
    _trips.insert(0, trip);
    _expenses[trip.id] = [];
    notifyListeners();
  }

  // Update trip
  void updateTrip(String id, Trip updatedTrip) {
    final index = _trips.indexWhere((trip) => trip.id == id);
    if (index != -1) {
      _trips[index] = updatedTrip;
      notifyListeners();
    }
  }

  // Delete trip
  void deleteTrip(String id) {
    _trips.removeWhere((trip) => trip.id == id);
    _expenses.remove(id);
    notifyListeners();
  }

  // Add expense
  void addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) {
    final expense = Expense(
      id: _uuid.v4(),
      tripId: tripId,
      amount: amount,
      currency: currency,
      categoryName: categoryName,
      paidBy: paidBy,
      expenseDate: expenseDate,
      note: note,
    );

    if (!_expenses.containsKey(tripId)) {
      _expenses[tripId] = [];
    }
    _expenses[tripId]!.insert(0, expense);
    notifyListeners();
  }

  // Update expense
  void updateExpense(String tripId, String expenseId, Expense updatedExpense) {
    final expenses = _expenses[tripId];
    if (expenses != null) {
      final index = expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        expenses[index] = updatedExpense;
        notifyListeners();
      }
    }
  }

  // Delete expense
  void deleteExpense(String tripId, String expenseId) {
    _expenses[tripId]?.removeWhere((e) => e.id == expenseId);
    notifyListeners();
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

    return categorySpent;
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
    return (getTotalSpent(tripId) / trip.totalBudget * 100).clamp(0, 100);
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
    return (spent / categoryBudget.limitAmount * 100).clamp(0, 100);
  }
}
