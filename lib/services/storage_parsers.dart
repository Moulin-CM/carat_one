// Top-level parsing helpers used with `compute()` (or `Isolate.run`) so the
// JSON-decode + model-construction work for invoices/purchases/withdrawals
// runs on a background isolate instead of stalling the UI thread on cold
// dashboard loads.
//
// `compute()` requires a top-level or static function reference, hence this
// file. Each helper accepts a single payload (a JSON string) and returns a
// fully built `List<XModel>` ready for the view-model to consume.
//
// Web note: `compute()` falls back to the same isolate on web (web has no
// real isolates), so these still run synchronously there. The mobile
// platforms — where the perceived jank actually happens — get the full
// off-thread benefit.

import 'dart:convert';

import '../models/invoice_model.dart';
import '../models/purchase_model.dart';
import '../models/withdrawal_model.dart';


// ─── Invoice ──────────────────────────────────────────────────────────────

/// Parse an invoice list from the local-cache JSON string.
/// Accepts the array shape used by SharedPreferences caches.
List<InvoiceModel> parseInvoiceListJson(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final result = <InvoiceModel>[];
    for (final entry in decoded) {
      if (entry is Map) {
        try {
          result.add(InvoiceModel.fromJson(Map<String, dynamic>.from(entry)));
        } catch (_) {
          // Skip malformed entries — one bad row shouldn't take the rest down.
        }
      }
    }
    result.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return result;
  } catch (_) {
    return const [];
  }
}

/// Parse the Firebase-shaped invoice map (keyed by invoice id) from a JSON
/// string. The caller is expected to have already serialised the
/// snapshot value to JSON on the calling thread (a single fast pass).
List<InvoiceModel> parseInvoiceMapJson(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final result = <InvoiceModel>[];
    decoded.forEach((key, value) {
      if (value is Map) {
        final m = Map<String, dynamic>.from(value);
        m['id'] = key.toString();
        try {
          result.add(InvoiceModel.fromJson(m));
        } catch (_) {
          // Skip malformed rows.
        }
      }
    });
    result.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return result;
  } catch (_) {
    return const [];
  }
}

// ─── Purchase ─────────────────────────────────────────────────────────────

List<PurchaseModel> parsePurchaseListJson(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final result = <PurchaseModel>[];
    for (final entry in decoded) {
      if (entry is Map) {
        try {
          result.add(PurchaseModel.fromJson(Map<String, dynamic>.from(entry)));
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return result;
  } catch (_) {
    return const [];
  }
}

List<PurchaseModel> parsePurchaseMapJson(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final result = <PurchaseModel>[];
    decoded.forEach((key, value) {
      if (value is Map) {
        final m = Map<String, dynamic>.from(value);
        m['id'] = key.toString();
        try {
          result.add(PurchaseModel.fromJson(m));
        } catch (_) {}
      }
    });
    result.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return result;
  } catch (_) {
    return const [];
  }
}

// ─── Withdrawal ───────────────────────────────────────────────────────────

List<WithdrawalModel> parseWithdrawalListJson(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final result = <WithdrawalModel>[];
    for (final entry in decoded) {
      if (entry is Map) {
        try {
          result.add(WithdrawalModel.fromJson(Map<String, dynamic>.from(entry)));
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.takenDate.compareTo(a.takenDate));
    return result;
  } catch (_) {
    return const [];
  }
}

List<WithdrawalModel> parseWithdrawalMapJson(String raw) {
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final result = <WithdrawalModel>[];
    decoded.forEach((key, value) {
      if (value is Map) {
        final m = Map<String, dynamic>.from(value);
        m['id'] = key.toString();
        try {
          result.add(WithdrawalModel.fromJson(m));
        } catch (_) {}
      }
    });
    result.sort((a, b) => b.takenDate.compareTo(a.takenDate));
    return result;
  } catch (_) {
    return const [];
  }
}
