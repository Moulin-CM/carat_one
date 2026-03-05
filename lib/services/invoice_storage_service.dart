import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';

class InvoiceStorageService {
  static const String _invoicesKey = 'saved_invoices';

  static DatabaseReference _getUserInvoiceRef(String uid) {
    return FirebaseDatabase.instance.ref('users/$uid/invoices');
  }

  static String _getLocalStorageKey(String uid) {
    return '${_invoicesKey}_$uid';
  }

  // ─── Auth helper ──────────────────────────────────────────────────────────

  static Future<User?> _getUser() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current;
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .where((u) => u != null)
          .first
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  // ─── Deep conversion helper ───────────────────────────────────────────────

  /// Recursively converts any Map<Object?, Object?> (returned by Firebase web)
  /// into a fully typed Map<String, dynamic> so fromJson() works on all platforms.
  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
              (e) => MapEntry(e.key.toString(), _deepConvert(e.value)),
        ),
      );
    }
    if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  static Future<void> saveInvoice(InvoiceModel invoice) async {
    final user = await _getUser();
    if (user == null) throw StateError('InvoiceStorageService: user is not logged in.');

    final uid = user.uid;
    final storageKey = _getLocalStorageKey(uid);

    final prefs = await SharedPreferences.getInstance();
    final invoices = await getAllInvoices();
    final existingIndex = invoices.indexWhere((inv) => inv.id == invoice.id);
    if (existingIndex != -1) {
      invoices[existingIndex] = invoice;
    } else {
      invoices.add(invoice);
    }
    await prefs.setString(
        storageKey, jsonEncode(invoices.map((inv) => inv.toJson()).toList()));

    try {
      await _getUserInvoiceRef(uid).child(invoice.id).set(invoice.toJson());
    } catch (e) {
      print('[InvoiceStorage] Remote save failed: $e');
    }
  }

  static Future<List<InvoiceModel>> getAllInvoices() async {
    final user = await _getUser();
    if (user == null) {
      print('[InvoiceStorage] getAllInvoices: no authenticated user, returning []');
      return [];
    }

    final uid = user.uid;
    final storageKey = _getLocalStorageKey(uid);

    try {
      print('[InvoiceStorage] Fetching from Firebase for uid: $uid');
      final snapshot = await _getUserInvoiceRef(uid).get();
      final List<InvoiceModel> remote = _parseSnapshot(snapshot);
      print('[InvoiceStorage] Firebase returned ${remote.length} invoices');

      if (remote.isNotEmpty) {
        remote.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        await _cacheLocally(remote, storageKey);
        return remote;
      }

      final cached = await _readLocalCache(storageKey);
      if (cached.isNotEmpty) {
        print('[InvoiceStorage] Migrating ${cached.length} local invoices to Firebase');
        await _migrateLocalToFirebase(uid, cached);
      }
      return cached;
    } catch (e) {
      print('[InvoiceStorage] Firebase read failed ($e), falling back to local cache');
      return _readLocalCache(storageKey);
    }
  }

  static Future<InvoiceModel?> getInvoiceById(String id) async {
    final invoices = await getAllInvoices();
    try {
      return invoices.firstWhere((inv) => inv.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteInvoice(String id) async {
    final user = await _getUser();
    if (user == null) throw StateError('InvoiceStorageService: user is not logged in.');

    final uid = user.uid;
    final storageKey = _getLocalStorageKey(uid);

    final prefs = await SharedPreferences.getInstance();
    final invoices = await getAllInvoices();
    invoices.removeWhere((inv) => inv.id == id);
    await prefs.setString(
        storageKey, jsonEncode(invoices.map((inv) => inv.toJson()).toList()));

    try {
      await _getUserInvoiceRef(uid).child(id).remove();
    } catch (e) {
      print('[InvoiceStorage] Remote delete failed: $e');
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static List<InvoiceModel> _parseSnapshot(DataSnapshot snapshot) {
    if (snapshot.value == null) return [];

    // _deepConvert handles the difference between mobile (LinkedHashMap) and
    // web (Map<Object?, Object?> with nested dynamic maps) Firebase responses.
    final converted = _deepConvert(snapshot.value);

    if (converted is! Map<String, dynamic>) {
      print('[InvoiceStorage] Unexpected snapshot type: ${snapshot.value.runtimeType}');
      return [];
    }

    final List<InvoiceModel> result = [];
    converted.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        try {
          value['id'] = key;
          result.add(InvoiceModel.fromJson(value));
        } catch (e) {
          print('[InvoiceStorage] Failed to parse invoice $key: $e');
        }
      }
    });

    print('[InvoiceStorage] Parsed ${result.length} invoices from snapshot');
    return result;
  }

  static Future<List<InvoiceModel>> _readLocalCache(String storageKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((json) => InvoiceModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _cacheLocally(
      List<InvoiceModel> invoices, String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        storageKey, jsonEncode(invoices.map((inv) => inv.toJson()).toList()));
  }

  static Future<void> _migrateLocalToFirebase(
      String uid, List<InvoiceModel> invoices) async {
    try {
      final Map<String, dynamic> updates = {};
      for (final inv in invoices) {
        updates[inv.id] = inv.toJson();
      }
      await _getUserInvoiceRef(uid).update(updates);
      print('[InvoiceStorage] Migration complete: ${invoices.length} invoices uploaded');
    } catch (e) {
      print('[InvoiceStorage] Migration failed: $e');
    }
  }
}