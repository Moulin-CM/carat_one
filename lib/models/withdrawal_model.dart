class WithdrawalModel {
  String id = DateTime.now().millisecondsSinceEpoch.toString();
  String personName = '';
  DateTime takenDate = DateTime.now();
  DateTime returnDate = DateTime.now();
  double amount = 0.0;
  bool isReturned = false;
  DateTime? returnedAt;
  DateTime createdAt = DateTime.now();

  WithdrawalModel();

  WithdrawalModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        personName = json['personName'] ?? '',
        takenDate = _parseDate(json['takenDate']),
        returnDate = _parseDate(json['returnDate']),
        amount = (json['amount'] ?? 0.0).toDouble(),
        isReturned = json['isReturned'] ?? false,
        returnedAt = json['returnedAt'] != null
            ? _parseDate(json['returnedAt'])
            : null,
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
        'takenDate': takenDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'amount': amount,
        'isReturned': isReturned,
        if (returnedAt != null) 'returnedAt': returnedAt!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
