import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/invoice_model.dart';

class PdfService {
  /// Generate PDF document (returns the document without saving)
  static Future<pw.Document> generatePdfDocument(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MM-yyyy');

    // Use MultiPage so content flows across pages; signatures stay right after Terms
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Tax Invoice Header
            _buildTaxInvoiceHeader(),
            pw.SizedBox(height: 12),
            // Seller Details - Split Layout
            _buildSellerDetails(invoice),
            pw.SizedBox(height: 12),
            // Buyer Details with Invoice Details on Right
            _buildBuyerDetailsWithInvoice(invoice, dateFormat),
            pw.SizedBox(height: 12),
            // Items Table (can span multiple pages when many items)
            _buildItemsTable(invoice),
            pw.SizedBox(height: 12),
            // Tax Summary and Total
            _buildTaxAndTotals(invoice),
            pw.SizedBox(height: 8),
            // Amount in Words
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Amount in words: ',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    invoice.amountInWords,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            // RTGS + Terms + Signatures grouped so they never split across pages
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildBankDetails(invoice),
                pw.SizedBox(height: 6),
                _buildTermsAndConditions(),
                pw.SizedBox(height: 8),
                _buildSignatures(invoice),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Generate, save and share PDF invoice
  static Future<void> generateInvoice(InvoiceModel invoice) async {
    final pdf = await generatePdfDocument(invoice);

    // Save and share PDF
    final output = await getApplicationDocumentsDirectory();
    // Use buyer name as filename, sanitize it for filesystem
    final buyerName = invoice.buyerName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${output.path}/$buyerName.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share the PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice ${invoice.invoiceNo}',
    );
  }

  static pw.Widget _buildTaxInvoiceHeader() {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1),
        ),
        child: pw.Text(
          'Tax Invoice',
          style: pw.TextStyle(
            fontSize: 16,
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
          // Left Side - Name, Address, Contact
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoice.sellerName,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 3),
                  if (invoice.sellerAddress.isNotEmpty) ...[
                    pw.Text(
                      invoice.sellerAddress,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 3),
                  ],
                  if (invoice.sellerMobile.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'MO: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerMobile,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (invoice.sellerEmail.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'Email: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerEmail,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Vertical Divider
          pw.Container(
            width: 1,
            color: PdfColors.black,
          ),
          // Right Side - Tax Numbers
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (invoice.sellerGstNo.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'GST NO: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerGstNo,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (invoice.sellerPanNo.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'PAN NO: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerPanNo,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (invoice.sellerCstNo.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'CST NO: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerCstNo,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (invoice.sellerVatNo.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'VAT NO: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerVatNo,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (invoice.sellerIecNo.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          'IEC NO: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          invoice.sellerIecNo,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
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
        // Left Side - Buyer Details (horizontal two-column layout inside)
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Buyer Name with "Buyer:" prefix
                if (invoice.buyerName.isNotEmpty) ...[
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Buyer: ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.TextSpan(
                          text: invoice.buyerName,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),
                ],
                // Horizontal two-column layout for buyer details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column: Address, Contact Person, Contact No, Email
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (invoice.buyerAddress.isNotEmpty) ...[
                            pw.Text(
                              'Address:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              invoice.buyerAddress,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.SizedBox(height: 3),
                          ],
                          if (invoice.buyerContactPerson.isNotEmpty) ...[
                            _buildLabelValue('CONTACT PERSON', invoice.buyerContactPerson),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.buyerContactNo.isNotEmpty) ...[
                            _buildLabelValue('CONTACT NO', invoice.buyerContactNo),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.buyerEmail.isNotEmpty)
                            _buildLabelValue('EMAIL', invoice.buyerEmail),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Right column: GST, PAN, VAT, CST, State, Place of Supply
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (invoice.buyerGstNo.isNotEmpty) ...[
                            _buildLabelValue('GST NO', invoice.buyerGstNo),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.buyerPanNo.isNotEmpty) ...[
                            _buildLabelValue('PAN NO', invoice.buyerPanNo),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.buyerVatNo.isNotEmpty) ...[
                            _buildLabelValue('VAT NO', invoice.buyerVatNo),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.buyerCstNo.isNotEmpty) ...[
                            _buildLabelValue('CST NO', invoice.buyerCstNo),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.buyerStateName.isNotEmpty || invoice.buyerStateCode.isNotEmpty) ...[
                            pw.Row(
                              children: [
                                pw.Text(
                                  'State: ',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  invoice.buyerStateName,
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                                if (invoice.buyerStateCode.isNotEmpty)
                                  pw.Text(
                                    ' (${invoice.buyerStateCode})',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                              ],
                            ),
                            pw.SizedBox(height: 1),
                          ],
                          if (invoice.placeOfSupply.isNotEmpty)
                            _buildLabelValue('Place of Supply', invoice.placeOfSupply),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Right Side - Invoice Details
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Invoice No.: ',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      invoice.invoiceNo,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Text(
                      'Invoice Date: ',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      dateFormat.format(invoice.invoiceDate),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                if (invoice.terms.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Terms: ',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        invoice.terms,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
                pw.SizedBox(height: 1),
                pw.Row(
                  children: [
                    pw.Text(
                      'Due Date: ',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      dateFormat.format(invoice.dueDate),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper: label-value row used in buyer details columns
  static pw.Widget _buildLabelValue(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(70),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('S', isHeader: true),
            _buildTableCell('PARTICULAR', isHeader: true),
            _buildTableCell('HSN CODE', isHeader: true),
            _buildTableCell('Carat', isHeader: true),
            _buildTableCell('Rate (Rs)', isHeader: true),
            _buildTableCell('Amount (Rs)', isHeader: true),
          ],
        ),
        // Items
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
        // Totals
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('', isBold: true),
            _buildTableCell('TOTAL', isBold: true),
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
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTaxAndTotals(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'CGST @ ${invoice.cgstRate}%: ',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _formatCurrency(invoice.cgstAmount),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'SGST @ ${invoice.sgstRate}%: ',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _formatCurrency(invoice.sgstAmount),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Round Off:',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Carat: ',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        invoice.totalCarat.toStringAsFixed(2),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 12),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Amount (Rs): ',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _formatCurrency(invoice.grandTotal),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBankDetails(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (invoice.bankName.isNotEmpty || invoice.branch.isNotEmpty ||
              invoice.accountNo.isNotEmpty || invoice.ifscCode.isNotEmpty) ...[
            pw.Text(
              'RTGS Instructions (Beneficiary):',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
          ],
          if (invoice.bankName.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Text(
                  'Bank Name: ',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  invoice.bankName,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
          ],
          if (invoice.branch.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Text(
                  'Branch: ',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  invoice.branch,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
          ],
          if (invoice.accountNo.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Text(
                  'Account no: ',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  invoice.accountNo,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
          ],
          if (invoice.ifscCode.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Text(
                  'IFSC Code: ',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  invoice.ifscCode,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildTermsAndConditions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms and Conditions:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'E. & O. E.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Goods once sold will not be taken back.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Payment within the days of invoice terms',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'In case of delay interest of 1.5% per month will be charged on due amount.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Subject to Surat Jurisdiction',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures(InvoiceModel invoice) {
    final sellerCompanyName = invoice.sellerName.isNotEmpty
        ? invoice.sellerName
        : 'Seller';
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'SIGNATURE AND STAMP OF PURCHASER',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                width: 140,
                height: 2,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'For $sellerCompanyName',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'AUTHORISED/PARTNER SIGNATURE',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                width: 140,
                height: 2,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }
}