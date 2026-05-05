class StockValuationItem {
  String id;
  String itemName;
  double carats;
  double ratePerCarat;
  double discountPercent;
  double brokeragePercent;

  StockValuationItem({
    String? id,
    this.itemName = '',
    this.carats = 0.0,
    this.ratePerCarat = 0.0,
    this.discountPercent = 0.0,
    this.brokeragePercent = 0.0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  double get effectiveRatePerCarat {
    final afterDiscount = ratePerCarat * (1 - (discountPercent / 100));
    final afterBrokerage = afterDiscount * (1 - (brokeragePercent / 100));
    return afterBrokerage < 0 ? 0 : afterBrokerage;
  }

  double get totalValue => carats * effectiveRatePerCarat;

  StockValuationItem.fromJson(Map<String, dynamic> json)
      : id = (json['id'] ??
                DateTime.now().microsecondsSinceEpoch.toString())
            .toString(),
        itemName = json['itemName'] ?? '',
        carats = (json['carats'] ?? 0.0).toDouble(),
        ratePerCarat = (json['ratePerCarat'] ?? 0.0).toDouble(),
        discountPercent = (json['discountPercent'] ?? 0.0).toDouble(),
        brokeragePercent = (json['brokeragePercent'] ?? 0.0).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'carats': carats,
        'ratePerCarat': ratePerCarat,
        'discountPercent': discountPercent,
        'brokeragePercent': brokeragePercent,
      };

  StockValuationItem copyWith({
    String? itemName,
    double? carats,
    double? ratePerCarat,
    double? discountPercent,
    double? brokeragePercent,
  }) {
    return StockValuationItem(
      id: id,
      itemName: itemName ?? this.itemName,
      carats: carats ?? this.carats,
      ratePerCarat: ratePerCarat ?? this.ratePerCarat,
      discountPercent: discountPercent ?? this.discountPercent,
      brokeragePercent: brokeragePercent ?? this.brokeragePercent,
    );
  }
}
