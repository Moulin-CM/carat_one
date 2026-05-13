import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_model.dart';


class InventoryStorageService {
  static const String _inventoryKey = 'saved_inventory';
  static final DatabaseReference _inventoryRef =
      FirebaseDatabase.instance.ref('inventory'.tr);

  static DatabaseReference _getUserInventoryRef(String? uid) {
    if (uid != null) {
      return FirebaseDatabase.instance.ref('users/$uid/inventory');
    }
    return _inventoryRef;
  }

  static String _getLocalStorageKey(String? uid) {
    if (uid != null) {
      return '${_inventoryKey}_$uid';
    }
    return _inventoryKey;
  }

  /// Save inventory item locally (SharedPreferences) and remotely (Firebase).
  static Future<void> saveInventoryItem(InventoryModel item) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userInventoryRef = _getUserInventoryRef(uid);
    final storageKey = _getLocalStorageKey(uid);

    // ---------- LOCAL PERSISTENCE (existing behaviour) ----------
    final prefs = await SharedPreferences.getInstance();
    final items = await getAllInventoryItems();

    // Ensure item has an id
    item.id ??= DateTime.now().millisecondsSinceEpoch.toString();

    // Update lastUpdatedDate when saving existing item
    final existingIndex = items.indexWhere((inv) => inv.id == item.id);
    if (existingIndex != -1) {
      item.lastUpdatedDate = DateTime.now();
      items[existingIndex] = item;
    } else {
      item.addedDate = DateTime.now();
      items.add(item);
    }

    final itemsJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(itemsJson));

    // ---------- REMOTE PERSISTENCE (Firebase Realtime DB) ----------
    try {
      await userInventoryRef.child(item.id).set(item.toJson());
    } catch (e) {
      debugPrint('[InventoryStorage] Remote save failed: $e');
    }
  }

  /// Read inventory items from Firebase if available, otherwise fall back to local.
  static Future<List<InventoryModel>> getAllInventoryItems() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userInventoryRef = _getUserInventoryRef(uid);
    final storageKey = _getLocalStorageKey(uid);

    try {
      final snapshot = await userInventoryRef.get();
      final List<InventoryModel> remote = [];

      if (snapshot.value is Map) {
        final data = Map<String, dynamic>.from(
          snapshot.value as Map<Object?, Object?>,
        );
        data.forEach((key, value) {
          if (value is Map<Object?, Object?>) {
            final json = Map<String, dynamic>.from(value);
            json['id'] = key;
            remote.add(InventoryModel.fromJson(json));
          }
        });
      }

      if (remote.isNotEmpty) {
        remote.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        // Keep local cache synced
        await _cacheInventoryLocally(remote, storageKey);
        return remote;
      }
    } catch (e) {
      // If Firebase fails (permission denied, network error, etc.), fall back to local cache.
      // This is expected behavior - we silently fall back to local storage.
      // Only log if it's not a permission error (which is expected for unauthenticated users)
      if (!e.toString().contains('.trPermission denied')) {
        debugPrint('[InventoryStorage] Firebase read error: $e');
      }
    }

    // ---------- LOCAL FALLBACK ----------
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(storageKey);

    if (itemsJson == null || itemsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      return decoded
          .map((json) => InventoryModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _cacheInventoryLocally(
      List<InventoryModel> items, String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(itemsJson));
  }

  static Future<InventoryModel?> getInventoryItemById(String id) async {
    final items = await getAllInventoryItems();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteInventoryItem(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userInventoryRef = _getUserInventoryRef(uid);
    final storageKey = _getLocalStorageKey(uid);

    // Local delete
    final prefs = await SharedPreferences.getInstance();
    final items = await getAllInventoryItems();
    items.removeWhere((item) => item.id == id);
    final itemsJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(itemsJson));

    // Remote delete
    try {
      await userInventoryRef.child(id).remove();
    } catch (e) {
      debugPrint('[InventoryStorage] Remote delete failed: $e');
    }
  }
}
