class ExpenseModel {
  String id = DateTime.now().millisecondsSinceEpoch.toString();
  String type = '';
  double amount = 0.0;
  DateTime expenseDate = DateTime.now();
  DateTime createdAt = DateTime.now();

  ExpenseModel();

  ExpenseModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type = json['type'] ?? '',
        amount = (json['amount'] ?? 0.0).toDouble(),
        expenseDate = _parseDate(json['expenseDate']),
        createdAt = _parseDate(json['createdAt']);

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      if (raw is DateTime) return raw;
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is String && raw.isNotEmpty) return DateTime.parse(raw);
    } catch (_) {}
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'expenseDate': expenseDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
