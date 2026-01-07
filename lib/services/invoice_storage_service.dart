import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';

class InvoiceStorageService {
  static const String _invoicesKey = 'saved_invoices';
  static final DatabaseReference _invoiceRef =
      FirebaseDatabase.instance.ref('invoices');

  static DatabaseReference _getUserInvoiceRef(String? uid) {
    if (uid != null) {
      return FirebaseDatabase.instance.ref('users/$uid/invoices');
    }
    return _invoiceRef;
  }

  static String _getLocalStorageKey(String? uid) {
    if (uid != null) {
      return '${_invoicesKey}_$uid';
    }
    return _invoicesKey;
  }

  /// Save invoice locally (SharedPreferences) and remotely (Firebase).
  static Future<void> saveInvoice(InvoiceModel invoice) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userInvoiceRef = _getUserInvoiceRef(uid);
    final storageKey = _getLocalStorageKey(uid);

    // ---------- LOCAL PERSISTENCE (existing behaviour) ----------
    final prefs = await SharedPreferences.getInstance();
    final invoices = await getAllInvoices();

    // Ensure invoice has an id
    invoice.id ??= DateTime.now().millisecondsSinceEpoch.toString();

    final existingIndex = invoices.indexWhere((inv) => inv.id == invoice.id);
    if (existingIndex != -1) {
      invoices[existingIndex] = invoice;
    } else {
      invoices.add(invoice);
    }

    final invoicesJson = invoices.map((inv) => inv.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(invoicesJson));

    // ---------- REMOTE PERSISTENCE (Firebase Realtime DB) ----------
    try {
      await userInvoiceRef.child(invoice.id!).set(invoice.toJson());
    } catch (_) {
      // Fail silently for now – local storage still works.
    }
  }

  /// Read invoices from Firebase if available, otherwise fall back to local.
  static Future<List<InvoiceModel>> getAllInvoices() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userInvoiceRef = _getUserInvoiceRef(uid);
    final storageKey = _getLocalStorageKey(uid);

    try {
      final snapshot = await userInvoiceRef.get();
      final List<InvoiceModel> remote = [];

      if (snapshot.value is Map) {
        final data = Map<String, dynamic>.from(
          snapshot.value as Map<Object?, Object?>,
        );
        data.forEach((key, value) {
          if (value is Map<Object?, Object?>) {
            final json = Map<String, dynamic>.from(value);
            json['id'] = key;
            remote.add(InvoiceModel.fromJson(json));
          }
        });
      }

      if (remote.isNotEmpty) {
        remote.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        // Keep local cache synced
        await _cacheInvoicesLocally(remote, storageKey);
        return remote;
      }
    } catch (e) {
      // If Firebase fails (permission denied, network error, etc.), fall back to local cache.
      // This is expected behavior - we silently fall back to local storage.
      // Only log if it's not a permission error (which is expected for unauthenticated users)
      if (e.toString().contains('Permission denied')) {
        // Expected - user may not have Firebase rules set up or not authenticated
        // Silently fall back to local
      } else {
        // Unexpected error - could log for debugging
        // print('Firebase read error: $e');
      }
    }

    // ---------- LOCAL FALLBACK ----------
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = prefs.getString(storageKey);

    if (invoicesJson == null || invoicesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(invoicesJson);
      return decoded
          .map((json) => InvoiceModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _cacheInvoicesLocally(
      List<InvoiceModel> invoices, String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = invoices.map((inv) => inv.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(invoicesJson));
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
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userInvoiceRef = _getUserInvoiceRef(uid);
    final storageKey = _getLocalStorageKey(uid);

    // Local delete
    final prefs = await SharedPreferences.getInstance();
    final invoices = await getAllInvoices();
    invoices.removeWhere((inv) => inv.id == id);
    final invoicesJson = invoices.map((inv) => inv.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(invoicesJson));

    // Remote delete
    try {
      await userInvoiceRef.child(id).remove();
    } catch (_) {
      // Ignore remote delete errors – local state is still consistent.
    }
  }
}

