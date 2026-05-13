import 'package:flutter/material.dart';
import 'package:invoice_generator/constants/app_translations.dart';


/// Shows a bottom sheet asking the user to pick between a "By Cash".tr sell
/// (no invoice / PDF) and a "By In Account".tr sell (full GST invoice flow).
///
/// Returns `true` for cash, `false` for in-account, or `null` if dismissed.
Future<bool?> showSellOptionsSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SellOptionsSheet(),
  );
}

class _SellOptionsSheet extends StatelessWidget {
  const _SellOptionsSheet();

  static const _accent = Color(0xFF4F8AF4);
  static const _deep = Color(0xFF1E3C72);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How is this sell being made?'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _deep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a mode — Cash skips the invoice/PDF, In Account creates a full GST invoice.'
                  .tr,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.payments_rounded,
              color: const Color(0xFF2E7D32),
              title: 'By Cash'.tr,
              subtitle: 'Save a cash sell entry. No invoice/PDF generated.'.tr,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.account_balance_rounded,
              color: _accent,
              title: 'By In Account'.tr,
              subtitle:
                  'Create a GST invoice with PDF and payment tracking.'.tr,
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
