class InvoiceReminder {
  final String invoiceId;
  final String invoiceNo;
  final String buyerName;
  final DateTime dueDate;
  final DateTime reminderDate;
  final bool isActive;
  final int notificationId;

  InvoiceReminder({
    required this.invoiceId,
    required this.invoiceNo,
    required this.buyerName,
    required this.dueDate,
    required this.reminderDate,
    this.isActive = true,
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'invoiceNo': invoiceNo,
        'buyerName': buyerName,
        'dueDate': dueDate.toIso8601String(),
        'reminderDate': reminderDate.toIso8601String(),
        'isActive': isActive,
        'notificationId': notificationId,
      };

  factory InvoiceReminder.fromJson(Map<String, dynamic> json) => InvoiceReminder(
        invoiceId: json['invoiceId'] as String,
        invoiceNo: json['invoiceNo'] as String,
        buyerName: json['buyerName'] as String,
        dueDate: DateTime.parse(json['dueDate'] as String),
        reminderDate: DateTime.parse(json['reminderDate'] as String),
        isActive: json['isActive'] as bool? ?? true,
        notificationId: json['notificationId'] as int,
      );

  InvoiceReminder copyWith({
    String? invoiceId,
    String? invoiceNo,
    String? buyerName,
    DateTime? dueDate,
    DateTime? reminderDate,
    bool? isActive,
    int? notificationId,
  }) {
    return InvoiceReminder(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      buyerName: buyerName ?? this.buyerName,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      isActive: isActive ?? this.isActive,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

