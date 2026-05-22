import 'package:flutter/foundation.dart';
import '../models/inventory_model.dart';
import '../services/inventory_storage_service.dart';
import '../services/invoice_storage_service.dart';

class InventoryViewModel extends ChangeNotifier {
  List<InventoryModel> _items = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  double _consumedCarat = 0.0;
  double _consumedAmount = 0.0;

  List<InventoryModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Statistics
  int get totalItems => _items.length;
  
  double get totalCarat {
    return _items.fold(0.0, (sum, item) => sum + item.carat);
  }

  double get totalValue {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Remaining total carat after deducting all invoiced carat.
  double get remainingTotalCarat => (totalCarat - _consumedCarat).clamp(0.0, double.infinity);

  /// Remaining total amount after deducting all invoiced amount.
  double get remainingTotalAmount => (totalValue - _consumedAmount).clamp(0.0, double.infinity);

  double get averagePricePerCarat {
    if (_items.isEmpty) return 0.0;
    final totalPrice = _items.fold(0.0, (sum, item) => sum + item.pricePerCarat);
    return totalPrice / _items.length;
  }

  double get thisMonthValue {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _items
        .where((item) => item.addedDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get thisMonthItems {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _items
        .where((item) => item.addedDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))))
        .length;
  }

  List<InventoryModel> get recentItems {
    final sorted = List<InventoryModel>.from(_items);
    sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return sorted.take(10).toList();
  }

  Future<void> _loadConsumedFromInvoices() async {
    try {
      final invoices = await InvoiceStorageService.getAllInvoices();
      _consumedCarat = 0.0;
      _consumedAmount = 0.0;
      for (final inv in invoices) {
        for (final item in inv.items) {
          _consumedCarat += item.carat;
          _consumedAmount += item.carat * item.rate;
        }
      }
    } catch (_) {
      _consumedCarat = 0.0;
      _consumedAmount = 0.0;
    }
  }

  Future<void> loadItems() async {
    // Only show the full skeleton shimmer on the very first load.
    // Subsequent refreshes (e.g. after returning from a form view or
    // pull-to-refresh) update data silently so the shimmer doesn't flash.
    if (!_hasLoadedOnce) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      _items = await InventoryStorageService.getAllInventoryItems();
      await _loadConsumedFromInvoices();
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasLoadedOnce = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> saveItem(InventoryModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await InventoryStorageService.saveInventoryItem(item);
      await loadItems(); // Reload to get updated list
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await InventoryStorageService.deleteInventoryItem(id);
      await loadItems(); // Reload to get updated list
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<InventoryModel?> getItemById(String id) async {
    try {
      return await InventoryStorageService.getInventoryItemById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}

