import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Normalised tabular data ready for the header-mapping layer.
class ParsedTable {
  final List<String> headers;
  final List<Map<String, String>> rows; // header → cell value

  ParsedTable({required this.headers, required this.rows});

  bool get isEmpty => rows.isEmpty;
}

class FormatParsers {
  /// Reads the first sheet of an .xlsx file and treats the first non-empty
  /// row as the header row. Empty rows below that are skipped.
  static Future<ParsedTable> parseExcel(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = xl.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return ParsedTable(headers: const [], rows: const []);
    }
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      return ParsedTable(headers: const [], rows: const []);
    }

    int headerRowIndex = -1;
    for (var i = 0; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.any((c) => _cellString(c?.value).trim().isNotEmpty)) {
        headerRowIndex = i;
        break;
      }
    }
    if (headerRowIndex == -1) {
      return ParsedTable(headers: const [], rows: const []);
    }

    final headers = sheet.rows[headerRowIndex]
        .map((c) => _cellString(c?.value).trim())
        .toList();

    final rows = <Map<String, String>>[];
    for (var i = headerRowIndex + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((c) => _cellString(c?.value).trim().isEmpty)) continue;
      final map = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        final h = headers[j];
        if (h.isEmpty) continue;
        final value = j < row.length ? _cellString(row[j]?.value) : '';
        map[h] = value.trim();
      }
      rows.add(map);
    }
    return ParsedTable(headers: headers, rows: rows);
  }

  /// Excel cells come back as typed objects (TextCellValue, IntCellValue,
  /// DoubleCellValue, DateCellValue, etc.). Render each to a plain string.
  /// TextCellValue wraps a TextSpan from the pdf package — we walk it via
  /// dynamic to avoid pulling in pdf's widget types here.
  static String _cellString(Object? value) {
    if (value == null) return '';
    if (value is xl.TextCellValue) return _spanToText(value.value);
    if (value is xl.IntCellValue) return value.value.toString();
    if (value is xl.DoubleCellValue) return value.value.toString();
    if (value is xl.BoolCellValue) return value.value.toString();
    if (value is xl.DateCellValue) {
      return DateTime(value.year, value.month, value.day).toIso8601String();
    }
    if (value is xl.DateTimeCellValue) {
      return DateTime(value.year, value.month, value.day, value.hour,
              value.minute, value.second)
          .toIso8601String();
    }
    if (value is xl.TimeCellValue) {
      return '${value.hour}:${value.minute}:${value.second}';
    }
    if (value is xl.FormulaCellValue) return value.formula;
    return value.toString();
  }

  static String _spanToText(dynamic span) {
    if (span == null) return '';
    try {
      final text = span.text as String?;
      final children = span.children as List?;
      final buffer = StringBuffer();
      if (text != null) buffer.write(text);
      if (children != null) {
        for (final c in children) {
          buffer.write(_spanToText(c));
        }
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  /// Parses a CSV file. The first non-empty row is treated as the header row.
  static Future<ParsedTable> parseCsv(String filePath) async {
    final raw = await File(filePath).readAsString();
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(raw.replaceAll('\r\n', '\n'));

    if (rows.isEmpty) return ParsedTable(headers: const [], rows: const []);

    int headerRowIndex = -1;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].any((c) => c.toString().trim().isNotEmpty)) {
        headerRowIndex = i;
        break;
      }
    }
    if (headerRowIndex == -1) {
      return ParsedTable(headers: const [], rows: const []);
    }

    final headers = rows[headerRowIndex]
        .map((c) => c.toString().trim())
        .toList();

    final dataRows = <Map<String, String>>[];
    for (var i = headerRowIndex + 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.every((c) => c.toString().trim().isEmpty)) continue;
      final map = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        final h = headers[j];
        if (h.isEmpty) continue;
        final value = j < r.length ? r[j].toString() : '';
        map[h] = value.trim();
      }
      dataRows.add(map);
    }
    return ParsedTable(headers: headers, rows: dataRows);
  }

  /// Parses JSON. Supports two shapes:
  /// - Top-level array of row objects: `[{"col1": "v", "col2": "v"}, ...]`
  /// - Backup wrapper: `{"invoices": [...]}` or `{"purchases": [...]}` —
  ///   each list item should be a map of fieldKey → value.
  static Future<ParsedTable> parseJson(String filePath) async {
    final raw = await File(filePath).readAsString();
    final decoded = jsonDecode(raw);

    List? items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      // Try common keys, including the localised forms used by the existing
      // export service ("invoices" / "purchases").
      for (final key in ['rows', 'data', 'invoices', 'purchases', 'items']) {
        if (decoded[key] is List) {
          items = decoded[key] as List;
          break;
        }
      }
    }
    if (items == null || items.isEmpty) {
      return ParsedTable(headers: const [], rows: const []);
    }

    // Collect the union of all keys across rows so heterogeneous JSON still
    // produces a complete header set.
    final headerSet = <String>{};
    final rows = <Map<String, String>>[];
    for (final item in items) {
      if (item is Map) {
        final row = <String, String>{};
        item.forEach((k, v) {
          final key = k.toString();
          headerSet.add(key);
          row[key] = v == null ? '' : v.toString();
        });
        rows.add(row);
      }
    }
    return ParsedTable(headers: headerSet.toList(), rows: rows);
  }

  /// Best-effort PDF table extraction. Works well for PDFs with a clear
  /// header row above space-separated columns (such as PDFs the app itself
  /// generates). Arbitrary supplier PDFs may not parse cleanly — that is a
  /// known limitation of plain-text PDF extraction.
  static Future<ParsedTable> parsePdf(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final allText = extractor.extractText();
      return _tableFromPlainText(allText);
    } finally {
      document.dispose();
    }
  }

  /// Splits raw text into rows + cells using whitespace as a column
  /// delimiter. Looks for a header line that contains at least one
  /// recognisable header keyword and treats subsequent non-blank lines as
  /// data rows.
  static ParsedTable _tableFromPlainText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.replaceAll('\t', '   ').trimRight())
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return ParsedTable(headers: const [], rows: const []);

    const headerHints = [
      'name', 'date', 'amount', 'carat', 'rate', 'discount', 'broker',
      'seller', 'buyer', 'invoice', 'gst', 'qty', 'item', 'description',
      'particular', 'total', 'price',
    ];

    int headerIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      final hits = headerHints.where((h) => lower.contains(h)).length;
      if (hits >= 2) {
        headerIdx = i;
        break;
      }
    }
    if (headerIdx == -1) {
      return ParsedTable(headers: const [], rows: const []);
    }

    final headers = _splitCells(lines[headerIdx]);
    final rows = <Map<String, String>>[];
    for (var i = headerIdx + 1; i < lines.length; i++) {
      final cells = _splitCells(lines[i]);
      // Heuristic: a real data row usually has at least half as many cells
      // as the header. Skip stray paragraph lines.
      if (cells.length < (headers.length / 2).ceil()) continue;
      final map = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        final h = headers[j].trim();
        if (h.isEmpty) continue;
        map[h] = j < cells.length ? cells[j].trim() : '';
      }
      rows.add(map);
    }
    return ParsedTable(headers: headers, rows: rows);
  }

  /// Split on runs of 2+ spaces, tabs, or `|`. This works for PDFs whose
  /// table cells are visually separated by gaps wider than a single space.
  static List<String> _splitCells(String line) {
    return line
        .split(RegExp(r'(\s{2,}|\t+|\|)'))
        .where((c) => c.trim().isNotEmpty)
        .toList();
  }
}
