import 'dart:convert';

class InventoryModel {
  // Basic Information
  String diamondName = '';
  double carat = 0.0;
  double pricePerCarat = 0.0;
  
  // Calculated fields
  double get totalPrice => carat * pricePerCarat;
  
  // Additional fields
  String? description;
  DateTime addedDate = DateTime.now();
  DateTime? lastUpdatedDate;
  
  // Unique ID for storage
  String id = DateTime.now().millisecondsSinceEpoch.toString();

  InventoryModel();

  InventoryModel.fromJson(Map<String, dynamic> json)
      : diamondName = json['diamondName'] ?? '',
        carat = (json['carat'] ?? 0.0).toDouble(),
        pricePerCarat = (json['pricePerCarat'] ?? 0.0).toDouble(),
        description = json['description'],
        addedDate = json['addedDate'] != null
            ? DateTime.parse(json['addedDate'])
            : DateTime.now(),
        lastUpdatedDate = json['lastUpdatedDate'] != null
            ? DateTime.parse(json['lastUpdatedDate'])
            : null,
        id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'diamondName': diamondName,
        'carat': carat,
        'pricePerCarat': pricePerCarat,
        'totalPrice': totalPrice,
        'description': description,
        'addedDate': addedDate.toIso8601String(),
        'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
      };

  InventoryModel copyWith({
    String? diamondName,
    double? carat,
    double? pricePerCarat,
    String? description,
    DateTime? addedDate,
    DateTime? lastUpdatedDate,
    String? id,
  }) {
    final model = InventoryModel()
      ..diamondName = diamondName ?? this.diamondName
      ..carat = carat ?? this.carat
      ..pricePerCarat = pricePerCarat ?? this.pricePerCarat
      ..description = description ?? this.description
      ..addedDate = addedDate ?? this.addedDate
      ..lastUpdatedDate = lastUpdatedDate ?? this.lastUpdatedDate
      ..id = id ?? this.id;
    return model;
  }
}

