// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== TRIPS ====================

  // Get trips stream for current user
  Stream<List<Trip>> getTripsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Trip(
          id: doc.id,
          title: data['title'] ?? '',
          destination: data['destination'] ?? '',
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          homeCurrency: data['homeCurrency'] ?? 'MYR',
          totalBudget: (data['totalBudget'] ?? 0).toDouble(),
          categoryBudgets: (data['categoryBudgets'] as List?)
                  ?.map((item) => CategoryBudget(
                        id: item['id'] ?? '',
                        categoryName: item['categoryName'] ?? '',
                        limitAmount: (item['limitAmount'] ?? 0).toDouble(),
                      ))
                  .toList() ??
              [],
        );
      }).toList();
    });
  }

  // Add new trip
  Future<String?> addTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    try {
      if (currentUserId == null) return null;

      final docRef = await _firestore.collection('trips').add({
        'userId': currentUserId,
        'title': title,
        'destination': destination,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'homeCurrency': homeCurrency,
        'totalBudget': totalBudget,
        'categoryBudgets': categoryBudgets
                ?.map((cb) => {
                      'id': cb.id,
                      'categoryName': cb.categoryName,
                      'limitAmount': cb.limitAmount,
                    })
                .toList() ??
            [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error adding trip: $e');
      return null;
    }
  }

  // Update trip
  Future<bool> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('trips').doc(tripId).update(updates);
      return true;
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  // Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      // Delete all expenses first
      final expensesSnapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .get();

      final batch = _firestore.batch();
      for (var doc in expensesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the trip
      batch.delete(_firestore.collection('trips').doc(tripId));

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  // ==================== EXPENSES ====================

  // Get expenses stream for a trip
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

  // Add expense
  Future<String?> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) async {
    try {
      final docRef = await _firestore
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

      return docRef.id;
    } catch (e) {
      print('Error adding expense: $e');
      return null;
    }
  }

  // Update expense
  Future<bool> updateExpense(
      String tripId, String expenseId, Map<String, dynamic> updates) async {
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

  // Delete expense
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

  // ==================== ANALYTICS ====================

  // Get all expenses for analytics (could be expensive, use wisely)
  Future<List<Expense>> getAllExpensesForTrip(String tripId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .get();

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
    } catch (e) {
      print('Error getting expenses: $e');
      return [];
    }
  }
}
