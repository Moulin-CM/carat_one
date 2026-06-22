import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import '../services/modern_ui_service.dart';


/// Shows a bottom sheet asking the user to pick between a "By Cash".tr sell
/// (no invoice / PDF) and a "By In Account".tr sell (full GST invoice flow).
///
/// Returns `true` for cash, `false` for in-account, or `null` if dismissed.
Future<bool?> showSellOptionsSheet(BuildContext context) {
  // Read once from the caller's context so the sheet matches whichever
  // surface (classic or modern) the user is on.
  final modernUiEnabled =
      context.read<ModernUiService>().enabled;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => modernUiEnabled
        ? const _ModernSellOptionsSheet()
        : const _SellOptionsSheet(),
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

// ─────────────────────────────────────────────────────────────────────────────
//                            MODERN VARIANT
// ─────────────────────────────────────────────────────────────────────────────

/// Modern dark-themed sell options sheet — matches the rest of the
/// modern UI surfaces (navy gradient surface, glass tiles with gradient
/// icon chips).
class _ModernSellOptionsSheet extends StatelessWidget {
  const _ModernSellOptionsSheet();

  // Website tokens
  static const _bg1 = Color(0xFF0C1230);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg1, Color(0xFF11173B), _bg1],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: _violet.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
              ).createShader(rect),
              child: Text(
                'How is this sell being made?'.tr,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a mode — Cash skips the invoice/PDF, In Account creates a full GST invoice.'
                  .tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _ModernOptionTile(
              icon: Icons.payments_rounded,
              iconGradient: const [Color(0xFF10B981), Color(0xFF34D399)],
              accent: const Color(0xFF34D399),
              title: 'By Cash'.tr,
              subtitle:
                  'Save a cash sell entry. No invoice/PDF generated.'.tr,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            _ModernOptionTile(
              icon: Icons.account_balance_rounded,
              iconGradient: const [Color(0xFF4F8AF4), Color(0xFF38BDF8)],
              accent: _accent,
              title: 'By In Account'.tr,
              subtitle:
                  'Create a GST invoice with PDF and payment tracking.'.tr,
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernOptionTile extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernOptionTile({
    required this.icon,
    required this.iconGradient,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withOpacity(0.15),
        highlightColor: accent.withOpacity(0.06),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconGradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.first.withOpacity(0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withOpacity(0.40)),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: accent, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
