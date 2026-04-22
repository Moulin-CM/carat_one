import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense_model.dart';
import 'pdf_service.dart';

class ExpenseReportPdfService {
  /// Builds a bank-style expense statement covering [items] in the given
  /// [periodLabel] / [start]–[end] range.
  static Future<pw.Document> build({
    required List<ExpenseModel> items,
    required String periodLabel,
    required DateTime start,
    required DateTime end,
    String heading = 'Expense Statement',
  }) async {
    final theme = await PdfService.buildUnicodeTheme();
    final doc = theme != null ? pw.Document(theme: theme) : pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy');
    final amountFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final total = items.fold<double>(0, (s, e) => s + e.amount);

    final grouped = <String, List<ExpenseModel>>{};
    for (final e in items) {
      final key = dateFmt.format(e.expenseDate);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(heading, periodLabel, dateFmt, start, end),
          pw.SizedBox(height: 14),
          _summary(items.length, total, amountFmt),
          pw.SizedBox(height: 14),
          _tableHeader(),
          ...grouped.entries.expand((group) {
            final groupTotal =
                group.value.fold<double>(0, (s, e) => s + e.amount);
            return [
              _dayHeader(group.key, groupTotal, amountFmt),
              ...group.value.map((e) => _row(e, amountFmt)),
            ];
          }),
          pw.SizedBox(height: 10),
          _totalFooter(total, amountFmt),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _header(String heading, String periodLabel,
      DateFormat dateFmt, DateTime start, DateTime end) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(heading,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(periodLabel,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 11)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('From ${dateFmt.format(start)}',
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 10)),
              pw.Text('To ${dateFmt.format(end)}',
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                    color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summary(
      int count, double total, NumberFormat amountFmt) {
    return pw.Row(
      children: [
        _summaryBox('Entries', '$count'),
        pw.SizedBox(width: 8),
        _summaryBox('Total Debit', '- ${amountFmt.format(total)}',
            valueColor: PdfColors.red),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, String value,
      {PdfColor? valueColor}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(
                    color: PdfColors.grey700, fontSize: 9)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: valueColor ?? PdfColors.black)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader() {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: PdfColors.grey200,
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 3,
              child: pw.Text('Type',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Date',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Amount',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _dayHeader(
      String date, double groupTotal, NumberFormat amountFmt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: PdfColors.blue50,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(date,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.blue900)),
          pw.Text('- ${amountFmt.format(groupTotal)}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.red)),
        ],
      ),
    );
  }

  static pw.Widget _row(ExpenseModel e, NumberFormat amountFmt) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 3,
              child: pw.Text(e.type.isNotEmpty ? e.type : 'Expense',
                  style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(dateFmt.format(e.expenseDate),
                  style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('- ${amountFmt.format(e.amount)}',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.red))),
        ],
      ),
    );
  }

  static pw.Widget _totalFooter(double total, NumberFormat amountFmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL EXPENSES',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
          pw.Text('- ${amountFmt.format(total)}',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
