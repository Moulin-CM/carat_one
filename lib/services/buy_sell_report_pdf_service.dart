import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

import 'package:invoice_generator/constants/app_translations.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import 'pdf_service.dart';


class BuySellReportPdfService {
  static Future<pw.Document> build({
    required List<PurchaseModel> purchases,
    required List<InvoiceModel> sells,
    required String periodLabel,
    required DateTime start,
    required DateTime end,
  }) async {
    final theme = await PdfService.buildUnicodeTheme();
    final doc = theme != null ? pw.Document(theme: theme) : pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy'.tr);
    final amountFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final caratFmt = NumberFormat('#,##0.00');

    final totalBuyCarat =
        purchases.fold<double>(0, (s, p) => s + p.totalCarat);
    final totalBuyAmount =
        purchases.fold<double>(0, (s, p) => s + p.netAmount);
    final totalSellCarat =
        sells.fold<double>(0, (s, i) => s + i.totalCarat);
    final totalSellAmount =
        sells.fold<double>(0, (s, i) => s + i.grandTotal);
    final netDelta = totalSellAmount - totalBuyAmount;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(periodLabel, dateFmt, start, end),
          pw.SizedBox(height: 14),
          _summary(
            amountFmt: amountFmt,
            caratFmt: caratFmt,
            buyCount: purchases.length,
            buyCarat: totalBuyCarat,
            buyAmount: totalBuyAmount,
            sellCount: sells.length,
            sellCarat: totalSellCarat,
            sellAmount: totalSellAmount,
            netDelta: netDelta,
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('Buy Entries (${purchases.length})'),
          _buyHeader(),
          if (purchases.isEmpty)
            _emptyRow('No purchases in this period'.tr)
          else
            ...purchases.map((p) => _buyRow(p, dateFmt, amountFmt, caratFmt)),
          _subtotalRow(
              'Total Buy'.tr,
              '${caratFmt.format(totalBuyCarat)} ct',
              amountFmt.format(totalBuyAmount),
              PdfColors.orange800),
          pw.SizedBox(height: 16),
          _sectionTitle('Sell Entries (${sells.length})'),
          _sellHeader(),
          if (sells.isEmpty)
            _emptyRow('No sells in this period'.tr)
          else
            ...sells.map((i) => _sellRow(i, dateFmt, amountFmt, caratFmt)),
          _subtotalRow(
              'Total Sell'.tr,
              '${caratFmt.format(totalSellCarat)} ct',
              amountFmt.format(totalSellAmount),
              PdfColors.green800),
          pw.SizedBox(height: 14),
          _netFooter(netDelta, amountFmt),
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
              pw.Text('Buy / Sell Report'.tr,
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

  static pw.Widget _summary({
    required NumberFormat amountFmt,
    required NumberFormat caratFmt,
    required int buyCount,
    required double buyCarat,
    required double buyAmount,
    required int sellCount,
    required double sellCarat,
    required double sellAmount,
    required double netDelta,
  }) {
    pw.Widget box(String title, String count, String carat, String amount,
        PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      color: color,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text(count,
                  style: const pw.TextStyle(
                      color: PdfColors.grey700, fontSize: 9)),
              pw.Text(carat,
                  style: const pw.TextStyle(
                      color: PdfColors.grey800, fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Text(amount,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        box(
          'BUY'.tr,
          '$buyCount ${buyCount == 1 ? 'entry'.tr : 'entries'.tr}',
          '${caratFmt.format(buyCarat)} ct',
          amountFmt.format(buyAmount),
          PdfColors.orange800,
        ),
        pw.SizedBox(width: 8),
        box(
          'SELL'.tr,
          '$sellCount ${sellCount == 1 ? 'entry'.tr : 'entries'.tr}',
          '${caratFmt.format(sellCarat)} ct',
          amountFmt.format(sellAmount),
          PdfColors.green800,
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: netDelta >= 0 ? PdfColors.green50 : PdfColors.red50,
              border: pw.Border.all(
                  color:
                      netDelta >= 0 ? PdfColors.green800 : PdfColors.red800),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('NET (Sell − Buy)'.tr,
                    style: pw.TextStyle(
                        color: netDelta >= 0
                            ? PdfColors.green800
                            : PdfColors.red800,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11)),
                pw.SizedBox(height: 16),
                pw.Text(
                  '${netDelta >= 0 ? '+' : '-'} ${amountFmt.format(netDelta.abs())}',
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: netDelta >= 0
                          ? PdfColors.green800
                          : PdfColors.red800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
              color: PdfColors.blue900,
              fontWeight: pw.FontWeight.bold,
              fontSize: 13)),
    );
  }

  static pw.Widget _buyHeader() {
    return _tableHeaderRow([
      _Col('Date'.tr, 2),
      _Col('Seller'.tr, 3),
      _Col('Size'.tr, 1),
      _Col('Carat'.tr, 2, right: true),
      _Col('Rate'.tr, 2, right: true),
      _Col('Amount'.tr, 2, right: true),
    ]);
  }

  static pw.Widget _sellHeader() {
    return _tableHeaderRow([
      _Col('Date'.tr, 2),
      _Col('No', 2),
      _Col('Buyer'.tr, 3),
      _Col('Mode'.tr, 1),
      _Col('Carat'.tr, 2, right: true),
      _Col('Amount'.tr, 2, right: true),
    ]);
  }

  static pw.Widget _tableHeaderRow(List<_Col> cols) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      color: PdfColors.grey200,
      child: pw.Row(
        children: cols
            .map((c) => pw.Expanded(
                  flex: c.flex,
                  child: pw.Text(
                    c.label,
                    textAlign: c.right
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                  ),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _buyRow(PurchaseModel p, DateFormat dateFmt,
      NumberFormat amountFmt, NumberFormat caratFmt) {
    return _bodyRow([
      _Cell(dateFmt.format(p.buyDate), 2),
      _Cell(p.sellerName.isNotEmpty ? p.sellerName : '-', 3),
      _Cell(p.size.isNotEmpty ? p.size : '-', 1),
      _Cell('${caratFmt.format(p.totalCarat)} ct', 2, right: true),
      _Cell(amountFmt.format(p.amountPerCarat), 2, right: true),
      _Cell(amountFmt.format(p.netAmount), 2, right: true),
    ]);
  }

  static pw.Widget _sellRow(InvoiceModel i, DateFormat dateFmt,
      NumberFormat amountFmt, NumberFormat caratFmt) {
    return _bodyRow([
      _Cell(dateFmt.format(i.invoiceDate), 2),
      _Cell(i.invoiceNo.isNotEmpty ? i.invoiceNo : '-', 2),
      _Cell(i.buyerName.isNotEmpty ? i.buyerName : '-', 3),
      _Cell(i.isCashSell ? 'Cash'.tr : 'Bill'.tr, 1),
      _Cell('${caratFmt.format(i.totalCarat)} ct', 2, right: true),
      _Cell(amountFmt.format(i.grandTotal), 2, right: true),
    ]);
  }

  static pw.Widget _bodyRow(List<_Cell> cells) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: cells
            .map((c) => pw.Expanded(
                  flex: c.flex,
                  child: pw.Text(
                    c.text,
                    textAlign: c.right
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _emptyRow(String text) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(text,
          style: const pw.TextStyle(
              color: PdfColors.grey600, fontSize: 10)),
    );
  }

  static pw.Widget _subtotalRow(
      String label, String carat, String amount, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(top: pw.BorderSide(color: color, width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 6,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                      fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text(carat,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(flex: 2, child: pw.SizedBox()),
          pw.Expanded(
              flex: 2,
              child: pw.Text(amount,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: color))),
        ],
      ),
    );
  }

  static pw.Widget _netFooter(double net, NumberFormat amountFmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('NET (Sell − Buy)'.tr,
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
          pw.Text(
            '${net >= 0 ? '+' : '-'} ${amountFmt.format(net.abs())}',
            style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Col {
  final String label;
  final int flex;
  final bool right;
  const _Col(this.label, this.flex, {this.right = false});
}

class _Cell {
  final String text;
  final int flex;
  final bool right;
  const _Cell(this.text, this.flex, {this.right = false});
}
