enum LedgerEntryKind { expense, purchase, sale }

enum LedgerPaymentStatus { notApplicable, paid, partial, unpaid }

class LedgerEntry {
  final String id;
  final LedgerEntryKind kind;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final double settledAmount;
  final LedgerPaymentStatus paymentStatus;
  final bool isDebit;
  final bool isCashMode;

  /// True when this row is a Debit the user tagged as a business expense.
  final bool isBusinessExpense;

  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.settledAmount,
    required this.paymentStatus,
    required this.isDebit,
    required this.isCashMode,
    this.isBusinessExpense = false,
  });
}
