import 'package:intl/intl.dart';

import '../../models/invoice_model.dart';
import '../../models/purchase_model.dart';
import '../invoice_storage_service.dart';
import '../purchase_storage_service.dart';
import 'format_parsers.dart';
import 'header_mapper.dart';
import 'import_event_bus.dart';

enum ImportDataKind { purchase, sell }

class DataImportResult {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final List<String> unmatchedHeaders;
  final List<String> matchedHeaders;
  final ImportDataKind kind;

  DataImportResult({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.unmatchedHeaders,
    required this.matchedHeaders,
    required this.kind,
  });

  bool get isSuccess => errorCount == 0 && successCount > 0;
  String get summary =>
      'Imported $successCount of $totalRows ${kind == ImportDataKind.purchase ? 'purchases' : 'sells'}'
      '${errorCount > 0 ? ' ($errorCount errors)' : ''}';
}

class DataImportService {
  /// Detect format by extension, parse the file, then auto-map columns and
  /// persist via the storage service that matches [kind].
  ///
  /// Throws [FormatException] for unsupported extensions or wholly empty
  /// files. Per-row errors are collected into the returned result.
  static Future<DataImportResult> importFromFile({
    required String filePath,
    required ImportDataKind kind,
  }) async {
    final ext = filePath.toLowerCase().split('.').last;
    final ParsedTable table;
    switch (ext) {
      case 'xlsx':
      case 'xls':
        table = await FormatParsers.parseExcel(filePath);
        break;
      case 'csv':
        table = await FormatParsers.parseCsv(filePath);
        break;
      case 'json':
        table = await FormatParsers.parseJson(filePath);
        break;
      case 'pdf':
        table = await FormatParsers.parsePdf(filePath);
        break;
      default:
        throw FormatException('Unsupported file type: .$ext');
    }

    if (table.isEmpty) {
      return DataImportResult(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: const ['File contains no data rows'],
        unmatchedHeaders: const [],
        matchedHeaders: const [],
        kind: kind,
      );
    }

    final fields = kind == ImportDataKind.purchase
        ? HeaderMapper.purchaseFields
        : HeaderMapper.invoiceFields;

    final mapping = HeaderMapper.map(table.headers, fields);

    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    for (var i = 0; i < table.rows.length; i++) {
      final raw = table.rows[i];
      final mapped = <String, String>{};
      raw.forEach((header, value) {
        final fieldKey = mapping.matched[header];
        if (fieldKey != null) mapped[fieldKey] = value;
      });

      try {
        if (kind == ImportDataKind.purchase) {
          final p = _buildPurchase(mapped, i);
          await PurchaseStorageService.savePurchase(p);
        } else {
          final inv = _buildInvoice(mapped, i);
          await InvoiceStorageService.saveInvoice(inv);
        }
        successCount++;
      } catch (e) {
        errorCount++;
        errors.add('Row ${i + 2}: ${e.toString()}');
      }
    }

    if (successCount > 0) {
      ImportEventBus.instance.notifyImported(
        kind == ImportDataKind.purchase
            ? ImportedDataKind.purchase
            : ImportedDataKind.invoice,
      );
    }

    return DataImportResult(
      totalRows: table.rows.length,
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
      unmatchedHeaders: mapping.unmatched,
      matchedHeaders: mapping.matched.keys.toList(),
      kind: kind,
    );
  }

  // ── Row → Model builders ────────────────────────────────────────────────

  static PurchaseModel _buildPurchase(Map<String, String> row, int idx) {
    final p = PurchaseModel();
    // Force a fresh, unique id even when imports happen quickly back-to-back.
    p.id = '${DateTime.now().millisecondsSinceEpoch}_p$idx';

    p.totalCarat = _toDouble(row['totalCarat']);
    p.amountPerCarat = _toDouble(row['amountPerCarat']);
    p.discount = _toDouble(row['discount']);

    // If the row gives a totalAmount but no amountPerCarat, keep totalAmount
    // verbatim and back-derive the rate so totals tally up correctly.
    final providedTotal = _toDouble(row['totalAmount']);
    if (providedTotal > 0 && p.amountPerCarat == 0 && p.totalCarat > 0) {
      p.amountPerCarat = providedTotal / p.totalCarat;
    }
    p.totalAmount = providedTotal > 0
        ? providedTotal
        : p.totalCarat * p.amountPerCarat * (1 - p.discount / 100);

    p.dueDays = _toInt(row['dueDays']);
    p.sellerName = row['sellerName'] ?? '';
    p.brokerName = row['brokerName'] ?? '';
    p.brokerChargeRate = _toDouble(row['brokerChargeRate']);

    final rawSize = row['size'] ?? '';
    if (rawSize.isNotEmpty) {
      final m = RegExp(r'^\s*([A-Za-z]*)\s*(\d*)').firstMatch(rawSize);
      p.sizeAlpha = (m?.group(1) ?? '').toUpperCase();
      p.sizeNumeric = int.tryParse(m?.group(2) ?? '') ?? 0;
    } else {
      p.sizeAlpha = (row['sizeAlpha'] ?? '').toUpperCase();
      p.sizeNumeric = _toInt(row['sizeNumeric']);
    }

    p.buyDate = _toDate(row['buyDate']) ?? DateTime.now();
    p.paymentDate = _toDate(row['paymentDate']) ?? p.buyDate;

    final type = (row['paymentType'] ?? '').toLowerCase().trim();
    p.paymentType = (type == 'bill' || type == 'account') ? 'bill' : 'cash';

    p.isForOther = _toBool(row['isForOther']);

    return p;
  }

