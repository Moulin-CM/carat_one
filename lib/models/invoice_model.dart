
class InvoiceModel {
  // Seller Details
  String sellerName = 'TIMELESS DIAMOND';
  String sellerAddress = 'A-1204 SAMRAT SKYLINE BUILDING DABHOLI GAM, KATARGAM, SURAT-395004';
  String sellerMobile = '9429510634';
  String sellerEmail = 'chovatiyakalpesh32@gmail.com';
  String sellerGstNo = '24AFWPC3919B1ZN';
  String sellerPanNo = 'AFWPC3919B';
  String sellerCstNo = '';
  String sellerVatNo = '';
  String sellerIecNo = '';

  // Buyer Details
  String buyerName = '';
  String buyerAddress = '';
  String buyerGstNo = '';
  String buyerPanNo = '';
  String buyerVatNo = '';
  String buyerCstNo = '';
  String buyerContactPerson = '';
  String buyerContactNo = '';
  String buyerEmail = '';
  String buyerStateName = '';
  String buyerStateCode = '';
  String placeOfSupply = '';

  // Invoice Details
  String invoiceNo = '';
  DateTime invoiceDate = DateTime.now();
  String terms = '';
  DateTime dueDate = DateTime.now();

  // Bank Details
  String bankName = 'AXIS BANK LTD.';
  String branch = 'KATARGAM BRANCH';
  String accountNo = '921020014373260';
  String ifscCode = 'UTIB0001440';

  // Items
  List<InvoiceItem> items = [];

  // Tax Rates
  double cgstRate = 0.75;
  double sgstRate = 0.75;
  double igstRate = 1.5;

  // Unique ID for storage
  String id = DateTime.now().millisecondsSinceEpoch.toString();

  InvoiceModel();

