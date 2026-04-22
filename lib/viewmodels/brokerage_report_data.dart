import '../models/invoice_model.dart';
import '../models/purchase_model.dart';

enum BrokerSide { buy, sell }

/// One broker-attributable transaction (a purchase or an invoice).
class BrokerEntry {
  final BrokerSide side;
  final DateTime date;
  final String personName; // seller (buy) or buyer (sell)
  final String itemLabel; // size (buy) or invoice no (sell)
  final double carat;
  final double charge; // brokerage amount earned by this broker

  const BrokerEntry({
    required this.side,
    required this.date,
    required this.personName,
    required this.itemLabel,
    required this.carat,
    required this.charge,
  });
}

/// All entries for a single broker name, plus totals.
class BrokerAggregate {
  final String name;
  final List<BrokerEntry> entries;

  BrokerAggregate(this.name, this.entries);

  double get totalCharge =>
      entries.fold(0.0, (s, e) => s + e.charge);
  double get totalCarat =>
      entries.fold(0.0, (s, e) => s + e.carat);
  int get buyCount =>
      entries.where((e) => e.side == BrokerSide.buy).length;
  int get sellCount =>
      entries.where((e) => e.side == BrokerSide.sell).length;
}

class BrokerageReportBuilder {
  /// Builds per-broker aggregates from the given purchases & invoices
  /// falling inside [start]–[end]. Only entries that have a non-empty
  /// broker name *and* a non-zero broker charge are included.
  static List<BrokerAggregate> build({
    required List<PurchaseModel> purchases,
    required List<InvoiceModel> invoices,
    required DateTime start,
    required DateTime end,
  }) {
    final byBroker = <String, List<BrokerEntry>>{};

    // An entry qualifies if it has EITHER a broker name OR a non-zero
    // broker charge. Legacy purchases/invoices that carry one but not
    // the other still surface — ones with no name are grouped under
    // "Unnamed Broker" so the user can see what's unattributed.
    for (final p in purchases) {
      final hasName = p.brokerName.trim().isNotEmpty;
      final hasCharge = p.brokerChargeAmount > 0;
      if (!hasName && !hasCharge) continue;
      if (p.buyDate.isBefore(start) || p.buyDate.isAfter(end)) continue;
      final key = hasName ? _normalize(p.brokerName) : 'Unnamed Broker';
      byBroker.putIfAbsent(key, () => []).add(BrokerEntry(
            side: BrokerSide.buy,
            date: p.buyDate,
            personName: p.sellerName,
            itemLabel: p.size.isNotEmpty ? p.size : '-',
            carat: p.totalCarat,
            charge: p.brokerChargeAmount,
          ));
    }

    for (final inv in invoices) {
      final hasName = inv.brokerName.trim().isNotEmpty;
      final hasCharge = inv.brokerChargeAmount > 0;
      if (!hasName && !hasCharge) continue;
      if (inv.invoiceDate.isBefore(start) ||
          inv.invoiceDate.isAfter(end)) continue;
      final key = hasName ? _normalize(inv.brokerName) : 'Unnamed Broker';
      byBroker.putIfAbsent(key, () => []).add(BrokerEntry(
            side: BrokerSide.sell,
            date: inv.invoiceDate,
            personName: inv.buyerName,
            itemLabel: inv.invoiceNo.isNotEmpty ? inv.invoiceNo : '-',
            carat: inv.totalCarat,
            charge: inv.brokerChargeAmount,
          ));
    }

    final result = byBroker.entries.map((e) {
      final sorted = [...e.value]..sort((a, b) => b.date.compareTo(a.date));
      return BrokerAggregate(e.key, sorted);
    }).toList();
    // Highest earners first.
    result.sort((a, b) => b.totalCharge.compareTo(a.totalCharge));
    return result;
  }

  static String _normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Unknown';
    // Title-case each space-separated token so "ramesh" and "Ramesh"
    // fold into one broker.
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
