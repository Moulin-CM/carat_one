class UsageQuota {
  final int purchasesAdded;
  final int sellsAdded;
  final int pdfsGenerated;
  final int adsWatched;
  final DateTime lastReset;

  UsageQuota({
    this.purchasesAdded = 0,
    this.sellsAdded = 0,
    this.pdfsGenerated = 0,
    this.adsWatched = 0,
    required this.lastReset,
  });

  factory UsageQuota.fromMap(Map<dynamic, dynamic> map) {
    return UsageQuota(
      purchasesAdded: map['purchasesAdded'] ?? 0,
      sellsAdded: map['sellsAdded'] ?? 0,
      pdfsGenerated: map['pdfsGenerated'] ?? 0,
      adsWatched: map['adsWatched'] ?? 0,
      lastReset: map['lastReset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReset'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'purchasesAdded': purchasesAdded,
      'sellsAdded': sellsAdded,
      'pdfsGenerated': pdfsGenerated,
      'adsWatched': adsWatched,
      'lastReset': lastReset.millisecondsSinceEpoch,
    };
  }
}
