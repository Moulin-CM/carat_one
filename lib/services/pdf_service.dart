import 'dart:io';

import 'package:invoice_generator/constants/app_translations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/invoice_model.dart';


class PdfService {
  /// Cached Unicode-capable PDF theme so every generated document renders
  /// Rupee / non-Latin glyphs correctly. Loaded lazily and falls back to
  /// the default (ASCII) font if the Google Fonts fetch ever fails (e.g.
  /// offline first-run). Subsequent calls reuse the cache.
  static pw.ThemeData? _cachedTheme;
  static bool _themeLoadFailed = false;

  static Future<pw.ThemeData?> buildUnicodeTheme() async {
    if (_cachedTheme != null) return _cachedTheme;
    if (_themeLoadFailed) return null;
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final italic = await PdfGoogleFonts.notoSansItalic();
      final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();
      _cachedTheme = pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: italic,
        boldItalic: boldItalic,
      );
      return _cachedTheme;
    } catch (e) {
      debugPrint('PdfService: failed to load Unicode font, using default: $e');
      _themeLoadFailed = true;
      return null;
    }
  }

  /// Generate PDF document (returns the document without saving)
  static Future<pw.Document> generatePdfDocument(InvoiceModel invoice) async {
    final theme = await buildUnicodeTheme();
    final pdf = theme != null ? pw.Document(theme: theme) : pw.Document();
    final dateFormat = DateFormat('dd-MM-yyyy'.tr);

    // Calculate rounded total for "Amount in words".tr consistency
    final rawGrandTotal = invoice.grandTotal;
    final roundedGrandTotal = rawGrandTotal.round();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        footer: (pw.Context context) => _buildSignatures(invoice),
        build: (pw.Context context) {
          return [
            // Tax Invoice Header
            _buildTaxInvoiceHeader(),
            pw.SizedBox(height: 8),
            
            // Seller Details
            _buildSellerDetails(invoice),
            pw.SizedBox(height: 8),
            
            // Buyer Details with Invoice Details on Right
            _buildBuyerDetailsWithInvoice(invoice, dateFormat),
            pw.SizedBox(height: 8),
            
            // Items Table
            _buildItemsTable(invoice),
            pw.SizedBox(height: 8),
            
            // Tax Summary and Total
            _buildTaxAndTotals(invoice),
            pw.SizedBox(height: 6),
            
            // Amount in Words
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Amount in words: '.tr,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: _numberToWords(roundedGrandTotal),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            
            // RTGS Instructions
            _buildBankDetails(invoice),
            pw.SizedBox(height: 6),
            
            // Terms and Conditions
            _buildTermsAndConditions(),
            pw.SizedBox(height: 8),

            _buildDeclaration(),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Build a filesystem-safe filename unique to this invoice.
  static String buildInvoiceFileName(InvoiceModel invoice) {
    String sanitize(String v) =>
        v.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
    final buyer = sanitize(invoice.buyerName);
    final no = sanitize(invoice.invoiceNo);
    final parts = <String>[
      'Invoice'.tr,
      if (no.isNotEmpty) no,
      if (buyer.isNotEmpty) buyer,
    ];
    final base = parts.join('_');
    return '${base.isEmpty ? 'Invoice_${invoice.id}' : base}.pdf';
  }

  /// Write the PDF to the app documents directory and return the file. Always
  /// overwrites any previous file for the same invoice so the on-disk copy
  /// stays in sync with the latest edits.
  static Future<File> writeInvoicePdf(InvoiceModel invoice) async {
    final pdf = await generatePdfDocument(invoice);
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${buildInvoiceFileName(invoice)}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> generateInvoice(InvoiceModel invoice) async {
    if (kIsWeb) {
      final pdf = await generatePdfDocument(invoice);
      final pdfBytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: buildInvoiceFileName(invoice),
      );
      return;
    }

    final file = await writeInvoicePdf(invoice);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice ${invoice.invoiceNo}',
      );
    } catch (e) {
      // Share sheet failures must not block the invoice save. The PDF is
      // already persisted to disk and can be re-shared from the list view.
      debugPrint('PdfService: share sheet failed: $e');
    }
  }

  static pw.Widget _buildTaxInvoiceHeader() {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1),
        ),
        child: pw.Text('Tax Invoice'.tr,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSellerDetails(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoice.sellerName,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    invoice.sellerAddress,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 2),
                  if (invoice.sellerMobile.isNotEmpty)
                    pw.Text('MO: ${invoice.sellerMobile}'.tr, style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.sellerEmail.isNotEmpty)
                    pw.Text('Email: ${invoice.sellerEmail}'.tr, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ),
          pw.Container(width: 1, height: 60, color: PdfColors.black),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (invoice.sellerGstNo.isNotEmpty)
                    _buildLabelValue('GST NO'.tr, invoice.sellerGstNo, size: 9),
                  if (invoice.sellerPanNo.isNotEmpty)
                    _buildLabelValue('PAN NO'.tr, invoice.sellerPanNo, size: 9),
                  if (invoice.sellerCstNo.isNotEmpty)
                    _buildLabelValue('CST NO'.tr, invoice.sellerCstNo, size: 9),
                  if (invoice.sellerVatNo.isNotEmpty)
                    _buildLabelValue('VAT NO'.tr, invoice.sellerVatNo, size: 9),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBuyerDetailsWithInvoice(InvoiceModel invoice, DateFormat dateFormat) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Buyer: '.tr,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text: invoice.buyerName,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (invoice.buyerAddress.isNotEmpty) ...[
                            pw.Text('Address:'.tr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text(invoice.buyerAddress, style: const pw.TextStyle(fontSize: 9)),
                          ],
                          if (invoice.buyerContactPerson.isNotEmpty)
                            _buildLabelValue('CONTACT'.tr, invoice.buyerContactPerson, size: 9),
                          if (invoice.buyerContactNo.isNotEmpty)
                            _buildLabelValue('MOBILE'.tr, invoice.buyerContactNo, size: 9),
                          if (invoice.buyerEmail.isNotEmpty)
                            _buildLabelValue('EMAIL', invoice.buyerEmail, size: 9),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (invoice.buyerGstNo.isNotEmpty)
                            _buildLabelValue('GST NO'.tr, invoice.buyerGstNo, size: 9),
                          if (invoice.buyerPanNo.isNotEmpty)
                            _buildLabelValue('PAN NO'.tr, invoice.buyerPanNo, size: 9),
                          if (invoice.buyerStateName.isNotEmpty)
                            _buildLabelValue('State'.tr, '${invoice.buyerStateName}${invoice.buyerStateCode.isNotEmpty ? " (${invoice.buyerStateCode})" : ""}', size: 9),
                          if (invoice.placeOfSupply.isNotEmpty)
                            _buildLabelValue('Supply'.tr, invoice.placeOfSupply, size: 9),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInvoiceDetailRow('Inv No.'.tr, invoice.invoiceNo),
                _buildInvoiceDetailRow('Date'.tr, dateFormat.format(invoice.invoiceDate)),
                if (invoice.terms.isNotEmpty) 
                   _buildInvoiceDetailRow('Terms'.tr, invoice.terms),
                _buildInvoiceDetailRow('Due Date'.tr, dateFormat.format(invoice.dueDate)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: '.tr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildLabelValue(String label, String value, {double size = 10}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label: '.tr, style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold)),
        pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: size))),
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('S', isHeader: true),
            _buildTableCell('PARTICULAR'.tr, isHeader: true),
            _buildTableCell('HSN CODE'.tr, isHeader: true),
            _buildTableCell('Carat'.tr, isHeader: true),
            _buildTableCell('Rate (Rs)'.tr, isHeader: true),
            _buildTableCell('Amount (Rs)'.tr, isHeader: true),
          ],
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${entry.key + 1}'),
              _buildTableCell(item.particular),
              _buildTableCell(item.hsnCode),
              _buildTableCell(item.carat.toStringAsFixed(2)),
              _buildTableCell(_formatCurrency(item.rate)),
              _buildTableCell(_formatCurrency(item.amount)),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('', isBold: true),
            _buildTableCell('TOTAL'.tr, isBold: true),
            _buildTableCell('', isBold: true),
            _buildTableCell(invoice.totalCarat.toStringAsFixed(2), isBold: true),
            _buildTableCell('', isBold: true),
            _buildTableCell(_formatCurrency(invoice.totalAmount), isBold: true),
          ],
        ),
      ],
    );
  }

  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTaxAndTotals(InvoiceModel invoice) {
    final rawGrandTotal = invoice.grandTotal;
    final roundedGrandTotal = rawGrandTotal.roundToDouble();
    final roundOff = roundedGrandTotal - rawGrandTotal;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (invoice.discountRate > 0) ...[
                _buildTaxRow('Discount @ ${invoice.discountRate}%',
                    '- ${_formatCurrency(invoice.discountAmount)}'),
                _buildTaxRow('Taxable Amount'.tr,
                    _formatCurrency(invoice.taxableAmount)),
              ],
              if (!invoice.isIgst) ...[
                _buildTaxRow('CGST @ ${invoice.cgstRate}%', _formatCurrency(invoice.cgstAmount)),
                _buildTaxRow('SGST @ ${invoice.sgstRate}%', _formatCurrency(invoice.sgstAmount)),
              ] else ...[
                _buildTaxRow('IGST @ ${invoice.igstRate}%', _formatCurrency(invoice.igstAmount)),
              ],
              if (invoice.brokerChargeRate > 0)
                _buildTaxRow('Broker Charge @ ${invoice.brokerChargeRate}%',
                    '- ${_formatCurrency(invoice.brokerChargeAmount)}'),
              _buildTaxRow('Round Off'.tr, _formatCurrency(roundOff)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('TOTAL Carat: ${invoice.totalCarat.toStringAsFixed(2)}'.tr, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 12),
                  pw.Text('Amount (Rs): ${_formatCurrency(roundedGrandTotal)}'.tr, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTaxRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: '.tr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildBankDetails(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      width: double.infinity,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RTGS Instructions (Beneficiary):'.tr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              pw.Expanded(child: _buildBankInfo('Bank Name'.tr, invoice.bankName)),
              pw.Expanded(child: _buildBankInfo('Branch'.tr, invoice.branch)),
            ],
          ),
          pw.Row(
            children: [
              pw.Expanded(child: _buildBankInfo('Account No'.tr, invoice.accountNo)),
              pw.Expanded(child: _buildBankInfo('IFSC Code'.tr, invoice.ifscCode)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBankInfo(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('$label: '.tr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _buildTermsAndConditions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      width: double.infinity,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Terms and Conditions:'.tr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text('E. & O. E. | Goods once sold will not be taken back.'.tr, style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Payment within the days of invoice terms. In case of delay interest of 1.5% per month will be charged.'.tr, style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Subject to Surat Jurisdiction'.tr, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildDeclaration() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Declaration',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 4),

          pw.Text(
            '1. The diamonds herein invoiced have been purchased from legitimate sources not involved in funding conflict, in compliance with United Nations Resolutions and corresponding national laws. '
                'The seller hereby guarantees that these diamonds are conflict free and confirms.',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.justify,
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            '2. By receipt of the above goods, then buyer/consignee acknowledges that the above goods purchased or received will be fully represented and disclosed as laboratory grown polished diamonds.',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.justify,
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            '3. Payment to be made by NEFT/RTGS/IMPS only.',
            style: const pw.TextStyle(fontSize: 8),
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            '4. No E-Way bill is required.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Purchaser'.tr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.sellerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Signature'.tr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('Signature'.tr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero Only'.tr;
    final ones = ['', 'One'.tr, 'Two'.tr, 'Three'.tr, 'Four'.tr, 'Five'.tr, 'Six'.tr, 'Seven'.tr, 'Eight'.tr, 'Nine'.tr, 'Ten'.tr, 'Eleven'.tr, 'Twelve'.tr, 'Thirteen'.tr, 'Fourteen'.tr, 'Fifteen'.tr, 'Sixteen'.tr, 'Seventeen'.tr, 'Eighteen'.tr, 'Nineteen'.tr];
    final tens = ['', '', 'Twenty'.tr, 'Thirty'.tr, 'Forty'.tr, 'Fifty'.tr, 'Sixty'.tr, 'Seventy'.tr, 'Eighty'.tr, 'Ninety'.tr];
    String convert(int n) {
      if (n < 20) return ones[n];
      if (n < 100) return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
      if (n < 1000) return '${ones[n ~/ 100]} Hundred${n % 100 > 0 ? ' ${convert(n % 100)}' : ''}';
      if (n < 100000) return '${convert(n ~/ 1000)} Thousand${n % 1000 > 0 ? ' ${convert(n % 1000)}' : ''}';
      if (n < 10000000) return '${convert(n ~/ 100000)} Lac${n % 100000 > 0 ? ' ${convert(n % 100000)}' : ''}';
      return '';
    }
    return '${convert(number)} Only';
  }
}
