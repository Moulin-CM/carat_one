import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/invoice_model.dart';
import 'invoice_storage_service.dart';

class ExportImportService {
  /// Export all invoices to JSON file
  static Future<String> exportInvoicesToJson() async {
    try {
      final invoices = await InvoiceStorageService.getAllInvoices();
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'invoiceCount': invoices.length,
        'invoices': invoices.map((inv) => inv.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      return jsonString;
    } catch (e) {
      throw Exception('Error exporting invoices: $e');
    }
  }

  /// Export invoices to file and share
  static Future<void> exportAndShareInvoices() async {
    try {
      final jsonString = await exportInvoicesToJson();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${directory.path}/invoices_backup_$timestamp.json');

      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice Backup - ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      throw Exception('Error sharing invoices: $e');
    }
  }

  /// Save exported invoices to a specific file path
  static Future<File> saveExportToFile(String fileName) async {
    try {
      final jsonString = await exportInvoicesToJson();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      return file;
    } catch (e) {
      throw Exception('Error saving export file: $e');
    }
  }

  /// Import invoices from JSON string
  static Future<ImportResult> importInvoicesFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate format
      if (data['invoices'] == null || data['invoices'] is! List) {
        throw Exception('Invalid backup file format');
      }

      final invoicesJson = data['invoices'] as List;
      final List<InvoiceModel> importedInvoices = [];
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (var invoiceJson in invoicesJson) {
        try {
          final invoice = InvoiceModel.fromJson(invoiceJson as Map<String, dynamic>);
          
          // Generate new ID to avoid conflicts
          invoice.id = '${DateTime.now().millisecondsSinceEpoch}_${importedInvoices.length}';
          
          importedInvoices.add(invoice);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Invoice ${importedInvoices.length + 1}: ${e.toString()}');
        }
      }

      // Save imported invoices
      for (var invoice in importedInvoices) {
        await InvoiceStorageService.saveInvoice(invoice);
      }

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
        totalCount: invoicesJson.length,
      );
    } catch (e) {
      throw Exception('Error importing invoices: $e');
    }
  }

  /// Import invoices from file
  static Future<ImportResult> importInvoicesFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importInvoicesFromJson(jsonString);
    } catch (e) {
      throw Exception('Error reading import file: $e');
    }
  }

  /// Get backup file info
  static Future<Map<String, dynamic>?> getBackupInfo(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'version': data['version'],
        'exportDate': data['exportDate'],
        'invoiceCount': data['invoiceCount'],
      };
    } catch (_) {
      return null;
    }
  }
}

class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final int totalCount;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.totalCount,
  });

  bool get isSuccess => errorCount == 0;
  String get summary => 
      'Imported $successCount of $totalCount invoices${errorCount > 0 ? ' ($errorCount errors)' : ''}';
}

