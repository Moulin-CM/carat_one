import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/usage_quota.dart';
import '../models/subscription_status.dart';
import '../models/subscription_plan.dart';
import 'subscription_service.dart';

class QuotaService {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _subService = SubscriptionService();

  static final QuotaService _instance = QuotaService._internal();
  factory QuotaService() => _instance;
  QuotaService._internal();

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<UsageQuota> getTodayQuota() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return UsageQuota(lastReset: DateTime.now());

    final snapshot = await _db.child('users/$uid/usage/$_todayKey').get();
    if (snapshot.value != null) {
      return UsageQuota.fromMap(Map<dynamic, dynamic>.from(snapshot.value as Map));
    } else {
      final newQuota = UsageQuota(lastReset: DateTime.now());
      await _db.child('users/$uid/usage/$_todayKey').set(newQuota.toMap());
      return newQuota;
    }
  }

  Future<bool> canAddEntry(bool isPurchase) async {
    final status = _subService.currentStatus;
    
    // Trial or Pro/Business have no limits or high limits
    if (status.plan == SubscriptionTier.trial && status.isActive) return true;
    if (status.plan == SubscriptionTier.pro || status.plan == SubscriptionTier.business) return true;

    final quota = await getTodayQuota();
    final currentMonthUsage = await _getMonthUsage();

    if (status.plan == SubscriptionTier.starter) {
      if (isPurchase) {
        return currentMonthUsage['purchases']! < 30;
      } else {
        return currentMonthUsage['sells']! < 30;
      }
    }

    // Expired or No Plan - Blocked unless they have ad credits (if implemented later)
    return false;
  }

  Future<Map<String, int>> _getMonthUsage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {'purchases': 0, 'sells': 0};

    final monthPrefix = DateFormat('yyyy-MM').format(DateTime.now());
    final snapshot = await _db.child('users/$uid/usage').get();
    
    int purchases = 0;
    int sells = 0;

    if (snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        if (key.toString().startsWith(monthPrefix)) {
          final dayData = Map<dynamic, dynamic>.from(value as Map);
          purchases += (dayData['purchasesAdded'] ?? 0) as int;
          sells += (dayData['sellsAdded'] ?? 0) as int;
        }
      });
    }

    return {'purchases': purchases, 'sells': sells};
  }

  Future<void> incrementUsage(bool isPurchase) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final field = isPurchase ? 'purchasesAdded' : 'sellsAdded';
    await _db.child('users/$uid/usage/$_todayKey/$field').set(ServerValue.increment(1));
  }

  Future<bool> canPrintPdf() async {
    final status = _subService.currentStatus;
    if (status.plan == SubscriptionTier.pro || status.plan == SubscriptionTier.business) return true;
    if (status.plan == SubscriptionTier.trial && status.isActive) return true;

    final currentMonthPdfs = await _getMonthPdfCount();
    if (status.plan == SubscriptionTier.starter) {
      return currentMonthPdfs < 10;
    }
    
    return false;
  }

  Future<int> _getMonthPdfCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final monthPrefix = DateFormat('yyyy-MM').format(DateTime.now());
    final snapshot = await _db.child('users/$uid/usage').get();
    
    int pdfs = 0;
    if (snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        if (key.toString().startsWith(monthPrefix)) {
          final dayData = Map<dynamic, dynamic>.from(value as Map);
          pdfs += (dayData['pdfsGenerated'] ?? 0) as int;
        }
      });
    }
    return pdfs;
  }

  Future<void> incrementPdfUsage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.child('users/$uid/usage/$_todayKey/pdfsGenerated').set(ServerValue.increment(1));
  }
}
