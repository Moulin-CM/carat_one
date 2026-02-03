import 'package:flutter/foundation.dart';
import '../models/inventory_model.dart';
import '../services/inventory_storage_service.dart';

class InventoryFormViewModel extends ChangeNotifier {
  final InventoryModel _item;
  final bool _isEditing;
  bool _isSaving = false;
  String? _errorMessage;

  InventoryFormViewModel({InventoryModel? item})
      : _item = item ?? InventoryModel(),
        _isEditing = item != null;

  InventoryModel get item => _item;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;

  void updateInvoiceNumber(String value) {
    _item.invoiceNumber = value;
    notifyListeners();
  }

  void updateInvoiceDate(DateTime date) {
    _item.invoiceDate = date;
    notifyListeners();
  }

  void updateCarat(String value) {
    final carat = double.tryParse(value) ?? 0.0;
    _item.carat = carat;
    notifyListeners();
  }

  void updatePricePerCarat(String value) {
    final pricePerCarat = double.tryParse(value) ?? 0.0;
    _item.pricePerCarat = pricePerCarat;
    notifyListeners();
  }

  void updateDescription(String value) {
    _item.description = value;
    notifyListeners();
  }

  double get totalPrice => _item.totalPrice;

  Future<bool> saveItem() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure item has an ID
      if (_item.id.isEmpty) {
        _item.id = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Update lastUpdatedDate if editing
      if (isEditing) {
        _item.lastUpdatedDate = DateTime.now();
      }

      // Save inventory item
      await InventoryStorageService.saveInventoryItem(_item);
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

