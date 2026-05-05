class ExpenseModel {
  String id = DateTime.now().millisecondsSinceEpoch.toString();
  String personName = '';
  double amount = 0.0;
  bool isCredit = false;
  DateTime expenseDate = DateTime.now();
  DateTime createdAt = DateTime.now();

  ExpenseModel();

  ExpenseModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        personName = (json['personName'] as String?)?.trim().isNotEmpty == true
            ? json['personName'] as String
            : (json['type'] as String? ?? ''),
        amount = (json['amount'] ?? 0.0).toDouble(),
        isCredit = json['isCredit'] == true,
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
        'personName': personName,
        // Mirror to legacy `type` key so older builds still read this record.
        'type': personName,
        'amount': amount,
        'isCredit': isCredit,
        'expenseDate': expenseDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
