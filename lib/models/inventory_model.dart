
class InventoryModel {
  // Basic Information
  String invoiceNumber = '';
  DateTime invoiceDate = DateTime.now();
  double carat = 0.0;
  double pricePerCarat = 0.0;
  
  // CGST & SGST for add stock
  double cgstRate = 0.75;
  double sgstRate = 0.75;

  // Calculated fields
  double get totalPrice => carat * pricePerCarat;
  double get cgstAmount => totalPrice * (cgstRate / 100);
  double get sgstAmount => totalPrice * (sgstRate / 100);
  double get totalWithGst => totalPrice + cgstAmount + sgstAmount;

  // Additional fields
  String? description;
  DateTime addedDate = DateTime.now();
  DateTime? lastUpdatedDate;
  
  // Unique ID for storage
  String id = DateTime.now().millisecondsSinceEpoch.toString();

  InventoryModel();

  InventoryModel.fromJson(Map<String, dynamic> json)
      : invoiceNumber = json['invoiceNumber'] ?? json['diamondName'] ?? '',
        invoiceDate = json['invoiceDate'] != null
            ? DateTime.parse(json['invoiceDate'])
            : (json['addedDate'] != null
                ? DateTime.parse(json['addedDate'])
                : DateTime.now()),
        carat = (json['carat'] ?? 0.0).toDouble(),
        pricePerCarat = (json['pricePerCarat'] ?? 0.0).toDouble(),
        description = json['description'],
        addedDate = json['addedDate'] != null
            ? DateTime.parse(json['addedDate'])
            : DateTime.now(),
        lastUpdatedDate = json['lastUpdatedDate'] != null
            ? DateTime.parse(json['lastUpdatedDate'])
            : null,
        cgstRate = (json['cgstRate'] ?? 0.75).toDouble(),
        sgstRate = (json['sgstRate'] ?? 0.75).toDouble(),
        id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String(),
        'carat': carat,
        'pricePerCarat': pricePerCarat,
        'totalPrice': totalPrice,
        'cgstRate': cgstRate,
        'sgstRate': sgstRate,
        'description': description,
        'addedDate': addedDate.toIso8601String(),
        'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
      };

  InventoryModel copyWith({
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? carat,
    double? pricePerCarat,
    double? cgstRate,
    double? sgstRate,
    String? description,
    DateTime? addedDate,
    DateTime? lastUpdatedDate,
    String? id,
  }) {
    final model = InventoryModel()
      ..invoiceNumber = invoiceNumber ?? this.invoiceNumber
      ..invoiceDate = invoiceDate ?? this.invoiceDate
      ..carat = carat ?? this.carat
      ..pricePerCarat = pricePerCarat ?? this.pricePerCarat
      ..cgstRate = cgstRate ?? this.cgstRate
      ..sgstRate = sgstRate ?? this.sgstRate
      ..description = description ?? this.description
      ..addedDate = addedDate ?? this.addedDate
      ..lastUpdatedDate = lastUpdatedDate ?? this.lastUpdatedDate
      ..id = id ?? this.id;
    return model;
  }
}

