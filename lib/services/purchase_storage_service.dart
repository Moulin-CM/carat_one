import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_model.dart';

class PurchaseStorageService {
  static const String _key = 'saved_purchases';

  static DatabaseReference _getUserRef(String uid) =>
      FirebaseDatabase.instance.ref('users/$uid/purchases');

  static String _localKey(String uid) => '${_key}_$uid';

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

  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
      );
    }
    if (value is List) return value.map(_deepConvert).toList();
    return value;
  }

  static Future<void> savePurchase(PurchaseModel item) async {
    final user = await _getUser();
    if (user == null) throw StateError('Not logged in');
    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllPurchases();
    final idx = all.indexWhere((p) => p.id == item.id);
    if (idx != -1) {
      all[idx] = item;
    } else {
      all.add(item);
    }
    await prefs.setString(_localKey(uid), jsonEncode(all.map((p) => p.toJson()).toList()));
    try {
      await _getUserRef(uid).child(item.id).set(item.toJson());
    } catch (_) {}
  }

  static Future<List<PurchaseModel>> getAllPurchases() async {
    final user = await _getUser();
    if (user == null) return [];
    final uid = user.uid;
    try {
      final snapshot = await _getUserRef(uid).get();
      if (snapshot.value != null) {
        final List<PurchaseModel> remote = [];
        final data = _deepConvert(snapshot.value);
        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              value['id'] = key;
              remote.add(PurchaseModel.fromJson(value));
            }
          });
        }
        if (remote.isNotEmpty) {
          remote.sort((a, b) => b.addedDate.compareTo(a.addedDate));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_localKey(uid), jsonEncode(remote.map((p) => p.toJson()).toList()));
          return remote;
        }
      }
    } catch (_) {}
    // Fall back to local
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey(uid));
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        final local = list.map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>)).toList();
        local.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        return local;
      }
    } catch (_) {}
    return [];
  }

  static Future<void> deletePurchase(String id) async {
    final user = await _getUser();
    if (user == null) return;
    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllPurchases();
    all.removeWhere((p) => p.id == id);
    await prefs.setString(_localKey(uid), jsonEncode(all.map((p) => p.toJson()).toList()));
    try {
      await _getUserRef(uid).child(id).remove();
    } catch (_) {}
  }

  static Future<PurchaseModel?> getPurchaseById(String id) async {
    final all = await getAllPurchases();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Update sold carats and amounts when a new invoice is created/updated/deleted
  static Future<void> updateSoldCarats({
    required String purchaseId,
    required double cashDelta,
    required double billDelta,
    double cashAmountDelta = 0.0,
    double billAmountDelta = 0.0,
  }) async {
    final item = await getPurchaseById(purchaseId);
    if (item == null) return;
    item.cashSoldCarat = (item.cashSoldCarat + cashDelta).clamp(0.0, double.infinity);
    item.billSoldCarat = (item.billSoldCarat + billDelta).clamp(0.0, double.infinity);
    item.cashSoldAmount = (item.cashSoldAmount + cashAmountDelta).clamp(0.0, double.infinity);
    item.billSoldAmount = (item.billSoldAmount + billAmountDelta).clamp(0.0, double.infinity);
    await savePurchase(item);
  }

  /// Apply or revert a sale across available purchases.
  ///
  /// Positive [totalCarat]/[totalAmount] deduct from stock using FIFO
  /// (oldest purchase first). Negative values restore stock using LIFO
  /// (most-recent purchase first) so the original deduction is unwound.
  static Future<void> distributeSale({
    required double totalCarat,
    required double totalAmount,
    required bool isCash,
  }) async {
    if (totalCarat == 0) return;
    final all = await getAllPurchases();
    all.sort((a, b) => a.addedDate.compareTo(b.addedDate));

    if (totalCarat > 0) {
      double remainingToDeduct = totalCarat;
      for (var p in all) {
        if (remainingToDeduct <= 0) break;
        if (p.remainingCarat <= 0) continue;

        double deduct =
            remainingToDeduct > p.remainingCarat ? p.remainingCarat : remainingToDeduct;
        double portionAmount = (deduct / totalCarat) * totalAmount;

        if (isCash) {
          p.cashSoldCarat += deduct;
          p.cashSoldAmount += portionAmount;
        } else {
          p.billSoldCarat += deduct;
          p.billSoldAmount += portionAmount;
        }

        await savePurchase(p);
        remainingToDeduct -= deduct;
      }
    } else {
      double remainingToRestore = -totalCarat;
      final amountToRestore = -totalAmount;
      // Reverse order so we unwind the most-recent allocation first.
      final reversed = all.reversed.toList();
      for (var p in reversed) {
        if (remainingToRestore <= 0) break;
        final sold = isCash ? p.cashSoldCarat : p.billSoldCarat;
        if (sold <= 0) continue;

        final restore = remainingToRestore > sold ? sold : remainingToRestore;
        final portionAmount = (restore / -totalCarat) * amountToRestore;

        if (isCash) {
          p.cashSoldCarat = (p.cashSoldCarat - restore).clamp(0.0, double.infinity);
          p.cashSoldAmount =
              (p.cashSoldAmount - portionAmount).clamp(0.0, double.infinity);
        } else {
          p.billSoldCarat = (p.billSoldCarat - restore).clamp(0.0, double.infinity);
          p.billSoldAmount =
              (p.billSoldAmount - portionAmount).clamp(0.0, double.infinity);
        }

        await savePurchase(p);
        remainingToRestore -= restore;
      }
    }
  }
}
