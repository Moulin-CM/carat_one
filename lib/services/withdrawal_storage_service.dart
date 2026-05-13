import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/withdrawal_model.dart';
import 'storage_parsers.dart';


class WithdrawalStorageService {
  static const String _key = 'saved_withdrawals';

  static DatabaseReference _getUserRef(String uid) =>
      FirebaseDatabase.instance.ref('users/$uid/withdrawals');

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

  static Future<void> saveWithdrawal(WithdrawalModel item) async {
    final user = await _getUser();
    if (user == null) throw StateError('Not logged in'.tr);
    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllWithdrawals();
    final idx = all.indexWhere((p) => p.id == item.id);
    if (idx != -1) {
      all[idx] = item;
    } else {
      all.add(item);
    }
    await prefs.setString(
        _localKey(uid), jsonEncode(all.map((w) => w.toJson()).toList()));
    try {
      await _getUserRef(uid).child(item.id).set(item.toJson());
    } catch (_) {}
  }

  static Future<List<WithdrawalModel>> getAllWithdrawals() async {
    final user = await _getUser();
    if (user == null) return [];
    final uid = user.uid;
    try {
      final snapshot = await _getUserRef(uid).get();
      if (snapshot.value != null) {
        final data = _deepConvert(snapshot.value);
        if (data is Map) {
          // jsonEncode on UI thread (cheap, primitives only) → compute()
          // does the decode + N×fromJson on a background isolate.
          final encoded = jsonEncode(data);
          final remote = await compute(parseWithdrawalMapJson, encoded);
          if (remote.isNotEmpty) {
            final cacheString = await compute(_encodeWithdrawals, remote);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_localKey(uid), cacheString);
            return remote;
          }
        }
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey(uid));
      if (raw != null && raw.isNotEmpty) {
        return await compute(parseWithdrawalListJson, raw);
      }
    } catch (_) {}
    return [];
  }

  static String _encodeWithdrawals(List<WithdrawalModel> items) {
    return jsonEncode(items.map((w) => w.toJson()).toList());
  }

  static Future<void> deleteWithdrawal(String id) async {
    final user = await _getUser();
    if (user == null) return;
    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllWithdrawals();
    all.removeWhere((p) => p.id == id);
    await prefs.setString(
        _localKey(uid), jsonEncode(all.map((w) => w.toJson()).toList()));
    try {
      await _getUserRef(uid).child(id).remove();
    } catch (_) {}
  }

  static Future<void> markReturned(String id, {bool returned = true}) async {
    final all = await getAllWithdrawals();
    final idx = all.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    all[idx].isReturned = returned;
    all[idx].returnedAt = returned ? DateTime.now() : null;
    await saveWithdrawal(all[idx]);
  }
}
