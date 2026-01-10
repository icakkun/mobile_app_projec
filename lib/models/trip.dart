import 'package:cloud_firestore/cloud_firestore.dart';

// CategoryBudget class
class CategoryBudget {
  final String categoryName;
  final double limitAmount;

  CategoryBudget({
    required this.categoryName,
    required this.limitAmount,
  });

  // ✅ fromFirestore factory method
  factory CategoryBudget.fromFirestore(Map<String, dynamic> data) {
    return CategoryBudget(
      categoryName: data['categoryName'] ?? '',
      limitAmount: (data['limitAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryName': categoryName,
      'limitAmount': limitAmount,
    };
  }

  CategoryBudget copyWith({
    String? categoryName,
    double? limitAmount,
  }) {
    return CategoryBudget(
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}

// Trip class
class Trip {
  final String id;
  final String userId;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String homeCurrency;
  final double totalBudget;
  final DateTime createdAt;
  final List<CategoryBudget> categoryBudgets;

  Trip({
    required this.id,
    required this.userId,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.homeCurrency,
    required this.totalBudget,
    required this.createdAt,
    this.categoryBudgets = const [],
  });

  // Create from Firestore
  factory Trip.fromFirestore(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      destination: data['destination'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      homeCurrency: data['homeCurrency'] ?? 'MYR',
      totalBudget: (data['totalBudget'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryBudgets: [], // Loaded separately
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'homeCurrency': homeCurrency,
      'totalBudget': totalBudget,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  Trip copyWith({
    String? id,
    String? userId,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? homeCurrency,
    double? totalBudget,
    DateTime? createdAt,
    List<CategoryBudget>? categoryBudgets,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      totalBudget: totalBudget ?? this.totalBudget,
      createdAt: createdAt ?? this.createdAt,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }
}
