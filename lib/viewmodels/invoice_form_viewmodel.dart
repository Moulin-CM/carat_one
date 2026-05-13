import 'package:flutter/foundation.dart';

import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../services/auth_service.dart';
import '../services/invoice_number_service.dart';
import '../services/invoice_storage_service.dart';
import '../services/pdf_service.dart';
import '../services/purchase_storage_service.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';

class InvoiceFormViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final InvoiceModel _invoice;
  InvoiceModel? _originalInvoice;
  bool _isLoadingProfile = false;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  String? _errorMessage;
  bool _isLoadingInventory = false;

  List<InvoiceModel> _allPastInvoices = [];
  List<InvoiceModel> _suggestedBuyers = [];

  List<PurchaseModel> _availablePurchases = [];

  // Constructor parameters for compatibility
  final String? _purchaseId;
  final double? _maxCaratFromPurchase;
  final String? _paymentTypeFromPurchase;

  bool get isLoadingInventory => _isLoadingInventory;

  List<InvoiceModel> get suggestedBuyers => _suggestedBuyers;

  String? get purchaseId => _purchaseId;

  InvoiceFormViewModel({InvoiceModel? invoice, String? purchaseId, double? maxCaratFromPurchase, String? paymentTypeFromPurchase, double? initialCarat, bool isCashSell = false})
    : _invoice = invoice ?? InvoiceModel(),
      _purchaseId = purchaseId,
      _maxCaratFromPurchase = maxCaratFromPurchase,
      _paymentTypeFromPurchase = paymentTypeFromPurchase {
    if (invoice == null) {
      _invoice.isCashSell = isCashSell;
      if (isCashSell) {
        _invoice.cgstRate = 0;
        _invoice.sgstRate = 0;
        _invoice.igstRate = 0;
        _invoice.isIgst = false;
      }
    }

    if (_invoice.items.isEmpty) {
      final item = InvoiceItem();
      if (initialCarat != null) {
        item.carat = initialCarat;
      }
      _invoice.items.add(item);
    } else if (invoice == null && initialCarat != null) {
      _invoice.items[0].carat = initialCarat;
    }

    if (invoice != null && invoice.id.isNotEmpty) {
      _originalInvoice = _deepCopyInvoice(invoice);
    }

    _loadPastInvoices();
    _loadAvailablePurchases();

    if (invoice == null) {
      _loadUserProfile();
      _loadAutoInvoiceNumber();
      _loadSettings();
    }
  }

  bool get isCashSell => _invoice.isCashSell;

  /// Strict remaining carat limit based on GLOBAL balance
  double get remainingTotalCarat {
    double total = _availablePurchases.fold(0.0, (sum, p) => sum + p.remainingCarat);
    if (isEditing && _originalInvoice != null) {
      // Add back the carats of the invoice currently being edited
      total += _originalInvoice!.totalCarat;
    }
    return total;
  }

  InvoiceModel _deepCopyInvoice(InvoiceModel invoice) {
    return InvoiceModel.fromJson(invoice.toJson());
  }

  Future<void> _loadPastInvoices() async {
    _allPastInvoices = await InvoiceStorageService.getAllInvoices();
  }

  Future<void> _loadAvailablePurchases() async {
    _isLoadingInventory = true;
    notifyListeners();
    try {
      _availablePurchases = await PurchaseStorageService.getAllPurchases();
    } finally {
      _isLoadingInventory = false;
      notifyListeners();
    }
  }

  Future<void> _loadAutoInvoiceNumber() async {
    if (_invoice.invoiceNo.isNotEmpty) return;

    final settings = await SettingsService.getSettings();
    final basePrefix = settings.invoiceNumberPrefix;

    int nextNumber;
    String prefix;

    if (_invoice.isCashSell) {
      // Cash sells have their own counter so Entry No is "cash-entries + 1".
      // Self-heal: if the counter is behind the actual number of cash
      // entries on disk (e.g. first install, counter reset, imported data),
      // fall back to actualCashCount + 1.
      final counterNext = await InvoiceNumberService.getNextCashEntryNumber();
      final allInvoices = _allPastInvoices.isNotEmpty ? _allPastInvoices : await InvoiceStorageService.getAllInvoices();
      final actualCashCount = allInvoices.where((inv) => inv.isCashSell).length;
      nextNumber = counterNext > actualCashCount ? counterNext : actualCashCount + 1;
      prefix = basePrefix.isNotEmpty ? '${basePrefix}CASH' : 'CASH';
    } else {
      final counterNext = await InvoiceNumberService.getNextInvoiceNumber();
      final currentNumber = await InvoiceNumberService.getCurrentInvoiceNumber();
      final startNumber = settings.startingInvoiceNumber;
      nextNumber = startNumber > currentNumber ? startNumber : counterNext;
      prefix = basePrefix;
    }

    _invoice.invoiceNo = prefix.isNotEmpty ? '$prefix$nextNumber' : nextNumber.toString();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.getSettings();
      if (!_invoice.isCashSell) {
        _invoice.cgstRate = settings.cgstRate;
        _invoice.sgstRate = settings.sgstRate;
        _invoice.igstRate = settings.igstRate;
      }
      if (settings.defaultTerms.isNotEmpty && _invoice.terms.isEmpty) {
        _invoice.terms = settings.defaultTerms;
        _recalculateDueDateFromTerms();
      }
      notifyListeners();
    } catch (_) {}
  }

  InvoiceModel get invoice => _invoice;

  bool get isLoadingProfile => _isLoadingProfile;

  bool get isSaving => _isSaving;

  bool get isGeneratingPdf => _isGeneratingPdf;

  String? get errorMessage => _errorMessage;

  bool get isEditing => _originalInvoice != null;

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    _isLoadingProfile = true;
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
        _invoice.bankName = profile.bankName;
        _invoice.branch = profile.branch;
        _invoice.accountNo = profile.accountNo;
        _invoice.ifscCode = profile.ifscCode;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  void updateBuyerName(String value) {
    _invoice.buyerName = value;
    if (value.length >= 2) {
      final query = value.toLowerCase();
      final seenNames = <String>{};
      _suggestedBuyers =
          _allPastInvoices.where((inv) {
            final name = inv.buyerName.toLowerCase();
            if (name.contains(query) && !seenNames.contains(name)) {
              seenNames.add(name);
              return true;
            }
            return false;
          }).toList();
    } else {
      _suggestedBuyers = [];
    }
    notifyListeners();
  }

  void selectSuggestedBuyer(InvoiceModel suggested) {
    _invoice.buyerName = suggested.buyerName;
    _invoice.buyerAddress = suggested.buyerAddress;
    _invoice.buyerContactPerson = suggested.buyerContactPerson;
    _invoice.brokerName = suggested.buyerContactPerson;
    _invoice.buyerContactNo = suggested.buyerContactNo;
    _invoice.buyerEmail = suggested.buyerEmail;
    _invoice.buyerGstNo = suggested.buyerGstNo;
    _invoice.buyerPanNo = suggested.buyerPanNo;
    _invoice.buyerStateName = suggested.buyerStateName;
    _invoice.buyerStateCode = suggested.buyerStateCode;
    _invoice.placeOfSupply = suggested.placeOfSupply;
    _invoice.isIgst = suggested.isIgst;
    _suggestedBuyers = [];
    notifyListeners();
  }

  void updateBuyerAddress(String value) {
    _invoice.buyerAddress = value;
    notifyListeners();
  }

  void updateBuyerContactPerson(String value) {
    _invoice.buyerContactPerson = value;
    // Contact Person doubles as the broker for this invoice, so the
    // Brokerage Report (which keys off `brokerName`) attributes charges to
    // the same person without a separate field on the form.
    _invoice.brokerName = value;
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

  void updateIsIgst(bool value) {
    _invoice.isIgst = value;
    notifyListeners();
  }

  void updateBrokerChargeRate(String value) {
    _invoice.brokerChargeRate = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    notifyListeners();
  }

  void updateBrokerName(String value) {
    _invoice.brokerName = value;
    notifyListeners();
  }

  void updateDiscountRate(String value) {
    _invoice.discountRate = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    notifyListeners();
  }

  void _recalculateDueDateFromTerms() {
    final match = RegExp(r'\d+').firstMatch(_invoice.terms);
    if (match != null) {
      final days = int.tryParse(match.group(0)!);
      if (days != null) _invoice.dueDate = _invoice.invoiceDate.add(Duration(days: days));
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

  void updateItemHsnCode(int index, String value) {
    if (index < _invoice.items.length) {
      _invoice.items[index].hsnCode = value;
      notifyListeners();
    }
  }

  void updateItemCarat(int index, String value) {
    if (index >= _invoice.items.length) return;

    final item = _invoice.items[index];
    final carat = double.tryParse(value) ?? 0.0;

    // Temporary web-only bypass.
    // Mobile apps will continue using stock validation.
    if (kIsWeb) {
      item.carat = carat;
      notifyListeners();
      return;
    }

    final limit = remainingTotalCarat;

    double others = 0;
    for (int i = 0; i < _invoice.items.length; i++) {
      if (i != index) {
        others += _invoice.items[i].carat;
      }
    }

    final allowed = (limit - others).clamp(0.0, limit);
    item.carat = carat > (allowed + 0.0001) ? allowed : carat;

    notifyListeners();
  }

  void updateItemRate(int index, String value) {
    if (index < _invoice.items.length) {
      _invoice.items[index].rate = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      notifyListeners();
    }
  }

  double get totalInvoiceCarat => _invoice.totalCarat;

  double get totalInvoiceAmount => _invoice.totalAmount;

  Future<bool> generateAndSaveInvoice() async {
    _isGeneratingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // "For Other" invoices are records-only: no stock check, no
      // distribution against purchases.
      // Temporary web-only bypass.
      // Mobile apps still enforce stock validation.
      if (!kIsWeb && !_invoice.isForOther) {
        final limit = remainingTotalCarat;

        if (totalInvoiceCarat > (limit + 0.01)) {
          throw 'Total carat (${totalInvoiceCarat.toStringAsFixed(2)}) exceeds stock balance (${limit.toStringAsFixed(2)}).';
        }
      }

      _isSaving = true;
      notifyListeners();

      if (!isEditing) {
        final numStr = _invoice.invoiceNo.replaceAll(RegExp(r'\D'), '');
        if (numStr.isNotEmpty) {
          final num = int.tryParse(numStr);
          if (num != null) {
            if (_invoice.isCashSell) {
              await InvoiceNumberService.saveCashEntryNumber(num);
            } else {
              await InvoiceNumberService.saveInvoiceNumber(num);
            }
          }
        }
      }

      await InvoiceStorageService.saveInvoice(_invoice);

      // Cash sell entries always count as cash; bill/account invoices count as bill.
      final isCash = _invoice.isCashSell;

      // Reverse the previous allocation only if the original wasn't a
      // "For Other" record (which never distributed in the first place).
      if (isEditing && _originalInvoice != null && !_originalInvoice!.isForOther) {
        final origIsCash = _originalInvoice!.isCashSell;
        await PurchaseStorageService.distributeSale(totalCarat: -_originalInvoice!.totalCarat, totalAmount: -_originalInvoice!.totalAmount, isCash: origIsCash);
      }

      if (!_invoice.isForOther) {
        await PurchaseStorageService.distributeSale(totalCarat: totalInvoiceCarat, totalAmount: totalInvoiceAmount, isCash: isCash);
      }

      if (!_invoice.isCashSell) {
        await PdfService.generateInvoice(_invoice);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }

  void updateIsForOther(bool value) {
    _invoice.isForOther = value;
    notifyListeners();
  }

  static Future<void> restoreInventoryOnDelete(String invoiceId) async {
    final invoice = await InvoiceStorageService.getInvoiceById(invoiceId);
    if (invoice != null && !invoice.isForOther) {
      final isCash = invoice.isCashSell;
      await PurchaseStorageService.distributeSale(totalCarat: -invoice.totalCarat, totalAmount: -invoice.totalAmount, isCash: isCash);
    }
  }
}
