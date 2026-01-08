// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID (you'll pass this in)
  String? _currentUserId;

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  // TRIPS STREAM - Real-time updates
  Stream<List<Trip>> getTripsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Parse category budgets
        List<CategoryBudget> categoryBudgets = [];
        if (data['categoryBudgets'] != null) {
          final budgetsList = data['categoryBudgets'] as List<dynamic>;
          categoryBudgets = budgetsList.map((budget) {
            return CategoryBudget(
              id: budget['id'] ?? '',
              categoryName: budget['categoryName'] ?? '',
              limitAmount: (budget['limitAmount'] ?? 0).toDouble(),
            );
          }).toList();
        }

        return Trip(
          id: doc.id,
          title: data['title'] ?? '',
          destination: data['destination'] ?? '',
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          homeCurrency: data['homeCurrency'] ?? 'MYR',
          totalBudget: (data['totalBudget'] ?? 0).toDouble(),
          categoryBudgets: categoryBudgets,
        );
      }).toList();
    });
  }

  // EXPENSES STREAM - Real-time updates for a specific trip
  Stream<List<Expense>> getExpensesStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          id: doc.id,
          tripId: tripId,
          amount: (data['amount'] ?? 0).toDouble(),
          currency: data['currency'] ?? 'MYR',
          categoryName: data['categoryName'] ?? '',
          paidBy: data['paidBy'] ?? '',
          expenseDate: (data['expenseDate'] as Timestamp).toDate(),
          note: data['note'] ?? '',
        );
      }).toList();
    });
  }

  // ADD TRIP
  Future<bool> addTrip({
    required String userId,
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    try {
      final categoryBudgetsData = categoryBudgets?.map((budget) {
            return {
              'id': budget.id,
              'categoryName': budget.categoryName,
              'limitAmount': budget.limitAmount,
            };
          }).toList() ??
          [];

      await _firestore.collection('trips').add({
        'userId': userId,
        'title': title,
        'destination': destination,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'homeCurrency': homeCurrency,
        'totalBudget': totalBudget,
        'categoryBudgets': categoryBudgetsData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding trip: $e');
      return false;
    }
  }

  // ADD EXPENSE
  Future<bool> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .add({
        'amount': amount,
        'currency': currency,
        'categoryName': categoryName,
        'paidBy': paidBy,
        'expenseDate': Timestamp.fromDate(expenseDate),
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding expense: $e');
      return false;
    }
  }

  // UPDATE TRIP
  Future<bool> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('trips').doc(tripId).update(updates);
      return true;
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  // DELETE TRIP
  Future<bool> deleteTrip(String tripId) async {
    try {
      // Delete all expenses first
      final expensesSnapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .get();

      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the trip
      await _firestore.collection('trips').doc(tripId).delete();
      return true;
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  // UPDATE EXPENSE
  Future<bool> updateExpense(
    String tripId,
    String expenseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .doc(expenseId)
          .update(updates);
      return true;
    } catch (e) {
      print('Error updating expense: $e');
      return false;
    }
  }

  // DELETE EXPENSE
  Future<bool> deleteExpense(String tripId, String expenseId) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }
}
