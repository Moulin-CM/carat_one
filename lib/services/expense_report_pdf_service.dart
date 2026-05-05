import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense_model.dart';
import 'pdf_service.dart';

class ExpenseReportPdfService {
  /// Builds a bank-style expense statement covering [items] in the given
  /// [periodLabel] / [start]–[end] range. Each entry is either a Credit
  /// (money in) or a Debit (money out).
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

    final creditTotal =
        items.where((e) => e.isCredit).fold<double>(0, (s, e) => s + e.amount);
    final debitTotal =
        items.where((e) => !e.isCredit).fold<double>(0, (s, e) => s + e.amount);
    final net = creditTotal - debitTotal;

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
          _summary(items.length, creditTotal, debitTotal, net, amountFmt),
          pw.SizedBox(height: 14),
          _tableHeader(),
          ...grouped.entries.expand((group) {
            final groupNet = group.value.fold<double>(
                0, (s, e) => s + (e.isCredit ? e.amount : -e.amount));
            return [
              _dayHeader(group.key, groupNet, amountFmt),
              ...group.value.map((e) => _row(e, amountFmt)),
            ];
          }),
          pw.SizedBox(height: 10),
          _totalFooter(net, amountFmt),
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

  static pw.Widget _summary(int count, double credit, double debit,
      double net, NumberFormat amountFmt) {
    final netSign = net >= 0 ? '+' : '-';
    final netColor = net >= 0 ? PdfColors.green800 : PdfColors.red;
    return pw.Row(
      children: [
        _summaryBox('Entries', '$count'),
        pw.SizedBox(width: 8),
        _summaryBox('Credits', '+ ${amountFmt.format(credit)}',
            valueColor: PdfColors.green800),
        pw.SizedBox(width: 8),
        _summaryBox('Debits', '- ${amountFmt.format(debit)}',
            valueColor: PdfColors.red),
        pw.SizedBox(width: 8),
        _summaryBox('Net', '$netSign ${amountFmt.format(net.abs())}',
            valueColor: netColor),
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
                    fontSize: 11,
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
              flex: 4,
              child: pw.Text('Person',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Date',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 1,
              child: pw.Text('Type',
                  textAlign: pw.TextAlign.center,
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
      String date, double groupNet, NumberFormat amountFmt) {
    final sign = groupNet >= 0 ? '+' : '-';
    final color = groupNet >= 0 ? PdfColors.green800 : PdfColors.red;
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
          pw.Text('$sign ${amountFmt.format(groupNet.abs())}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: color)),
        ],
      ),
    );
  }

  static pw.Widget _row(ExpenseModel e, NumberFormat amountFmt) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final color = e.isCredit ? PdfColors.green800 : PdfColors.red;
    final sign = e.isCredit ? '+' : '-';
    final name = e.personName.isNotEmpty ? e.personName : 'Entry';
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 4,
              child: pw.Text(name,
                  style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(dateFmt.format(e.expenseDate),
                  style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
              flex: 1,
              child: pw.Text(e.isCredit ? 'Cr' : 'Dr',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: color))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('$sign ${amountFmt.format(e.amount)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 10, color: color))),
        ],
      ),
    );
  }

  static pw.Widget _totalFooter(double net, NumberFormat amountFmt) {
    final sign = net >= 0 ? '+' : '-';
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('NET (Credits − Debits)',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
          pw.Text('$sign ${amountFmt.format(net.abs())}',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
