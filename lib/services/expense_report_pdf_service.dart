import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

import 'package:invoice_generator/constants/app_translations.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/ledger_entry.dart';
import 'pdf_service.dart';


class ExpenseReportPdfService {
  /// Builds a bank-style statement covering [items] (any ledger entries —
  /// user expenses, sell collections, and seller payments) in the given
  /// [periodLabel] / [start]–[end] range. Each entry is either a Credit
  /// (money in) or a Debit (money out).
  static Future<pw.Document> build({
    required List<LedgerEntry> items,
    required String periodLabel,
    required DateTime start,
    required DateTime end,
    String? heading,
  }) async {
    final theme = await PdfService.buildUnicodeTheme();
    final doc = theme != null ? pw.Document(theme: theme) : pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy'.tr);
    final amountFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final displayHeading = heading ?? 'Expense Statement'.tr;

    final creditTotal =
        items.where((e) => !e.isDebit).fold<double>(0, (s, e) => s + e.amount);
    final debitTotal =
        items.where((e) => e.isDebit).fold<double>(0, (s, e) => s + e.amount);
    // Business expenses are a subset of the debits above — reported
    // separately so the reader can see what hit profitability.
    final expenseTotal = items
        .where((e) => e.isBusinessExpense)
        .fold<double>(0, (s, e) => s + e.amount);
    final net = creditTotal - debitTotal;

    final grouped = <String, List<LedgerEntry>>{};
    for (final e in items) {
      final key = dateFmt.format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(displayHeading, periodLabel, dateFmt, start, end),
          pw.SizedBox(height: 14),
          _summary(items.length, creditTotal, debitTotal, expenseTotal, net,
              amountFmt),
          pw.SizedBox(height: 14),
          _tableHeader(),
          ...grouped.entries.expand((group) {
            final groupNet = group.value.fold<double>(
                0, (s, e) => s + (e.isDebit ? -e.amount : e.amount));
            return [
              _dayHeader(group.key, groupNet, amountFmt),
              ...group.value.map((e) => _row(e, amountFmt)),
            ];
          }),
          pw.SizedBox(height: 10),
          _totalFooter(net, expenseTotal, amountFmt),
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
              pw.Text('From ${dateFmt.format(start)}'.tr,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 10)),
              pw.Text('To ${dateFmt.format(end)}'.tr,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated ${DateFormat('dd MMM yyyy'.tr).format(DateTime.now())}',
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
      double expense, double net, NumberFormat amountFmt) {
    final netSign = net >= 0 ? '+' : '-';
    final netColor = net >= 0 ? PdfColors.green800 : PdfColors.red;
    return pw.Row(
      children: [
        _summaryBox('Entries'.tr, '$count'),
        pw.SizedBox(width: 8),
        _summaryBox('Credits'.tr, '+ ${amountFmt.format(credit)}',
            valueColor: PdfColors.green800),
        pw.SizedBox(width: 8),
        _summaryBox('Debits'.tr, '- ${amountFmt.format(debit)}',
            valueColor: PdfColors.red),
        pw.SizedBox(width: 8),
        _summaryBox('Expenses'.tr, '- ${amountFmt.format(expense)}',
            valueColor: PdfColors.deepOrange700),
        pw.SizedBox(width: 8),
        _summaryBox('Net'.tr, '$netSign ${amountFmt.format(net.abs())}',
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
            // Five boxes share the page width, so a large amount must scale
            // down rather than overflow its box.
            pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(value,
                  maxLines: 1,
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: valueColor ?? PdfColors.black)),
            ),
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
              child: pw.Text('Person'.tr,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 3,
              child: pw.Text('Source'.tr,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Date'.tr,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 1,
              child: pw.Text('Type'.tr,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Amount'.tr,
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
          pw.Text('$sign ${amountFmt.format(groupNet.abs())}'.tr,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: color)),
        ],
      ),
    );
  }

  static pw.Widget _row(LedgerEntry e, NumberFormat amountFmt) {
    final dateFmt = DateFormat('dd MMM yyyy'.tr);
    // Tagged business expenses get their own colour so they stand out from
    // ordinary day-book debits at a glance.
    final color = e.isBusinessExpense
        ? PdfColors.deepOrange700
        : (e.isDebit ? PdfColors.red : PdfColors.green800);
    final sign = e.isDebit ? '-' : '+';
    final name = e.title.isNotEmpty ? e.title : 'Entry'.tr;
    final source = e.isBusinessExpense
        ? 'Expense'.tr
        : (e.subtitle.isNotEmpty
            ? e.subtitle
            : (e.kind == LedgerEntryKind.expense ? 'Roj mel'.tr : ''));
    final typeLabel =
        e.isBusinessExpense ? 'Dr-E' : (e.isDebit ? 'Dr' : 'Cr');
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: e.isBusinessExpense ? PdfColors.deepOrange50 : null,
        border: const pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 4,
              child: pw.Text(name,
                  style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
              flex: 3,
              child: pw.Text(source,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: e.isBusinessExpense
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: e.isBusinessExpense
                          ? PdfColors.deepOrange700
                          : PdfColors.grey700))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(dateFmt.format(e.date),
                  style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(
              flex: 1,
              child: pw.Text(typeLabel,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: color))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('$sign ${amountFmt.format(e.amount)}'.tr,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 10, color: color))),
        ],
      ),
    );
  }

  static pw.Widget _totalFooter(
      double net, double expense, NumberFormat amountFmt) {
    final sign = net >= 0 ? '+' : '-';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('NET (Credits − Debits)'.tr,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12)),
              pw.Text('$sign ${amountFmt.format(net.abs())}'.tr,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ),
        if (expense > 0) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.deepOrange50,
              border: pw.Border.all(color: PdfColors.deepOrange700, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                      'Of which Business Expenses (Dr-E) — deducted from Net Profit'
                          .tr,
                      style: pw.TextStyle(
                          color: PdfColors.deepOrange700,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10)),
                ),
                pw.SizedBox(width: 8),
                pw.Text('- ${amountFmt.format(expense)}',
                    style: pw.TextStyle(
                        color: PdfColors.deepOrange700,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
