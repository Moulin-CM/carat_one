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

  final InvoiceModel _invoice;
  InvoiceModel? _originalInvoice; // Store original invoice when editing to restore inventory
  bool _isLoadingProfile = false;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  String? _errorMessage;
  List<InventoryModel> _inventoryItems = [];
  bool _isLoadingInventory = false;
  double _consumedCarat = 0.0;
  double _consumedAmount = 0.0;

  List<InventoryModel> get inventoryItems => _inventoryItems;
  bool get isLoadingInventory => _isLoadingInventory;

  double get _inventoryTotalCarat => _inventoryItems.fold(0.0, (sum, i) => sum + i.carat);
  double get _inventoryTotalAmount => _inventoryItems.fold(0.0, (sum, i) => sum + i.totalPrice);

  /// Remaining total carat (inventory total minus all invoiced carat; when editing, current invoice is excluded).
  double get remainingTotalCarat => (_inventoryTotalCarat - _consumedCarat).clamp(0.0, double.infinity);

  /// Remaining total amount (inventory total minus all invoiced amount; when editing, current invoice is excluded).
  double get remainingTotalAmount => (_inventoryTotalAmount - _consumedAmount).clamp(0.0, double.infinity);

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
      await _loadConsumedFromInvoices();
      _isLoadingInventory = false;
      notifyListeners();
    } catch (e) {
      _isLoadingInventory = false;
      notifyListeners();
    }
  }

  Future<void> _loadConsumedFromInvoices() async {
    try {
      final invoices = await InvoiceStorageService.getAllInvoices();
      _consumedCarat = 0.0;
      _consumedAmount = 0.0;
      for (final inv in invoices) {
        if (isEditing && inv.id == _invoice.id) continue;
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
        _recalculateDueDateFromTerms();
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
  // An invoice is considered "editing" only when it was opened
  // with an existing invoice (i.e. _originalInvoice is set).
  // New invoices created from scratch should not be treated as editing,
  // even though they get an auto-generated ID.
  bool get isEditing => _originalInvoice != null;

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

  /// Parse number of days from terms string (e.g. "30 days", "15", "Payment within 45 days").
  static int? _parseDaysFromTerms(String terms) {
    if (terms.trim().isEmpty) return null;
    final match = RegExp(r'\d+').firstMatch(terms.trim());
    if (match == null) return null;
    final days = int.tryParse(match.group(0)!);
    return days != null && days >= 0 ? days : null;
  }

  void _recalculateDueDateFromTerms() {
    final days = _parseDaysFromTerms(_invoice.terms);
    if (days != null) {
      _invoice.dueDate = _invoice.invoiceDate.add(Duration(days: days));
    }
  }

  void updateInvoiceDate(DateTime value) {
    _invoice.invoiceDate = value;
    _recalculateDueDateFromTerms();
    notifyListeners();
  }

  void updateTerms(String value) {
    _invoice.terms = value;
    _recalculateDueDateFromTerms();
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

  /// Max carat allowed per item = remaining total carat (total validated on save).
  double getMaxCaratForItem(int itemIndex) => remainingTotalCarat;

  void updateItemHsnCode(int index, String value) {
    if (index < _invoice.items.length) {
      _invoice.items[index].hsnCode = value;
      notifyListeners();
    }
  }

  void updateItemCarat(int index, String value) {
    if (index >= _invoice.items.length) return;
    final item = _invoice.items[index];
    if (value.isEmpty || value.trim().isEmpty) {
      item.carat = 0.0;
      return;
    }
    final carat = double.tryParse(value) ?? 0.0;
    final maxCarat = getMaxCaratForItem(index);
    item.carat = carat.clamp(0.0, maxCarat);
  }

  void finalizeItemCarat(int index) {
    if (index >= _invoice.items.length) return;
    notifyListeners();
  }

  void updateItemRate(int index, String value) {
    if (index >= _invoice.items.length) return;
    final rate = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    _invoice.items[index].rate = rate.clamp(0.0, double.infinity);
    notifyListeners();
  }

  double get totalInvoiceCarat => _invoice.items.fold(0.0, (sum, i) => sum + i.carat);

  Future<bool> generateAndSaveInvoice() async {
    _isGeneratingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (totalInvoiceCarat > remainingTotalCarat) {
        _isGeneratingPdf = false;
        _errorMessage = 'Total carat (${totalInvoiceCarat.toStringAsFixed(2)}) cannot exceed remaining inventory carat (${remainingTotalCarat.toStringAsFixed(2)}).';
        notifyListeners();
        return false;
      }
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
  
  /// No-op: remaining carat/amount are computed from all invoices; delete automatically reduces consumed.
  static Future<void> restoreInventoryOnDelete(String invoiceId) async {}
}

