/// A single installment payment recorded against a purchase or an invoice.
///
/// The model is intentionally shared between PurchaseModel and InvoiceModel:
/// both sides record payments the same way (mode, carat, amount, date).
/// The Expense ledger sums these into a single row per purchase/invoice;
/// the per-row bottom sheet enumerates them.
class PaymentInstallment {
  String id;
  DateTime date;
  String mode; // 'cash' | 'account'
  double amount;
  double carat;

  PaymentInstallment({
    String? id,
    DateTime? date,
    required this.mode,
    required this.amount,
    required this.carat,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  PaymentInstallment.fromJson(Map<String, dynamic> json)
      : id = (json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString(),
        date = _parseDate(json['date']),
        mode = (json['mode'] ?? 'cash').toString(),
        amount = (json['amount'] ?? 0.0).toDouble(),
        carat = (json['carat'] ?? 0.0).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mode': mode,
        'amount': amount,
        'carat': carat,
      };

  bool get isCash => mode == 'cash';
  bool get isAccount => mode == 'account';

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      if (raw is DateTime) return raw;
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is String && raw.isNotEmpty) return DateTime.parse(raw);
    } catch (_) {}
    return DateTime.now();
  }
}
