import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/inventory_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/inventory_storage_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../services/invoice_number_service.dart';
import '../services/settings_service.dart';

class InvoiceFormViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  InvoiceModel _invoice;
  InvoiceModel? _originalInvoice; // Store original invoice when editing to restore inventory
  bool _isLoadingProfile = false;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  String? _errorMessage;
  List<InventoryModel> _inventoryItems = [];
  bool _isLoadingInventory = false;

  List<InventoryModel> get inventoryItems => _inventoryItems;
  bool get isLoadingInventory => _isLoadingInventory;

  InvoiceFormViewModel({InvoiceModel? invoice}) : _invoice = invoice ?? InvoiceModel() {
    if (_invoice.items.isEmpty) {
      _invoice.items.add(InvoiceItem());
    }
    
    // Store original invoice if editing (deep copy to track original state)
    if (invoice != null && invoice.id.isNotEmpty) {
      _originalInvoice = _deepCopyInvoice(invoice);
    }
    
    _loadInventoryItems();
    if (invoice == null) {
      _loadUserProfile();
      _loadAutoInvoiceNumber();
      _loadSettings();
    }
  }
  
  // Deep copy invoice for tracking original state
  InvoiceModel _deepCopyInvoice(InvoiceModel invoice) {
    final copy = InvoiceModel.fromJson(invoice.toJson());
    return copy;
  }

  Future<void> _loadInventoryItems() async {
    _isLoadingInventory = true;
    notifyListeners();
    try {
      _inventoryItems = await InventoryStorageService.getAllInventoryItems();
      _isLoadingInventory = false;
      notifyListeners();
    } catch (e) {
      _isLoadingInventory = false;
      notifyListeners();
    }
  }

  Future<void> _loadAutoInvoiceNumber() async {
    if (_invoice.invoiceNo.isEmpty) {
      final settings = await SettingsService.getSettings();
      final nextNumber = await InvoiceNumberService.getNextInvoiceNumber();
      
      // Use starting number from settings if it's higher than current
      final startNumber = settings.startingInvoiceNumber;
      final currentNumber = await InvoiceNumberService.getCurrentInvoiceNumber();
      final actualNextNumber = startNumber > currentNumber ? startNumber : nextNumber;
      
      // Format invoice number with prefix if set
      String invoiceNo;
      if (settings.invoiceNumberPrefix.isNotEmpty) {
        invoiceNo = '${settings.invoiceNumberPrefix}$actualNextNumber';
      } else {
        invoiceNo = actualNextNumber.toString();
      }
      
      _invoice.invoiceNo = invoiceNo;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.getSettings();
      _invoice.cgstRate = settings.cgstRate;
      _invoice.sgstRate = settings.sgstRate;
      _invoice.igstRate = settings.igstRate;
      if (settings.defaultTerms.isNotEmpty && _invoice.terms.isEmpty) {
        _invoice.terms = settings.defaultTerms;
      }
      notifyListeners();
    } catch (_) {
      // If settings loading fails, use default values
    }
  }

  InvoiceModel get invoice => _invoice;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isSaving => _isSaving;
  bool get isGeneratingPdf => _isGeneratingPdf;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _invoice.id.isNotEmpty;

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      _isLoadingProfile = false;
      notifyListeners();
      return;
    }

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _userService.getUserProfile(user.uid);
      if (profile != null) {
        _invoice.sellerName = profile.companyName;
        _invoice.sellerAddress = profile.companyAddress;
        _invoice.sellerMobile = profile.mobileNumber;
        _invoice.sellerEmail = profile.email;
        _invoice.sellerGstNo = profile.gstNo;
        _invoice.sellerPanNo = profile.panNo;
        _invoice.sellerCstNo = profile.cstNo ?? '';
        _invoice.sellerVatNo = profile.vatNo ?? '';
        _invoice.sellerIecNo = profile.iecNo ?? '';
        _invoice.bankName = profile.bankName;
        _invoice.branch = profile.branch;
        _invoice.accountNo = profile.accountNo;
        _invoice.ifscCode = profile.ifscCode;
      }
      _isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      _isLoadingProfile = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void updateBuyerName(String value) {
    _invoice.buyerName = value;
    notifyListeners();
  }

  void updateBuyerAddress(String value) {
    _invoice.buyerAddress = value;
    notifyListeners();
  }

  void updateBuyerContactPerson(String value) {
    _invoice.buyerContactPerson = value;
    notifyListeners();
  }

  void updateBuyerContactNo(String value) {
    _invoice.buyerContactNo = value;
    notifyListeners();
  }

  void updateBuyerEmail(String value) {
    _invoice.buyerEmail = value;
    notifyListeners();
  }

  void updateBuyerGstNo(String value) {
    _invoice.buyerGstNo = value;
    notifyListeners();
  }

  void updateBuyerPanNo(String value) {
    _invoice.buyerPanNo = value;
    notifyListeners();
  }

  void updateBuyerVatNo(String value) {
    _invoice.buyerVatNo = value;
    notifyListeners();
  }

  void updateBuyerCstNo(String value) {
    _invoice.buyerCstNo = value;
    notifyListeners();
  }

  void updateBuyerStateName(String value) {
    _invoice.buyerStateName = value;
    notifyListeners();
  }

  void updateBuyerStateCode(String value) {
    _invoice.buyerStateCode = value;
    notifyListeners();
  }

  void updatePlaceOfSupply(String value) {
    _invoice.placeOfSupply = value;
    notifyListeners();
  }

  void updateInvoiceNo(String value) {
    _invoice.invoiceNo = value;
    notifyListeners();
  }

  void updateInvoiceDate(DateTime value) {
    _invoice.invoiceDate = value;
    notifyListeners();
  }

  void updateTerms(String value) {
    _invoice.terms = value;
    notifyListeners();
  }

  void updateDueDate(DateTime value) {
    _invoice.dueDate = value;
    notifyListeners();
  }

  void addItem() {
    _invoice.items.add(InvoiceItem());
    notifyListeners();
  }

  void removeItem(int index) {
    if (_invoice.items.length > 1) {
      _invoice.items.removeAt(index);
      notifyListeners();
    }
  }

  // Get available inventory items for a specific item index (excluding already selected ones)
  List<InventoryModel> getAvailableInventoryItems(int itemIndex) {
    final selectedIds = _invoice.items
        .asMap()
        .entries
        .where((entry) => entry.key != itemIndex && entry.value.inventoryItemId != null)
        .map((entry) => entry.value.inventoryItemId!)
        .toSet();
    
    return _inventoryItems.where((item) => !selectedIds.contains(item.id)).toList();
  }

  // Get the selected inventory item for an invoice item
  InventoryModel? getSelectedInventoryItem(int itemIndex) {
    if (itemIndex >= _invoice.items.length) return null;
    final inventoryId = _invoice.items[itemIndex].inventoryItemId;
    if (inventoryId == null) return null;
    try {
      return _inventoryItems.firstWhere((item) => item.id == inventoryId);
    } catch (_) {
      return null;
    }
  }

  // Get max carat available for an invoice item
  double getMaxCaratForItem(int itemIndex) {
    final inventoryItem = getSelectedInventoryItem(itemIndex);
    if (inventoryItem == null) return 0.0;
    
    // Calculate remaining carat (total carat minus already used in other items)
    // Exclude the current item's carat from the calculation
    double usedCarat = 0.0;
    for (int i = 0; i < _invoice.items.length; i++) {
      if (i != itemIndex && _invoice.items[i].inventoryItemId == inventoryItem.id) {
        usedCarat += _invoice.items[i].carat;
      }
    }
    
    // Max available is total carat minus what's used in other items
    // The current item can use up to the remaining amount
    return (inventoryItem.carat - usedCarat).clamp(0.0, inventoryItem.carat);
  }

  // Select inventory item for an invoice item
  void selectInventoryItem(int itemIndex, String? inventoryItemId) {
    if (itemIndex >= _invoice.items.length) return;
    
    final item = _invoice.items[itemIndex];
    
    // If deselecting (null), clear the item
    if (inventoryItemId == null) {
      item.inventoryItemId = null;
      item.particular = 'CUT AND POLISHED LAB GROWN DIAMOND SALE';
      item.carat = 0.0;
      item.rate = 0.0;
      notifyListeners();
      return;
    }
    
    // Find the inventory item
    try {
      final inventoryItem = _inventoryItems.firstWhere((inv) => inv.id == inventoryItemId);
      
      // Set the inventory item
      item.inventoryItemId = inventoryItemId;
      item.particular = inventoryItem.diamondName;
      item.rate = inventoryItem.pricePerCarat;
      
      // Set carat to max available if current carat exceeds max
      final maxCarat = getMaxCaratForItem(itemIndex);
      if (item.carat > maxCarat) {
        item.carat = maxCarat;
      }
      
      notifyListeners();
    } catch (_) {
      // Inventory item not found
    }
  }

  void updateItemParticular(int index, String value) {
    // This method is kept for backward compatibility but shouldn't be used
    // Use selectInventoryItem instead
    if (index < _invoice.items.length) {
      _invoice.items[index].particular = value;
      notifyListeners();
    }
  }

  void updateItemHsnCode(int index, String value) {
    if (index < _invoice.items.length) {
      _invoice.items[index].hsnCode = value;
      notifyListeners();
    }
  }

  void updateItemCarat(int index, String value) {
    if (index >= _invoice.items.length) return;
    
    final item = _invoice.items[index];
    final inventoryItem = getSelectedInventoryItem(index);
    
    // If no inventory selected, don't allow carat entry
    if (inventoryItem == null) {
      item.carat = 0.0;
      return;
    }
    
    // Parse the carat value - this is called from onChanged, so we update directly
    // without notifying listeners to prevent keyboard dismissal
    if (value.isEmpty || value.trim().isEmpty) {
      item.carat = 0.0;
      return;
    }
    
    final carat = double.tryParse(value) ?? 0.0;
    final maxCarat = getMaxCaratForItem(index);
    
    // Clamp carat to max available (0 to maxCarat)
    item.carat = carat.clamp(0.0, maxCarat);
    
    // Don't call notifyListeners here - it causes keyboard to dismiss
    // The UI will update when finalizeItemCarat is called or when other actions trigger rebuild
  }
  
  // Method to force update after user finishes editing (e.g., on focus loss)
  void finalizeItemCarat(int index) {
    if (index >= _invoice.items.length) return;
    notifyListeners(); // Update UI to reflect final value and recalculate amount
  }

  void updateItemRate(int index, String value) {
    // Rate is now read-only (comes from inventory), but keep method for compatibility
    // Do nothing - rate is automatically set from inventory
  }

  // Update inventory based on invoice items
  Future<void> _updateInventoryFromInvoice() async {
    try {
      // Reload inventory to get latest data
      await _loadInventoryItems();

      // If editing, restore original inventory first
      if (isEditing && _originalInvoice != null) {
        await _restoreInventoryFromInvoice(_originalInvoice!);
      }

      // Update inventory for current invoice items
      for (var invoiceItem in _invoice.items) {
        if (invoiceItem.inventoryItemId != null && invoiceItem.carat > 0) {
          // Find the inventory item
          final inventoryItem = _inventoryItems.firstWhere(
            (inv) => inv.id == invoiceItem.inventoryItemId,
            orElse: () => InventoryModel(),
          );

          if (inventoryItem.id.isNotEmpty) {
            // Deduct carat from inventory
            final newCarat = inventoryItem.carat - invoiceItem.carat;
            if (newCarat < 0) {
              // This shouldn't happen if validation is working, but add safeguard
              print('Warning: Inventory carat would go negative. Current: ${inventoryItem.carat}, Deducting: ${invoiceItem.carat}');
              inventoryItem.carat = 0.0;
            } else {
              inventoryItem.carat = newCarat;
            }
            inventoryItem.lastUpdatedDate = DateTime.now();

            // Save updated inventory item
            await InventoryStorageService.saveInventoryItem(inventoryItem);
          }
        }
      }

      // Reload inventory to reflect changes
      await _loadInventoryItems();
    } catch (e) {
      // Log error but don't fail invoice generation
      print('Error updating inventory: $e');
    }
  }

  // Restore inventory from invoice items (used when editing or deleting)
  Future<void> _restoreInventoryFromInvoice(InvoiceModel invoice) async {
    try {
      // Reload inventory to get latest data
      await _loadInventoryItems();
      
      for (var invoiceItem in invoice.items) {
        if (invoiceItem.inventoryItemId != null && invoiceItem.carat > 0) {
          // Find the inventory item in loaded list first
          try {
            final inventoryItem = _inventoryItems.firstWhere(
              (inv) => inv.id == invoiceItem.inventoryItemId,
            );
            
            // Restore carat to inventory
            inventoryItem.carat = inventoryItem.carat + invoiceItem.carat;
            inventoryItem.lastUpdatedDate = DateTime.now();

            // Save updated inventory item
            await InventoryStorageService.saveInventoryItem(inventoryItem);
          } catch (_) {
            // Inventory item not found in current list, try to fetch from storage
            final inventoryItem = await InventoryStorageService.getInventoryItemById(invoiceItem.inventoryItemId!);
            if (inventoryItem != null) {
              inventoryItem.carat = inventoryItem.carat + invoiceItem.carat;
              inventoryItem.lastUpdatedDate = DateTime.now();
              await InventoryStorageService.saveInventoryItem(inventoryItem);
            }
          }
        }
      }
      
      // Reload inventory to reflect changes
      await _loadInventoryItems();
    } catch (e) {
      // Log error but don't fail operation
      print('Error restoring inventory: $e');
    }
  }

  Future<bool> generateAndSaveInvoice() async {
    _isGeneratingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure invoice has an ID
      if (_invoice.id.isEmpty) {
        _invoice.id = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Save invoice number if it's a new invoice
      if (!isEditing && _invoice.invoiceNo.isNotEmpty) {
        final invoiceNumber = int.tryParse(_invoice.invoiceNo);
        if (invoiceNumber != null) {
          await InvoiceNumberService.saveInvoiceNumber(invoiceNumber);
        }
      }

      // Save invoice
      _isSaving = true;
      notifyListeners();
      await InvoiceStorageService.saveInvoice(_invoice);
      
      // Update inventory based on invoice items
      await _updateInventoryFromInvoice();
      
      _isSaving = false;

      // Generate PDF
      await PdfService.generateInvoice(_invoice);
      _isGeneratingPdf = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isGeneratingPdf = false;
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Method to restore inventory when invoice is deleted (to be called from invoice list viewmodel)
  static Future<void> restoreInventoryOnDelete(String invoiceId) async {
    try {
      final invoice = await InvoiceStorageService.getInvoiceById(invoiceId);
      if (invoice == null) return;

      // Restore inventory for each invoice item
      for (var invoiceItem in invoice.items) {
        if (invoiceItem.inventoryItemId != null && invoiceItem.carat > 0) {
          final inventoryItem = await InventoryStorageService.getInventoryItemById(invoiceItem.inventoryItemId!);
          
          if (inventoryItem != null) {
            // Restore carat to inventory
            inventoryItem.carat = inventoryItem.carat + invoiceItem.carat;
            inventoryItem.lastUpdatedDate = DateTime.now();
            await InventoryStorageService.saveInventoryItem(inventoryItem);
          }
        }
      }
    } catch (e) {
      print('Error restoring inventory on delete: $e');
    }
  }
}

