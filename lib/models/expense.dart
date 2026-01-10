// Updated Expense Model with Receipt Image URL

class Expense {
  final String id;
  final String tripId;
  final String userId;
  final double amount;
  final String currency;
  final String categoryName;
  final String paidBy;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String note;
  final String? receiptImageUrl; // ← NEW FIELD

  Expense({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.categoryName,
    required this.paidBy,
    required this.expenseDate,
    required this.createdAt,
    this.note = '',
    this.receiptImageUrl, // ← NEW FIELD
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'categoryName': categoryName,
      'paidBy': paidBy,
      'expenseDate': expenseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'receiptImageUrl': receiptImageUrl, // ← NEW FIELD
    };
  }

  // Create from Firestore
  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'MYR',
      categoryName: data['categoryName'] ?? 'Others',
      paidBy: data['paidBy'] ?? 'Me',
      expenseDate: DateTime.parse(
          data['expenseDate'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      note: data['note'] ?? '',
      receiptImageUrl: data['receiptImageUrl'], // ← NEW FIELD
    );
  }

  // Copy with method
  Expense copyWith({
    String? id,
    String? tripId,
    String? userId,
    double? amount,
    String? currency,
    String? categoryName,
    String? paidBy,
    DateTime? expenseDate,
    DateTime? createdAt,
    String? note,
    String? receiptImageUrl, // ← NEW FIELD
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryName: categoryName ?? this.categoryName,
      paidBy: paidBy ?? this.paidBy,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl, // ← NEW FIELD
    );
  }
}
