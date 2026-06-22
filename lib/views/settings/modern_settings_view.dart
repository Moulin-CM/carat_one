import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ads_service.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../constants/app_translations.dart';
import '../export_import/export_import_view.dart';

/// Modern UI surface for the Settings tab.
///
/// Same VM, same fields, same save / reset / rewarded-ad flows — only
/// the visual layer is restyled to match the dark navy modern surfaces.
class ModernSettingsContent extends StatefulWidget {
  const ModernSettingsContent({super.key});

  @override
  State<ModernSettingsContent> createState() => _ModernSettingsContentState();
}

class _ModernSettingsContentState extends State<ModernSettingsContent> {
  // Website tokens
  static const _bg0 = Color(0xFF07091C);
  static const _bg1 = Color(0xFF0C1230);
  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _accent, _violet],
    stops: [0.0, 0.5, 1.0],
  );

  final TextEditingController _invoicePrefixController =
      TextEditingController();
  final TextEditingController _startingNumberController =
      TextEditingController();
  final TextEditingController _defaultTermsController =
      TextEditingController();

  @override
  void dispose() {
    _invoicePrefixController.dispose();
    _startingNumberController.dispose();
    _defaultTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: _bg0,
        body: const Center(
            child: CircularProgressIndicator(color: _accent)),
      );
    }

    // Sync controllers with VM values.
    if (_invoicePrefixController.text !=
        vm.settings.invoiceNumberPrefix) {
      _invoicePrefixController.text = vm.settings.invoiceNumberPrefix;
    }
    if (_startingNumberController.text !=
        vm.settings.startingInvoiceNumber.toString()) {
      _startingNumberController.text =
          vm.settings.startingInvoiceNumber.toString();
    }
    if (_defaultTermsController.text != vm.settings.defaultTerms) {
      _defaultTermsController.text = vm.settings.defaultTerms;
    }

    return Scaffold(
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.errorMessage != null)
                    _buildErrorBanner(vm.errorMessage!),
                  if (vm.successMessage != null)
                    _buildSuccessBanner(vm.successMessage!),
                  _glassSection(
                    title: 'Tax Rates'.tr,
                    icon: Icons.calculate_rounded,
                    gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    children: [
                      _slider(
                        'CGST Rate (%)'.tr,
                        vm.settings.cgstRate,
                        vm.updateCgstRate,
                        min: 0.0,
                        max: 10.0,
                      ),
                      const SizedBox(height: 14),
                      _slider(
                        'SGST Rate (%)'.tr,
                        vm.settings.sgstRate,
                        vm.updateSgstRate,
                        min: 0.0,
                        max: 10.0,
                      ),
                      const SizedBox(height: 14),
                      _slider(
                        'IGST Rate (%)'.tr,
                        vm.settings.igstRate,
                        vm.updateIgstRate,
                        min: 0.0,
                        max: 10.0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassSection(
                    title: 'Invoice Numbering'.tr,
                    icon: Icons.numbers_rounded,
                    gradient: const [_primary, _accent],
                    children: [
                      _textField(
                        label: 'Invoice Number Prefix'.tr,
                        controller: _invoicePrefixController,
                        hint: 'e.g., INV, INVOICE'.tr,
                        icon: Icons.tag_rounded,
                        onChanged: vm.updateInvoiceNumberPrefix,
                      ),
                      const SizedBox(height: 16),
                      _numberField(
                        label: 'Starting Invoice Number'.tr,
                        controller: _startingNumberController,
                        icon: Icons.start_rounded,
                        onChanged: vm.updateStartingInvoiceNumber,
                      ),
                      const SizedBox(height: 14),
                      _infoCard(
                        'Note: Changing the starting number will affect new invoices only. Use "Reset Invoice Numbering".tr to reset the current counter.'
                            .tr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassSection(
                    title: 'Default Invoice Terms'.tr,
                    icon: Icons.description_rounded,
                    gradient: const [_accent, _violet],
                    children: [
                      _textField(
                        label: 'Default Terms'.tr,
                        controller: _defaultTermsController,
                        hint: 'Enter default terms and conditions'.tr,
                        icon: Icons.text_fields_rounded,
                        maxLines: 3,
                        onChanged: vm.updateDefaultTerms,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassSection(
                    title: 'App Preferences'.tr,
                    icon: Icons.tune_rounded,
                    gradient: const [Color(0xFF6366F1), _violet],
                    children: [
                      _switchTile(
                        title: 'Enable Notifications'.tr,
                        value: vm.settings.enableNotifications,
                        icon: Icons.notifications_outlined,
                        onChanged: vm.updateEnableNotifications,
                      ),
                      const SizedBox(height: 10),
                      _switchTile(
                        title: 'Auto Save Draft'.tr,
                        value: vm.settings.autoSaveDraft,
                        icon: Icons.save_outlined,
                        onChanged: vm.updateAutoSaveDraft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassSection(
                    title: 'Data Management'.tr,
                    icon: Icons.storage_rounded,
                    gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                    children: [
                      _actionButton(
                        title: 'Export / Import'.tr,
                        subtitle: 'Backup and restore your invoices'.tr,
                        icon: Icons.import_export_rounded,
                        gradient: const [
                          _primary,
                          _accent,
                        ],
                        accent: _accent,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExportImportView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _actionButton(
                        title: 'Reset Invoice Numbering'.tr,
                        subtitle:
                            'Reset the invoice number counter to start from beginning'
                                .tr,
                        icon: Icons.refresh_rounded,
                        gradient: const [
                          Color(0xFFFBBF24),
                          Color(0xFFF59E0B),
                        ],
                        accent: const Color(0xFFFBBF24),
                        onTap: () =>
                            _handleResetInvoiceNumbering(context, vm),
                      ),
                      const SizedBox(height: 12),
                      _actionButton(
                        title: 'Reset All Settings'.tr,
                        subtitle: 'Reset all settings to default values'.tr,
                        icon: Icons.restore_rounded,
                        gradient: const [
                          Color(0xFFEF4444),
                          Color(0xFFF87171),
                        ],
                        accent: const Color(0xFFF87171),
                        onTap: () => _handleResetSettings(context, vm),
                      ),
                    ],
                  ),
                  if (AdsService.instance.isSupported) ...[
                    const SizedBox(height: 16),
                    _glassSection(
                      title: 'Support CaratOne'.tr,
                      icon: Icons.favorite_rounded,
                      gradient: const [
                        Color(0xFFF0ABFC),
                        Color(0xFFEC4899),
                      ],
                      children: [
                        _actionButton(
                          title: 'Watch a Short Ad'.tr,
                          subtitle:
                              'Help keep CaratOne free — watch a 30-second ad to support development'
                                  .tr,
                          icon: Icons.play_circle_fill_rounded,
                          gradient: const [
                            Color(0xFFF0ABFC),
                            Color(0xFFEC4899),
                          ],
                          accent: const Color(0xFFF0ABFC),
                          onTap: () => _handleSupportRewarded(context),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingSaveButton(context, vm),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
            ).createShader(rect),
            child: Text(
              'Settings'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  BACKDROP  ───────────────────────────────

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, _bg0],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _glow(280, _primary.withOpacity(0.25)),
          ),
          Positioned(
            top: 240,
            left: -100,
            child: _glow(240, _violet.withOpacity(0.18)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  // ─────────────────────────────  BANNERS  ────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFFCA5A5), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF34D399).withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF34D399), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  GLASS SECTION  ──────────────────────────

  Widget _glassSection({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ─────────────────────────────  SLIDER  ─────────────────────────────────

  Widget _slider(
    String label,
    double value,
    Function(double) onChanged, {
    required double min,
    required double max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withOpacity(0.40)),
              ),
              child: Text(
                '${value.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _accent,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white.withOpacity(0.10),
            thumbColor: Colors.white,
            overlayColor: _accent.withOpacity(0.20),
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 100).toInt(),
            label: '${value.toStringAsFixed(2)}%',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────  TEXT / NUMBER FIELDS  ───────────────────

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: _accent,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required Function(int) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: _accent,
          decoration: _inputDecoration(icon: icon),
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null && intValue > 0) {
              onChanged(intValue);
            }
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.40),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: _accent, size: 20)
          : null,
      prefixIconConstraints:
          const BoxConstraints(minWidth: 44, minHeight: 0),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  // ─────────────────────────────  SWITCH TILE  ────────────────────────────

  Widget _switchTile({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? _accent.withOpacity(0.40)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: value
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primary, _accent],
                    )
                  : null,
              color: value ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? Colors.white : Colors.white.withOpacity(0.65),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _accent,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  INFO CARD  ──────────────────────────────

  Widget _infoCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: _accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  ACTION BUTTON  ──────────────────────────

  Widget _actionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: accent.withOpacity(0.15),
        highlightColor: accent.withOpacity(0.06),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: accent,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  FLOATING SAVE  ──────────────────────────

  Widget _buildFloatingSaveButton(
      BuildContext context, SettingsViewModel vm) {
    final pillWidth = MediaQuery.of(context).size.width - 32;
    final busy = vm.isSaving;
    return SizedBox(
      width: pillWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: busy ? null : () => _handleSaveSettings(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: busy ? null : _grad,
              color: busy ? Colors.white.withOpacity(0.10) : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: busy
                  ? null
                  : [
                      BoxShadow(
                        color: _primary.withOpacity(0.45),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: _violet.withOpacity(0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  const Icon(Icons.save_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    busy ? 'Saving...'.tr : 'Save Settings'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  HANDLERS  ───────────────────────────────

  Future<void> _handleSaveSettings(
      BuildContext context, SettingsViewModel vm) async {
    final success = await vm.saveSettings();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully!'.tr),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          vm.clearMessages();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(vm.errorMessage ?? 'Error saving settings'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResetInvoiceNumbering(
      BuildContext context, SettingsViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Invoice Numbering'.tr),
        content: Text(
            'Are you sure you want to reset the invoice numbering? This will reset the counter to start from the beginning.'
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('Reset'.tr),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await vm.resetInvoiceNumbering();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice numbering reset successfully!'.tr),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.errorMessage ??
                  'Error resetting invoice numbering'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResetSettings(
      BuildContext context, SettingsViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset All Settings'.tr),
        content: Text(
            'Are you sure you want to reset all settings to default values? This action cannot be undone.'
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Reset'.tr),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await vm.resetSettings();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Settings reset to default!'.tr),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(vm.errorMessage ?? 'Error resetting settings'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSupportRewarded(BuildContext context) async {
    const pink = Color(0xFFEC4899);
    const rose = Color(0xFFF0ABFC);

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
                color: pink.withOpacity(0.30),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: rose.withOpacity(0.20),
                blurRadius: 22,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart medallion
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [rose, pink],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: pink.withOpacity(0.50),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
                ).createShader(rect),
                child: Text(
                  'Thank You!'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A short video ad will play. When it finishes you\'ll get a thank-you and we earn a small amount that keeps CaratOne free.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pink.withOpacity(0.40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: rose),
                    const SizedBox(width: 6),
                    Text(
                      'You can close the ad at any time.'.tr,
                      style: const TextStyle(
                        color: rose,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Center(
                            child: Text(
                              'Maybe Later'.tr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [rose, pink],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: pink.withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Watch Ad'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !context.mounted) return;

    await AdsService.instance.showRewarded(
      onReward: () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Thanks for supporting CaratOne ❤️'.tr),
              ],
            ),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      },
      onUnavailable: () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ad not available right now — please try again later.'.tr),
          ),
        );
      },
    );
  }
}
