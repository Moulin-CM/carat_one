import 'package:intl/intl.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import '../viewmodels/brokerage_report_data.dart';
import 'pdf_service.dart';


class BrokerageReportPdfService {
  static Future<pw.Document> build({
    required List<BrokerAggregate> brokers,
    required String periodLabel,
    required DateTime start,
    required DateTime end,
  }) async {
    final theme = await PdfService.buildUnicodeTheme();
    final doc = theme != null ? pw.Document(theme: theme) : pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy'.tr);
    final amountFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final caratFmt = NumberFormat('#,##0.00');

    final grandCharge =
        brokers.fold<double>(0, (s, b) => s + b.totalCharge);
    final grandEntries =
        brokers.fold<int>(0, (s, b) => s + b.entries.length);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(periodLabel, dateFmt, start, end),
          pw.SizedBox(height: 14),
          _summary(brokers.length, grandEntries, grandCharge, amountFmt),
          pw.SizedBox(height: 14),
          if (brokers.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              child: pw.Text('No brokerage entries in this period'.tr,
                  style: const pw.TextStyle(color: PdfColors.grey700)),
            )
          else
            ...brokers.map((b) =>
                _brokerBlock(b, dateFmt, amountFmt, caratFmt)),
          pw.SizedBox(height: 10),
          _grandFooter(grandCharge, amountFmt),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _header(String periodLabel, DateFormat dateFmt,
      DateTime start, DateTime end) {
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
              pw.Text('Brokerage Report'.tr,
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

  static pw.Widget _summary(int brokerCount, int entryCount,
      double totalCharge, NumberFormat amountFmt) {
    pw.Widget box(String label, String value, {PdfColor? color}) {
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
                      color: color ?? PdfColors.black)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        box('Brokers'.tr, brokerCount.toString()),
        pw.SizedBox(width: 8),
        box('Entries'.tr, entryCount.toString()),
        pw.SizedBox(width: 8),
        box('Total Brokerage'.tr, amountFmt.format(totalCharge),
            color: PdfColors.blue900),
      ],
    );
  }

  static pw.Widget _brokerBlock(BrokerAggregate b, DateFormat dateFmt,
      NumberFormat amountFmt, NumberFormat caratFmt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: PdfColors.blue50,
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    b.name,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.blue900),
                  ),
                ),
                pw.Text('${b.entries.length} entries'.tr,
                    style: const pw.TextStyle(
                        color: PdfColors.grey700, fontSize: 9)),
                pw.SizedBox(width: 10),
                pw.Text(amountFmt.format(b.totalCharge),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        fontSize: 12)),
              ],
            ),
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: PdfColors.grey200,
            child: pw.Row(
              children: [
                _col('Side'.tr, 1),
                _col('Date'.tr, 2),
                _col('Person'.tr, 3),
                _col('Item'.tr, 2),
                _col('Carat'.tr, 2, right: true),
                _col('Charge'.tr, 2, right: true),
              ],
            ),
          ),
          ...b.entries.map((e) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Row(
                  children: [
                    _cell(e.side == BrokerSide.buy ? 'Buy'.tr : 'Sell'.tr, 1,
                        color: e.side == BrokerSide.buy
                            ? PdfColors.orange800
                            : PdfColors.green800),
                    _cell(dateFmt.format(e.date), 2),
                    _cell(e.personName.isNotEmpty ? e.personName : '-', 3),
                    _cell(e.itemLabel.isNotEmpty ? e.itemLabel : '-', 2),
                    _cell('${caratFmt.format(e.carat)} ct', 2, right: true),
                    _cell(amountFmt.format(e.charge), 2, right: true),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _col(String label, int flex, {bool right = false}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        label,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static pw.Widget _cell(String text, int flex,
      {bool right = false, PdfColor? color}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
            fontSize: 9,
            color: color ?? PdfColors.black,
            fontWeight:
                color != null ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _grandFooter(
      double totalCharge, NumberFormat amountFmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL BROKERAGE'.tr,
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
          pw.Text(amountFmt.format(totalCharge),
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
