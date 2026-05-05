import 'stock_valuation_item.dart';

class AppSettingsModel {
  // Tax Rates
  double cgstRate = 0.75;
  double sgstRate = 0.75;
  double igstRate = 1.5;

  // Invoice Numbering
  String invoiceNumberPrefix = '';
  int startingInvoiceNumber = 1;
  String invoiceNumberFormat = '{prefix}{number}'; // {prefix}{number} or {number} or custom

  // Default Invoice Terms
  String defaultTerms = '';

  // App Preferences
  bool enableNotifications = true;
  bool autoSaveDraft = true;

  // Financial Year settings. `yearEndDate` marks the last day of the current
  // financial year. The new year starts automatically on the day after.
  // When null, no year filtering is applied (lifetime totals are used).
  DateTime? yearEndDate;

  // Manual carry-forward values that the user can enter by tapping the
  // Opening Carat / Opening Amount cards on the Purchase and Invoice tabs.
  double manualOpeningCarat = 0.0;
  double manualOpeningAmount = 0.0;
  double manualOpeningSellCarat = 0.0;
  double manualOpeningSellAmount = 0.0;

  // Expense Opening values
  double manualOpeningExpenseAmount = 0.0;

  // Stock valuation — user-defined breakdown of the remaining unsold
  // carats into named items with a per-carat rate. Used to show the
  // estimated worth of the current stock on the Purchase summary bar.
  List<StockValuationItem> stockValuationItems = [];

  AppSettingsModel();

  AppSettingsModel.fromJson(Map<String, dynamic> json)
      : cgstRate = (json['cgstRate'] ?? 0.75).toDouble(),
        sgstRate = (json['sgstRate'] ?? 0.75).toDouble(),
        igstRate = (json['igstRate'] ?? 1.5).toDouble(),
        invoiceNumberPrefix = json['invoiceNumberPrefix'] ?? '',
        startingInvoiceNumber = json['startingInvoiceNumber'] ?? 1,
        invoiceNumberFormat = json['invoiceNumberFormat'] ?? '{prefix}{number}',
        defaultTerms = json['defaultTerms'] ?? '',
        enableNotifications = json['enableNotifications'] ?? true,
        autoSaveDraft = json['autoSaveDraft'] ?? true,
        yearEndDate = _parseDate(json['yearEndDate']),
        manualOpeningCarat = (json['manualOpeningCarat'] ?? 0.0).toDouble(),
        manualOpeningAmount = (json['manualOpeningAmount'] ?? 0.0).toDouble(),
        manualOpeningSellCarat =
            (json['manualOpeningSellCarat'] ?? 0.0).toDouble(),
        manualOpeningSellAmount =
            (json['manualOpeningSellAmount'] ?? 0.0).toDouble(),
        manualOpeningExpenseAmount =
            (json['manualOpeningExpenseAmount'] ?? 0.0).toDouble(),
        stockValuationItems = _parseStockValuationItems(
            json['stockValuationItems']);

  static List<StockValuationItem> _parseStockValuationItems(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => StockValuationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is DateTime) return raw;
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is String && raw.isNotEmpty) return DateTime.parse(raw);
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() => {
        'cgstRate': cgstRate,
        'sgstRate': sgstRate,
        'igstRate': igstRate,
        'invoiceNumberPrefix': invoiceNumberPrefix,
        'startingInvoiceNumber': startingInvoiceNumber,
        'invoiceNumberFormat': invoiceNumberFormat,
        'defaultTerms': defaultTerms,
        'enableNotifications': enableNotifications,
        'autoSaveDraft': autoSaveDraft,
        'yearEndDate': yearEndDate?.toIso8601String(),
        'manualOpeningCarat': manualOpeningCarat,
        'manualOpeningAmount': manualOpeningAmount,
        'manualOpeningSellCarat': manualOpeningSellCarat,
        'manualOpeningSellAmount': manualOpeningSellAmount,
        'manualOpeningExpenseAmount': manualOpeningExpenseAmount,
        'stockValuationItems':
            stockValuationItems.map((e) => e.toJson()).toList(),
      };

  AppSettingsModel copyWith({
    double? cgstRate,
    double? sgstRate,
    double? igstRate,
    String? invoiceNumberPrefix,
    int? startingInvoiceNumber,
    String? invoiceNumberFormat,
    String? defaultTerms,
    bool? enableNotifications,
    bool? autoSaveDraft,
    DateTime? yearEndDate,
    bool clearYearEndDate = false,
    double? manualOpeningCarat,
    double? manualOpeningAmount,
    double? manualOpeningSellCarat,
    double? manualOpeningSellAmount,
    double? manualOpeningExpenseAmount,
    List<StockValuationItem>? stockValuationItems,
  }) {
    return AppSettingsModel()
      ..cgstRate = cgstRate ?? this.cgstRate
      ..sgstRate = sgstRate ?? this.sgstRate
      ..igstRate = igstRate ?? this.igstRate
      ..invoiceNumberPrefix = invoiceNumberPrefix ?? this.invoiceNumberPrefix
      ..startingInvoiceNumber = startingInvoiceNumber ?? this.startingInvoiceNumber
      ..invoiceNumberFormat = invoiceNumberFormat ?? this.invoiceNumberFormat
      ..defaultTerms = defaultTerms ?? this.defaultTerms
      ..enableNotifications = enableNotifications ?? this.enableNotifications
      ..autoSaveDraft = autoSaveDraft ?? this.autoSaveDraft
      ..yearEndDate =
          clearYearEndDate ? null : (yearEndDate ?? this.yearEndDate)
      ..manualOpeningCarat = manualOpeningCarat ?? this.manualOpeningCarat
      ..manualOpeningAmount = manualOpeningAmount ?? this.manualOpeningAmount
      ..manualOpeningSellCarat =
          manualOpeningSellCarat ?? this.manualOpeningSellCarat
      ..manualOpeningSellAmount =
          manualOpeningSellAmount ?? this.manualOpeningSellAmount
      ..manualOpeningExpenseAmount =
          manualOpeningExpenseAmount ?? this.manualOpeningExpenseAmount
      ..stockValuationItems =
          stockValuationItems ?? List.of(this.stockValuationItems);
  }

  /// Beginning of the current financial year. Returns null when
  /// [yearEndDate] is not configured. The returned value is midnight on the
  /// first day of the active year (i.e. day after the most recently elapsed
  /// year-end anniversary).
  DateTime? currentYearStart({DateTime? now}) {
    final end = yearEndDate;
    if (end == null) return null;
    final today = now ?? DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    // Year-end anniversary in the current calendar year.
    DateTime anniversary = DateTime(today.year, end.month, end.day);
    if (anniversary.isBefore(todayMidnight) ||
        anniversary.isAtSameMomentAs(todayMidnight)) {
      // Anniversary has already passed (or is today) → year started the
      // day after.
      return anniversary.add(const Duration(days: 1));
    }
    // Anniversary still ahead this calendar year → year started after the
    // previous anniversary.
    final previous = DateTime(today.year - 1, end.month, end.day);
    return previous.add(const Duration(days: 1));
  }
}