  InvoiceModel.fromJson(Map<String, dynamic> json)
      : sellerName = json['sellerName'] ?? 'TIMELESS DIAMOND',
        sellerAddress = json['sellerAddress'] ?? '',
        sellerMobile = json['sellerMobile'] ?? '',
        sellerEmail = json['sellerEmail'] ?? '',
        sellerGstNo = json['sellerGstNo'] ?? '',
        sellerPanNo = json['sellerPanNo'] ?? '',
        sellerCstNo = json['sellerCstNo'] ?? '',
        sellerVatNo = json['sellerVatNo'] ?? '',
        sellerIecNo = json['sellerIecNo'] ?? '',
        buyerName = json['buyerName'] ?? '',
        buyerAddress = json['buyerAddress'] ?? '',
        buyerGstNo = json['buyerGstNo'] ?? '',
        buyerPanNo = json['buyerPanNo'] ?? '',
        buyerVatNo = json['buyerVatNo'] ?? '',
        buyerCstNo = json['buyerCstNo'] ?? '',
        buyerContactPerson = json['buyerContactPerson'] ?? '',
        buyerContactNo = json['buyerContactNo'] ?? '',
        buyerEmail = json['buyerEmail'] ?? '',
        buyerStateName = json['buyerStateName'] ?? '',
        buyerStateCode = json['buyerStateCode'] ?? '',
        placeOfSupply = json['placeOfSupply'] ?? '',
        invoiceNo = json['invoiceNo'] ?? '',
        invoiceDate = _parseFlexibleDate(json['invoiceDate']),
        terms = json['terms'] ?? '',
        dueDate = _parseFlexibleDate(json['dueDate']),
        bankName = json['bankName'] ?? 'AXIS BANK LTD.',
        branch = json['branch'] ?? '',
        accountNo = json['accountNo'] ?? '',
        ifscCode = json['ifscCode'] ?? '',
        items = (json['items'] as List<dynamic>?)
                ?.map((item) => InvoiceItem.fromJson(item))
                .toList() ??
            [],
        cgstRate = (json['cgstRate'] ?? 0.75).toDouble(),
        sgstRate = (json['sgstRate'] ?? 0.75).toDouble(),
        igstRate = (json['igstRate'] ?? 1.5).toDouble(),
        id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Safely parse dates stored either as ISO8601 strings, integer
  /// timestamps (milliseconds since epoch), or already as DateTime.
  /// Falls back to `DateTime.now()` if parsing fails or value is null.
  static DateTime _parseFlexibleDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      if (raw is DateTime) return raw;
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw is String && raw.isNotEmpty) {
        return DateTime.parse(raw);
      }
    } catch (_) {
      // Ignore and fall through to default below.
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerName': sellerName,
        'sellerAddress': sellerAddress,
        'sellerMobile': sellerMobile,
        'sellerEmail': sellerEmail,
        'sellerGstNo': sellerGstNo,
        'sellerPanNo': sellerPanNo,
        'sellerCstNo': sellerCstNo,
        'sellerVatNo': sellerVatNo,
        'sellerIecNo': sellerIecNo,
        'buyerName': buyerName,
        'buyerAddress': buyerAddress,
        'buyerGstNo': buyerGstNo,
        'buyerPanNo': buyerPanNo,
        'buyerVatNo': buyerVatNo,
        'buyerCstNo': buyerCstNo,
        'buyerContactPerson': buyerContactPerson,
        'buyerContactNo': buyerContactNo,
        'buyerEmail': buyerEmail,
        'buyerStateName': buyerStateName,
        'buyerStateCode': buyerStateCode,
        'placeOfSupply': placeOfSupply,
        'invoiceNo': invoiceNo,
        'invoiceDate': invoiceDate.toIso8601String(),
        'terms': terms,
        'dueDate': dueDate.toIso8601String(),
        'bankName': bankName,
        'branch': branch,
        'accountNo': accountNo,
        'ifscCode': ifscCode,
        'items': items.map((item) => item.toJson()).toList(),
        'cgstRate': cgstRate,
        'sgstRate': sgstRate,
        'igstRate': igstRate,
      };

  double get totalCarat => items.fold(0.0, (sum, item) => sum + item.carat);
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);
  double get cgstAmount => totalAmount * (cgstRate / 100);
  double get sgstAmount => totalAmount * (sgstRate / 100);
  double get igstAmount => totalAmount * (igstRate / 100);
  double get grandTotal => totalAmount + cgstAmount + sgstAmount;

  String get amountInWords => _numberToWords(grandTotal.toInt());

  String _numberToWords(int number) {
    if (number == 0) return 'Zero Only';

    final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convert(int n) {
      if (n < 20) return ones[n];
      if (n < 100) return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
      if (n < 1000) {
        final hundred = n ~/ 100;
        final remainder = n % 100;
        return '${ones[hundred]} Hundred${remainder > 0 ? ' ${convert(remainder)}' : ''}';
      }
      if (n < 100000) {
        final thousand = n ~/ 1000;
        final remainder = n % 1000;
        return '${convert(thousand)} Thousand${remainder > 0 ? ' ${convert(remainder)}' : ''}';
      }
      if (n < 10000000) {
        final lac = n ~/ 100000;
        final remainder = n % 100000;
        return '${convert(lac)} Lac${remainder > 0 ? ' ${convert(remainder)}' : ''}';
      }
      return '';
    }

    return '${convert(number)} Only';
  }
}

class InvoiceItem {
  String particular = 'CUT AND POLISHED LAB GROWN DIAMOND SALE';
  String hsnCode = '71049120';
  double carat = 0.0;
  double rate = 0.0;
  String? inventoryItemId; // ID of the selected inventory item
  double get amount => carat * rate;

  InvoiceItem();

  InvoiceItem.fromJson(Map<String, dynamic> json)
      : particular = json['particular'] ?? 'CUT AND POLISHED LAB GROWN DIAMOND SALE',
        hsnCode = json['hsnCode'] ?? '71049120',
        carat = (json['carat'] ?? 0.0).toDouble(),
        rate = (json['rate'] ?? 0.0).toDouble(),
        inventoryItemId = json['inventoryItemId'];

  Map<String, dynamic> toJson() => {
        'particular': particular,
        'hsnCode': hsnCode,
        'carat': carat,
        'rate': rate,
        'inventoryItemId': inventoryItemId,
      };
}

