import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../services/invoice_storage_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../services/invoice_number_service.dart';
import '../services/settings_service.dart';

class InvoiceFormViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  InvoiceModel _invoice;
  bool _isLoadingProfile = false;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  String? _errorMessage;

  InvoiceFormViewModel({InvoiceModel? invoice}) : _invoice = invoice ?? InvoiceModel() {
    if (_invoice.items.isEmpty) {
      _invoice.items.add(InvoiceItem());
    }
    if (invoice == null) {
      _loadUserProfile();
      _loadAutoInvoiceNumber();
      _loadSettings();
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

  void updateItemParticular(int index, String value) {
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
    if (index < _invoice.items.length) {
      _invoice.items[index].carat = double.tryParse(value) ?? 0.0;
      notifyListeners();
    }
  }

  void updateItemRate(int index, String value) {
    if (index < _invoice.items.length) {
      _invoice.items[index].rate = double.tryParse(value) ?? 0.0;
      notifyListeners();
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
}