  static InvoiceModel _buildInvoice(Map<String, String> row, int idx) {
    final inv = InvoiceModel();
    inv.id = '${DateTime.now().millisecondsSinceEpoch}_i$idx';

    inv.invoiceNo = row['invoiceNo'] ?? '';
    inv.invoiceDate = _toDate(row['invoiceDate']) ?? DateTime.now();
    inv.dueDate = _toDate(row['dueDate']) ?? inv.invoiceDate;
    inv.terms = row['terms'] ?? '';

    inv.buyerName = row['buyerName'] ?? '';
    inv.buyerAddress = row['buyerAddress'] ?? '';
    inv.buyerGstNo = row['buyerGstNo'] ?? '';
    inv.buyerPanNo = row['buyerPanNo'] ?? '';
    inv.buyerContactNo = row['buyerContactNo'] ?? '';
    inv.buyerEmail = row['buyerEmail'] ?? '';
    inv.buyerStateName = row['buyerStateName'] ?? '';
    inv.buyerStateCode = row['buyerStateCode'] ?? '';
    inv.placeOfSupply = row['placeOfSupply'] ?? '';

    inv.brokerName = row['brokerName'] ?? '';
    inv.brokerChargeRate = _toDouble(row['brokerChargeRate']);
    inv.discountRate = _toDouble(row['discountRate']);
    inv.isCashSell = _toBool(row['isCashSell']);
    inv.isForOther = _toBool(row['isForOther']);
    inv.isIgst = _toBool(row['isIgst']);

    final cgst = _toDoubleOrNull(row['cgstRate']);
    final sgst = _toDoubleOrNull(row['sgstRate']);
    final igst = _toDoubleOrNull(row['igstRate']);
    if (cgst != null) inv.cgstRate = cgst;
    if (sgst != null) inv.sgstRate = sgst;
    if (igst != null) inv.igstRate = igst;

    // Build a single line item from the row's carat/rate/amount columns.
    final item = InvoiceItem();
    final carat = _toDouble(row['itemCarat']);
    final rate = _toDouble(row['itemRate']);
    final lineAmount = _toDoubleOrNull(row['itemAmount']);
    item.carat = carat;
    item.rate = rate > 0
        ? rate
        : (lineAmount != null && carat > 0 ? lineAmount / carat : 0);
    if ((row['itemParticular'] ?? '').isNotEmpty) {
      item.particular = row['itemParticular']!;
    }
    if ((row['itemHsnCode'] ?? '').isNotEmpty) {
      item.hsnCode = row['itemHsnCode']!;
    }
    inv.items = [item];

    return inv;
  }

  // ── Coercion helpers ────────────────────────────────────────────────────

  static double _toDouble(String? raw) => _toDoubleOrNull(raw) ?? 0.0;

  static double? _toDoubleOrNull(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[₹$,€£\s]'), '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static int _toInt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final asDouble = _toDoubleOrNull(raw);
    return asDouble?.round() ?? 0;
  }

  static bool _toBool(String? raw) {
    if (raw == null) return false;
    final v = raw.trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes' || v == 'y';
  }

  /// Parse a date from many common formats: ISO 8601, dd/MM/yyyy,
  /// dd-MM-yyyy, MM/dd/yyyy, yyyy-MM-dd, or epoch milliseconds.
  static DateTime? _toDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();

    // Epoch (millis) — e.g. "1715731200000".
    final asInt = int.tryParse(v);
    if (asInt != null && asInt > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }

    try {
      return DateTime.parse(v);
    } catch (_) {}

    const patterns = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'd/M/yyyy',
      'd-M-yyyy',
      'MM/dd/yyyy',
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'dd MMM yyyy',
      'dd-MMM-yyyy',
    ];
    for (final p in patterns) {
      try {
        return DateFormat(p).parseStrict(v);
      } catch (_) {}
    }
    return null;
  }
}
