// Field-name auto-detection for imported tabular data.
// Each importable model field has a list of synonyms. When a file's column
// header matches any synonym (case-insensitive, whitespace/punctuation
// stripped), the column is mapped to that field. Unknown columns are
// reported back so the caller can show them to the user.

class FieldSpec {
  final String key;
  final List<String> synonyms;
  const FieldSpec(this.key, this.synonyms);
}

class HeaderMapping {
  /// Original header → canonical field key.
  final Map<String, String> matched;
  /// Headers we couldn't map.
  final List<String> unmatched;
  /// Canonical fields the file is missing entirely.
  final List<String> missing;

  HeaderMapping(this.matched, this.unmatched, this.missing);
}

class HeaderMapper {
  // ── Purchase fields ─────────────────────────────────────────────────────
  static const List<FieldSpec> purchaseFields = [
    FieldSpec('totalAmount', [
      'total amount', 'totalamount', 'amount', 'total', 'net amount',
      'netamount', 'net', 'price', 'value', 'grand total', 'grandtotal',
    ]),
    FieldSpec('totalCarat', [
      'total carat', 'totalcarat', 'carat', 'carats', 'ct', 'cts',
      'weight', 'qty', 'quantity', 'wt',
    ]),
    FieldSpec('amountPerCarat', [
      'amount per carat', 'amountpercarat', 'rate per carat', 'rate/ct',
      'rate', 'per carat', 'unit price', 'unitprice', 'rate per ct',
      'price per carat',
    ]),
    FieldSpec('discount', [
      'discount', 'disc', 'discount %', 'discount percent',
      'discountrate', 'discount rate',
    ]),
    FieldSpec('dueDays', [
      'due days', 'dueday', 'due day', 'credit days', 'creditdays',
      'payment days', 'paymentdays',
    ]),
    FieldSpec('sellerName', [
      'seller', 'seller name', 'sellername', 'supplier', 'vendor',
      'from', 'party name', 'partyname', 'party',
    ]),
    FieldSpec('brokerName', [
      'broker', 'broker name', 'brokername', 'agent', 'agent name',
    ]),
    FieldSpec('brokerChargeRate', [
      'broker charge', 'brokercharge', 'broker rate', 'brokerrate',
      'brokerage', 'brokerage %', 'broker charge %', 'broker charge rate',
    ]),
    FieldSpec('size', [
      'size', 'sieve', 'sieve size', 'grade', 'category',
    ]),
    FieldSpec('sizeAlpha', [
      'size alpha', 'sizealpha', 'size letter', 'size code',
    ]),
    FieldSpec('sizeNumeric', [
      'size numeric', 'sizenumeric', 'size number', 'size num',
    ]),
    FieldSpec('buyDate', [
      'buy date', 'buydate', 'date', 'purchase date', 'purchasedate',
      'transaction date', 'txn date',
    ]),
    FieldSpec('paymentDate', [
      'payment date', 'paymentdate', 'pay date', 'paydate', 'due date',
      'duedate',
    ]),
    FieldSpec('paymentType', [
      'payment type', 'paymenttype', 'type', 'mode', 'payment mode',
      'paymode', 'pay mode',
    ]),
    FieldSpec('isForOther', [
      'is for other', 'for other', 'forother', 'is_for_other',
      'recordkeeping', 'record keeping',
    ]),
  ];

