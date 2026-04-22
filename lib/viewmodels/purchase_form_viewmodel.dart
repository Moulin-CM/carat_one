import 'package:flutter/foundation.dart';
import '../models/purchase_model.dart';
import '../services/purchase_storage_service.dart';

class PurchaseFormViewModel extends ChangeNotifier {
  late PurchaseModel _item;
  final PurchaseModel? _original;
  bool _isSaving = false;
  String? _errorMessage;

  PurchaseFormViewModel({PurchaseModel? item})
      : _original = item,
        _item = item != null
            ? PurchaseModel.fromJson(item.toJson())
            : PurchaseModel();

  PurchaseModel get item => _item;
  bool get isEditing => _original != null;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // Gross Amount = Total Carat × Amt per Carat
  double get grossAmount => _item.totalCarat * _item.amountPerCarat;

  // Auto-calc: Total Amount = Gross Amount - Discount
  void _recalcTotalAmount() {
    double gross = grossAmount;
    double discountVal = (gross * _item.discount) / 100;
    _item.totalAmount = gross - discountVal;
  }

  // Auto-calc: Payment Date = Buy Date + Due Days
  void _recalcPaymentDate() {
    if (_item.dueDays > 0) {
      _item.paymentDate = _item.buyDate.add(Duration(days: _item.dueDays));
    }
  }

  double get discountAmount => (grossAmount * _item.discount) / 100;
  double get netAmount => _item.totalAmount; // Since totalAmount now includes discount

  void updateTotalAmount(String v) {
    _item.totalAmount = double.tryParse(v) ?? 0;
    notifyListeners();
  }

  void updateTotalCarat(String v) {
    _item.totalCarat = double.tryParse(v) ?? 0;
    _recalcTotalAmount();
    notifyListeners();
  }

  void updateAmountPerCarat(String v) {
    _item.amountPerCarat = double.tryParse(v) ?? 0;
    _recalcTotalAmount();
    notifyListeners();
  }

  void updateDiscount(String v) {
    _item.discount = double.tryParse(v) ?? 0;
    _recalcTotalAmount();
    notifyListeners();
  }

  void updateDueDays(String v) {
    _item.dueDays = int.tryParse(v) ?? 0;
    _recalcPaymentDate();
    notifyListeners();
  }

  void updateSellerName(String v) {
    _item.sellerName = v;
    notifyListeners();
  }

  void updateBrokerName(String v) {
    _item.brokerName = v;
    notifyListeners();
  }

  void updateBrokerChargeRate(String v) {
    _item.brokerChargeRate =
        double.tryParse(v.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    notifyListeners();
  }

  void updateSize(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) {
      _item.sizeAlpha = '';
      _item.sizeNumeric = 0;
    } else {
      final match = RegExp(r'^([a-zA-Z]*)(\d*)$').firstMatch(trimmed);
      if (match != null) {
        _item.sizeAlpha = (match.group(1) ?? '').toUpperCase();
        _item.sizeNumeric = int.tryParse(match.group(2) ?? '') ?? 0;
      }
    }
    notifyListeners();
  }

  void updateBuyDate(DateTime d) {
    _item.buyDate = d;
    _recalcPaymentDate();
    notifyListeners();
  }

  void updatePaymentDate(DateTime d) {
    _item.paymentDate = d;
    notifyListeners();
  }

  void updateIsForOther(bool value) {
    _item.isForOther = value;
    notifyListeners();
  }

  Future<bool> save() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await PurchaseStorageService.savePurchase(_item);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
