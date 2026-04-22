class PurchaseModel {
  String id = DateTime.now().millisecondsSinceEpoch.toString();

  // 1. totalAmount: Stored final amount after discount.
  // Note: For existing records, this might be Gross. 
  // We prefer using the netAmount getter for UI to ensure consistency.
  double totalAmount = 0.0;

  // 2. Total Carat
  double totalCarat = 0.0;

  // 3. Amount as per Carat (rate per carat)
  double amountPerCarat = 0.0;

  // 4. Discount (%)
  double discount = 0.0;

  // 5. Due Day (number of days for payment)
  int dueDays = 0;

  // 6. Seller Name
  String sellerName = '';

  // 7. Broker Name
  String brokerName = '';

  // 7b. Broker Charge % on this purchase's net amount. Used by the
  // Brokerage Report to attribute earnings to the named broker.
  double brokerChargeRate = 0.0;
  double get brokerChargeAmount => netAmount * (brokerChargeRate / 100);

  // 8. Size (e.g. C3, A5, B12)
  String sizeAlpha = '';
  int sizeNumeric = 0;
  String get size => '$sizeAlpha$sizeNumeric';

  // 9. Buy Date
  DateTime buyDate = DateTime.now();

  // 10. Payment Date
  DateTime paymentDate = DateTime.now();

  // 11. Payment Type: 'cash' or 'bill'
  String paymentType = 'cash'; // 'cash' or 'bill'

  // 12. "For Other" flag. Purchases/invoices with this flag are kept for
  // record-keeping only and are excluded from Opening totals, Remaining
  // stock, Sales Profit, and Net Profit calculations.
  bool isForOther = false;

  // Sold tracking
  double cashSoldCarat = 0.0;
  double billSoldCarat = 0.0;
  double cashSoldAmount = 0.0;
  double billSoldAmount = 0.0;

  // Payment made to seller (in carats) per payment mode
  double cashPaidCarat = 0.0;
  double accountPaidCarat = 0.0;

  double get totalSoldCarat => cashSoldCarat + billSoldCarat;
  double get totalSoldAmount => cashSoldAmount + billSoldAmount;
  double get remainingCarat => (totalCarat - totalSoldCarat).clamp(0.0, double.infinity);

  // Payment helpers
  double get totalPaidCarat => cashPaidCarat + accountPaidCarat;
  double get remainingPaymentCarat =>
      (totalCarat - totalPaidCarat).clamp(0.0, double.infinity);
  double get cashPaidAmount => cashPaidCarat * effectivePurchaseRate;
  double get accountPaidAmount => accountPaidCarat * effectivePurchaseRate;
  bool get isFullyPaid => totalCarat > 0 && remainingPaymentCarat <= 0.0001;

  // Calculated getters
  double get grossAmount => totalCarat * amountPerCarat;
  double get discountValue => (grossAmount * discount) / 100;
  
  // Always calculate netAmount from gross and discount for consistency, 
  // especially for older records where totalAmount might be saved as Gross.
  double get netAmount => grossAmount - discountValue;

  // Profit and Loss calculations
  double get effectivePurchaseRate => totalCarat > 0 ? netAmount / totalCarat : 0.0;
  double get costOfSoldGoods => totalSoldCarat * effectivePurchaseRate;
  double get profitOrLoss => totalSoldAmount - costOfSoldGoods;

  DateTime addedDate = DateTime.now();

  PurchaseModel();

  PurchaseModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        totalAmount = (json['totalAmount'] ?? 0.0).toDouble(),
        totalCarat = (json['totalCarat'] ?? 0.0).toDouble(),
        amountPerCarat = (json['amountPerCarat'] ?? 0.0).toDouble(),
        discount = (json['discount'] ?? 0.0).toDouble(),
        dueDays = (json['dueDays'] ?? 0) is int
            ? json['dueDays']
            : int.tryParse(json['dueDays'].toString()) ?? 0,
        sellerName = json['sellerName'] ?? '',
        brokerName = json['brokerName'] ?? '',
        brokerChargeRate = (json['brokerChargeRate'] ?? 0.0).toDouble(),
        sizeAlpha = json['sizeAlpha'] ?? '',
        sizeNumeric = (json['sizeNumeric'] ?? 0) is int
            ? json['sizeNumeric']
            : int.tryParse(json['sizeNumeric'].toString()) ?? 0,
        buyDate = _parseDate(json['buyDate']),
        paymentDate = _parseDate(json['paymentDate']),
        paymentType = json['paymentType'] ?? 'cash',
        cashSoldCarat = (json['cashSoldCarat'] ?? 0.0).toDouble(),
        billSoldCarat = (json['billSoldCarat'] ?? 0.0).toDouble(),
        cashSoldAmount = (json['cashSoldAmount'] ?? 0.0).toDouble(),
        billSoldAmount = (json['billSoldAmount'] ?? 0.0).toDouble(),
        // Legacy migration: records saved before the payment-tracking fields
        // existed carry no cashPaidCarat/accountPaidCarat keys. For those,
        // seed the new payment fields from the old sold-tracking fields
        // (cash sold → cash paid, bill sold → account paid). New records
        // that already include the keys are loaded as-is.
        cashPaidCarat = json.containsKey('cashPaidCarat')
            ? (json['cashPaidCarat'] ?? 0.0).toDouble()
            : (json['cashSoldCarat'] ?? 0.0).toDouble(),
        accountPaidCarat = json.containsKey('accountPaidCarat')
            ? (json['accountPaidCarat'] ?? 0.0).toDouble()
            : (json['billSoldCarat'] ?? 0.0).toDouble(),
        isForOther = json['isForOther'] ?? false,
        addedDate = _parseDate(json['addedDate']);

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
        'totalAmount': totalAmount,
        'totalCarat': totalCarat,
        'amountPerCarat': amountPerCarat,
        'discount': discount,
        'dueDays': dueDays,
        'sellerName': sellerName,
        'brokerName': brokerName,
        'brokerChargeRate': brokerChargeRate,
        'sizeAlpha': sizeAlpha,
        'sizeNumeric': sizeNumeric,
        'buyDate': buyDate.toIso8601String(),
        'paymentDate': paymentDate.toIso8601String(),
        'paymentType': paymentType,
        'cashSoldCarat': cashSoldCarat,
        'billSoldCarat': billSoldCarat,
        'cashSoldAmount': cashSoldAmount,
        'billSoldAmount': billSoldAmount,
        'cashPaidCarat': cashPaidCarat,
        'accountPaidCarat': accountPaidCarat,
        'isForOther': isForOther,
        'addedDate': addedDate.toIso8601String(),
      };

  PurchaseModel copyWith({
    String? id,
    double? totalAmount,
    double? totalCarat,
    double? amountPerCarat,
    double? discount,
    int? dueDays,
    String? sellerName,
    String? brokerName,
    double? brokerChargeRate,
    String? sizeAlpha,
    int? sizeNumeric,
    DateTime? buyDate,
    DateTime? paymentDate,
    String? paymentType,
    double? cashSoldCarat,
    double? billSoldCarat,
    double? cashSoldAmount,
    double? billSoldAmount,
    double? cashPaidCarat,
    double? accountPaidCarat,
    bool? isForOther,
  }) {
    final m = PurchaseModel()
      ..id = id ?? this.id
      ..totalAmount = totalAmount ?? this.totalAmount
      ..totalCarat = totalCarat ?? this.totalCarat
      ..amountPerCarat = amountPerCarat ?? this.amountPerCarat
      ..discount = discount ?? this.discount
      ..dueDays = dueDays ?? this.dueDays
      ..sellerName = sellerName ?? this.sellerName
      ..brokerName = brokerName ?? this.brokerName
      ..brokerChargeRate = brokerChargeRate ?? this.brokerChargeRate
      ..sizeAlpha = sizeAlpha ?? this.sizeAlpha
      ..sizeNumeric = sizeNumeric ?? this.sizeNumeric
      ..buyDate = buyDate ?? this.buyDate
      ..paymentDate = paymentDate ?? this.paymentDate
      ..paymentType = paymentType ?? this.paymentType
      ..cashSoldCarat = cashSoldCarat ?? this.cashSoldCarat
      ..billSoldCarat = billSoldCarat ?? this.billSoldCarat
      ..cashSoldAmount = cashSoldAmount ?? this.cashSoldAmount
      ..billSoldAmount = billSoldAmount ?? this.billSoldAmount
      ..cashPaidCarat = cashPaidCarat ?? this.cashPaidCarat
      ..accountPaidCarat = accountPaidCarat ?? this.accountPaidCarat
      ..isForOther = isForOther ?? this.isForOther
      ..addedDate = addedDate;
    return m;
  }
}