  // ── Invoice (sell) fields ───────────────────────────────────────────────
  static const List<FieldSpec> invoiceFields = [
    FieldSpec('invoiceNo', [
      'invoice no', 'invoiceno', 'invoice number', 'bill no', 'billno',
      'bill number', 'inv no', 'inv #',
    ]),
    FieldSpec('invoiceDate', [
      'invoice date', 'invoicedate', 'date', 'bill date', 'billdate',
      'sell date', 'selldate', 'transaction date',
    ]),
    FieldSpec('dueDate', [
      'due date', 'duedate', 'payment date', 'paymentdate',
    ]),
    FieldSpec('terms', [
      'terms', 'payment terms', 'paymentterms',
    ]),
    FieldSpec('buyerName', [
      'buyer', 'buyer name', 'buyername', 'customer', 'customer name',
      'to', 'party', 'party name', 'client', 'client name',
    ]),
    FieldSpec('buyerAddress', [
      'address', 'buyer address', 'buyeraddress', 'customer address',
    ]),
    FieldSpec('buyerGstNo', [
      'gst', 'gstin', 'gst no', 'gstno', 'buyer gst', 'buyergst',
      'gst number',
    ]),
    FieldSpec('buyerPanNo', [
      'pan', 'panno', 'pan no', 'pan number', 'buyer pan',
    ]),
    FieldSpec('buyerContactNo', [
      'phone', 'mobile', 'contact', 'contactno', 'contact no',
      'buyer contact', 'buyer phone', 'buyer mobile',
    ]),
    FieldSpec('buyerEmail', [
      'email', 'buyer email', 'buyeremail', 'customer email',
      'email id', 'emailid',
    ]),
    FieldSpec('buyerStateName', [
      'state', 'state name', 'statename', 'buyer state',
    ]),
    FieldSpec('buyerStateCode', [
      'state code', 'statecode', 'buyer state code',
    ]),
    FieldSpec('placeOfSupply', [
      'place of supply', 'placeofsupply', 'supply place',
    ]),
    // Single-line item fields (one row = one invoice with one item).
    FieldSpec('itemCarat', [
      'carat', 'carats', 'ct', 'cts', 'weight', 'wt', 'qty', 'quantity',
    ]),
    FieldSpec('itemRate', [
      'rate', 'rate per carat', 'rate/ct', 'price per carat', 'unit price',
      'per carat',
    ]),
    FieldSpec('itemAmount', [
      'amount', 'total', 'total amount', 'item amount', 'line total',
    ]),
    FieldSpec('itemParticular', [
      'particular', 'particulars', 'description', 'item', 'item name',
      'product',
    ]),
    FieldSpec('itemHsnCode', [
      'hsn', 'hsn code', 'hsncode', 'hsn no',
    ]),
    FieldSpec('cgstRate', [
      'cgst', 'cgst rate', 'cgst %', 'cgstrate',
    ]),
    FieldSpec('sgstRate', [
      'sgst', 'sgst rate', 'sgst %', 'sgstrate',
    ]),
    FieldSpec('igstRate', [
      'igst', 'igst rate', 'igst %', 'igstrate',
    ]),
    FieldSpec('isIgst', [
      'is igst', 'isigst', 'igst applicable',
    ]),
    FieldSpec('discountRate', [
      'discount', 'disc', 'discount %', 'discount rate', 'discountrate',
    ]),
    FieldSpec('brokerChargeRate', [
      'broker charge', 'brokercharge', 'broker rate', 'brokerage',
      'brokerage %',
    ]),
    FieldSpec('brokerName', [
      'broker', 'broker name', 'brokername', 'agent',
    ]),
    FieldSpec('isCashSell', [
      'cash sell', 'cashsell', 'is cash', 'iscash', 'cash',
    ]),
    FieldSpec('isForOther', [
      'is for other', 'for other', 'forother',
    ]),
  ];

  /// Normalise a header for comparison: lowercase, strip whitespace and
  /// punctuation. So "Buyer Name", "buyer_name", "BUYER-NAME" all collapse
  /// to "buyername".
  static String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_./\\():%#,]'), '')
        .trim();
  }

  /// Map raw headers from a file to canonical field keys.
  ///
  /// First pass: exact match (after normalisation).
  /// Second pass: if a header is a substring/superstring of a synonym, match.
  /// A header that already matched in pass 1 is not reconsidered.
  static HeaderMapping map(
    List<String> rawHeaders,
    List<FieldSpec> fields,
  ) {
    final matched = <String, String>{};
    final claimedFieldKeys = <String>{};
    final unmatched = <String>[];

    final normalizedHeaders = {
      for (final h in rawHeaders) h: _normalize(h),
    };

    // Pass 1: exact matches.
    for (final entry in normalizedHeaders.entries) {
      final raw = entry.key;
      final norm = entry.value;
      if (norm.isEmpty) continue;
      for (final f in fields) {
        if (claimedFieldKeys.contains(f.key)) continue;
        final matchesExact = f.synonyms.any((s) => _normalize(s) == norm);
        if (matchesExact) {
          matched[raw] = f.key;
          claimedFieldKeys.add(f.key);
          break;
        }
      }
    }

    // Pass 2: substring matches (only for headers still unmatched).
    for (final entry in normalizedHeaders.entries) {
      final raw = entry.key;
      if (matched.containsKey(raw)) continue;
      final norm = entry.value;
      if (norm.isEmpty) continue;
      for (final f in fields) {
        if (claimedFieldKeys.contains(f.key)) continue;
        final matchesSub = f.synonyms.any((s) {
          final sn = _normalize(s);
          return sn.contains(norm) || norm.contains(sn);
        });
        if (matchesSub) {
          matched[raw] = f.key;
          claimedFieldKeys.add(f.key);
          break;
        }
      }
    }

    for (final raw in rawHeaders) {
      if (!matched.containsKey(raw) && raw.trim().isNotEmpty) {
        unmatched.add(raw);
      }
    }

    final missing = fields
        .where((f) => !claimedFieldKeys.contains(f.key))
        .map((f) => f.key)
        .toList();

    return HeaderMapping(matched, unmatched, missing);
  }
}
