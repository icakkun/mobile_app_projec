class Expense {
  final String id;
  final String tripId;
  final double amount;
  final String currency;
  final String categoryName;
  final String paidBy;
  final DateTime expenseDate;
  final String note;

  Expense({
    required this.id,
    required this.tripId,
    required this.amount,
    required this.currency,
    required this.categoryName,
    required this.paidBy,
    required this.expenseDate,
    this.note = '',
  });

  Expense copyWith({
    double? amount,
    String? currency,
    String? categoryName,
    String? paidBy,
    DateTime? expenseDate,
    String? note,
  }) {
    return Expense(
      id: id,
      tripId: tripId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryName: categoryName ?? this.categoryName,
      paidBy: paidBy ?? this.paidBy,
      expenseDate: expenseDate ?? this.expenseDate,
      note: note ?? this.note,
    );
  }
}
