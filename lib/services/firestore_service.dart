import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  void setUserId(String userId) {
    _userId = userId;
  }

  // Get trips stream
  Stream<List<Trip>> getTripsStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Trip.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get expenses stream for a trip
  Stream<List<Expense>> getExpensesStream(String tripId) {
    return _firestore
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _expenseFromFirestore(doc, tripId))
          .toList();
    });
  }

  // ✅ UPDATED: Add receiptImageUrl to _expenseFromFirestore
  Expense _expenseFromFirestore(DocumentSnapshot doc, String tripId) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      tripId: tripId,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'MYR',
      categoryName: data['categoryName'] ?? '',
      paidBy: data['paidBy'] ?? '',
      expenseDate: (data['expenseDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] ?? '',
      receiptImageUrl: data['receiptImageUrl'], // ← ADDED THIS!
    );
  }

  // Add trip
  Future<void> addTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required double totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) async {
    if (_userId == null) return;

    final tripRef = await _firestore.collection('trips').add({
      'userId': _userId,
      'title': title,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'homeCurrency': homeCurrency,
      'totalBudget': totalBudget,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add category budgets if provided
    if (categoryBudgets != null && categoryBudgets.isNotEmpty) {
      final batch = _firestore.batch();
      for (var categoryBudget in categoryBudgets) {
        final catBudgetRef =
            _firestore.collection('trips/${tripRef.id}/categoryBudgets').doc();
        batch.set(catBudgetRef, {
          'categoryName': categoryBudget.categoryName,
          'limitAmount': categoryBudget.limitAmount,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // Update trip
  Future<void> updateTrip(String id, Trip updatedTrip) async {
    await _firestore.collection('trips').doc(id).update({
      'title': updatedTrip.title,
      'destination': updatedTrip.destination,
      'startDate': Timestamp.fromDate(updatedTrip.startDate),
      'endDate': Timestamp.fromDate(updatedTrip.endDate),
      'homeCurrency': updatedTrip.homeCurrency,
      'totalBudget': updatedTrip.totalBudget,
    });

    // Update category budgets
    final categoryBudgetsRef =
        _firestore.collection('trips/$id/categoryBudgets');

    // Delete existing category budgets
    final existingDocs = await categoryBudgetsRef.get();
    final batch = _firestore.batch();
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    // Add new category budgets
    for (var categoryBudget in updatedTrip.categoryBudgets) {
      final newDocRef = categoryBudgetsRef.doc();
      batch.set(newDocRef, {
        'categoryName': categoryBudget.categoryName,
        'limitAmount': categoryBudget.limitAmount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Delete trip
  Future<void> deleteTrip(String id) async {
    // Delete category budgets first
    final categoryBudgetsRef =
        _firestore.collection('trips/$id/categoryBudgets');
    final categoryDocs = await categoryBudgetsRef.get();
    for (var doc in categoryDocs.docs) {
      await doc.reference.delete();
    }

    // Delete all expenses for this trip
    final expenses = await _firestore
        .collection('expenses')
        .where('tripId', isEqualTo: id)
        .get();
    for (var doc in expenses.docs) {
      await doc.reference.delete();
    }

    // Delete the trip
    await _firestore.collection('trips').doc(id).delete();
  }

  // Get category budgets
  Future<List<CategoryBudget>> getCategoryBudgets(String tripId) async {
    final snapshot =
        await _firestore.collection('trips/$tripId/categoryBudgets').get();

    return snapshot.docs
        .map((doc) => CategoryBudget.fromFirestore(doc.data()))
        .toList();
  }

  // ✅ UPDATED: Add receiptImageUrl parameter
  Future<void> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String categoryName,
    required String paidBy,
    required DateTime expenseDate,
    String note = '',
    String? receiptImageUrl, // ← ADDED THIS PARAMETER!
  }) async {
    if (_userId == null) return;

    await _firestore.collection('expenses').add({
      'tripId': tripId,
      'userId': _userId,
      'amount': amount,
      'currency': currency,
      'categoryName': categoryName,
      'paidBy': paidBy,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': FieldValue.serverTimestamp(),
      'note': note,
      'receiptImageUrl': receiptImageUrl, // ← ADDED THIS FIELD!
    });
  }

  // Update expense
  Future<void> updateExpense(
      String tripId, String expenseId, Expense updatedExpense) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'amount': updatedExpense.amount,
      'currency': updatedExpense.currency,
      'categoryName': updatedExpense.categoryName,
      'paidBy': updatedExpense.paidBy,
      'expenseDate': Timestamp.fromDate(updatedExpense.expenseDate),
      'note': updatedExpense.note,
      'receiptImageUrl': updatedExpense.receiptImageUrl, // ← ADDED THIS!
    });
  }

  // Delete expense
  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }
}
