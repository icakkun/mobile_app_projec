import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  String? _currentUserId;

  void setUserId(String userId) {
    _currentUserId = userId;
    print('🔥 FirestoreService: Set userId to $userId');
  }

  // Get trips stream for current user
  Stream<List<Trip>> getTripsStream() {
    if (_currentUserId == null) {
      print('❌ FirestoreService: No user ID set!');
      return Stream.value([]);
    }

    print(
        '🔥 FirestoreService: Getting trips stream for user: $_currentUserId');

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
          '🔥 FirestoreService: Received ${snapshot.docs.length} trip documents');
      return snapshot.docs.map((doc) => _tripFromFirestore(doc)).toList();
    });
  }

  // Get expenses stream for a trip
  Stream<List<Expense>> getExpensesStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _expenseFromFirestore(doc, tripId))
          .toList();
    });
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
    if (_currentUserId == null) {
      throw Exception('No user ID set');
    }

    final tripId = _uuid.v4();
    final now = Timestamp.now();

    print('🔥 FirestoreService: Adding trip $tripId');

    await _firestore.collection('trips').doc(tripId).set({
      'title': title,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'homeCurrency': homeCurrency,
      'totalBudget': totalBudget,
      'userId': _currentUserId,
      'createdAt': now,
    });

    // Add category budgets if provided
    if (categoryBudgets != null && categoryBudgets.isNotEmpty) {
      final batch = _firestore.batch();
      for (var categoryBudget in categoryBudgets) {
        final budgetRef = _firestore
            .collection('trips')
            .doc(tripId)
            .collection('categoryBudgets')
            .doc(categoryBudget.id);

        batch.set(budgetRef, {
          'categoryName': categoryBudget.categoryName,
          'limitAmount': categoryBudget.limitAmount,
        });
      }
      await batch.commit();
    }
  }

  // Update an existing trip
  // ✅ OPTIMIZED: Uses batch operations for SPEED (safe for updates)
  Future<void> updateTrip(String tripId, Trip trip) async {
    if (_currentUserId == null) {
      throw Exception('No user ID set');
    }

    print('🔥 FirestoreService: Updating trip $tripId');

    try {
      // Step 1: Update trip document
      await _firestore.collection('trips').doc(tripId).update({
        'title': trip.title,
        'destination': trip.destination,
        'startDate': Timestamp.fromDate(trip.startDate),
        'endDate': Timestamp.fromDate(trip.endDate),
        'homeCurrency': trip.homeCurrency,
        'totalBudget': trip.totalBudget,
      });

      // Step 2: Get existing category budgets
      final existingBudgets = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('categoryBudgets')
          .get();

      // Step 3: Use batch to delete old and add new budgets (FAST!)
      final batch = _firestore.batch();

      // Delete all existing budgets in batch
      for (var doc in existingBudgets.docs) {
        batch.delete(doc.reference);
      }

      // Add new category budgets in same batch
      if (trip.categoryBudgets.isNotEmpty) {
        for (var categoryBudget in trip.categoryBudgets) {
          final budgetRef = _firestore
              .collection('trips')
              .doc(tripId)
              .collection('categoryBudgets')
              .doc(categoryBudget.id);

          batch.set(budgetRef, {
            'categoryName': categoryBudget.categoryName,
            'limitAmount': categoryBudget.limitAmount,
          });
        }
      }

      // Commit all changes at once (FAST - ~100ms instead of ~500ms)
      await batch.commit();
      print('✅ Trip updated successfully');
    } catch (e) {
      print('❌ Error updating trip: $e');
      rethrow;
    }
  }

  // Delete a trip and all its expenses
  // ✅ RELIABLE: Uses sequential operations (needed for delete to avoid errors)
  Future<void> deleteTrip(String tripId) async {
    if (_currentUserId == null) {
      throw Exception('No user ID set');
    }

    print('🔥 FirestoreService: Deleting trip $tripId');

    try {
      // Step 1: Delete all expenses (one by one to avoid batch issues)
      print('🔥 Deleting expenses...');
      final expensesSnapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .get();

      if (expensesSnapshot.docs.isNotEmpty) {
        print('🔥 Found ${expensesSnapshot.docs.length} expenses to delete');
        for (var doc in expensesSnapshot.docs) {
          await doc.reference.delete();
        }
        print('✅ Expenses deleted');
      } else {
        print('✅ No expenses to delete');
      }

      // Step 2: Delete all category budgets (one by one)
      print('🔥 Deleting category budgets...');
      final budgetsSnapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('categoryBudgets')
          .get();

      if (budgetsSnapshot.docs.isNotEmpty) {
        print('🔥 Found ${budgetsSnapshot.docs.length} budgets to delete');
        for (var doc in budgetsSnapshot.docs) {
          await doc.reference.delete();
        }
        print('✅ Category budgets deleted');
      } else {
        print('✅ No category budgets to delete');
      }

      // Step 3: Delete the trip document itself
      print('🔥 Deleting trip document...');
      await _firestore.collection('trips').doc(tripId).delete();
      print('✅ Trip deleted successfully');
    } catch (e) {
      print('❌ Error deleting trip: $e');
      rethrow;
    }
  }

  // Add an expense
  Future<void> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
  }) async {
    final expenseId = _uuid.v4();
    final now = Timestamp.now();

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc(expenseId)
        .set({
      'amount': amount,
      'currency': currency,
      'categoryName': categoryName,
      'paidBy': paidBy,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'note': note,
      'createdAt': now,
    });
  }

  // Update an expense
  Future<void> updateExpense(
      String tripId, String expenseId, Expense expense) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'amount': expense.amount,
      'currency': expense.currency,
      'categoryName': expense.categoryName,
      'paidBy': expense.paidBy,
      'expenseDate': Timestamp.fromDate(expense.expenseDate),
      'note': expense.note,
    });
  }

  // Delete an expense
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // Convert Firestore document to Trip model
  Trip _tripFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      title: data['title'] ?? '',
      destination: data['destination'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      homeCurrency: data['homeCurrency'] ?? 'MYR',
      totalBudget: (data['totalBudget'] ?? 0).toDouble(),
      categoryBudgets: [], // Will be loaded separately if needed
    );
  }

  // Convert Firestore document to Expense model
  Expense _expenseFromFirestore(DocumentSnapshot doc, String tripId) {
    final data = doc.data() as Map<String, dynamic>;
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
  }

  // Get category budgets for a trip (called when needed)
  Future<List<CategoryBudget>> getCategoryBudgets(String tripId) async {
    final snapshot = await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('categoryBudgets')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CategoryBudget(
        id: doc.id,
        categoryName: data['categoryName'] ?? '',
        limitAmount: (data['limitAmount'] ?? 0).toDouble(),
      );
    }).toList();
  }
}
