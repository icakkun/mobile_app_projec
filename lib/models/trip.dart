class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String homeCurrency;
  final double totalBudget;
  final List<CategoryBudget> categoryBudgets;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.homeCurrency,
    required this.totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) : categoryBudgets = categoryBudgets ?? [];

  Trip copyWith({
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? homeCurrency,
    double? totalBudget,
    List<CategoryBudget>? categoryBudgets,
  }) {
    return Trip(
      id: id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }
}

class CategoryBudget {
  final String id;
  final String categoryName;
  final double limitAmount;

  CategoryBudget({
    required this.id,
    required this.categoryName,
    required this.limitAmount,
  });

  CategoryBudget copyWith({
    String? categoryName,
    double? limitAmount,
  }) {
    return CategoryBudget(
      id: id,
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}
