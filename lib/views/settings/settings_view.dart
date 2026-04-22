import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../export_import/export_import_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel()..loadSettings(),
      child: const _SettingsViewContent(),
    );
  }
}

class _SettingsViewContent extends StatefulWidget {
  const _SettingsViewContent();

  @override
  State<_SettingsViewContent> createState() => _SettingsViewContentState();
}

class _SettingsViewContentState extends State<_SettingsViewContent> {
  final Color _accent = const Color(0xFF4F8AF4);
  final Color _deepAccent = const Color(0xFF1E3C72);
  final Color _surfaceTint = const Color(0xFFF5F7FB);

  final TextEditingController _invoicePrefixController = TextEditingController();
  final TextEditingController _startingNumberController = TextEditingController();
  final TextEditingController _defaultTermsController = TextEditingController();

  @override
  void dispose() {
    _invoicePrefixController.dispose();
    _startingNumberController.dispose();
    _defaultTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Sync controllers with ViewModel values if they are empty (initial load)
    // or if the ViewModel values changed from outside (like reset)
    if (_invoicePrefixController.text != viewModel.settings.invoiceNumberPrefix) {
      _invoicePrefixController.text = viewModel.settings.invoiceNumberPrefix;
    }
    if (_startingNumberController.text != viewModel.settings.startingInvoiceNumber.toString()) {
      _startingNumberController.text = viewModel.settings.startingInvoiceNumber.toString();
    }
    if (_defaultTermsController.text != viewModel.settings.defaultTerms) {
      _defaultTermsController.text = viewModel.settings.defaultTerms;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Icon(Icons.settings_rounded, color: _accent),
              ),
              const SizedBox(width: 10),
              const Text('Settings'),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.errorMessage != null)
                    _buildErrorMessage(viewModel.errorMessage!),
                  if (viewModel.successMessage != null)
                    _buildSuccessMessage(viewModel.successMessage!),
                  const SizedBox(height: 8),
                  _buildSection(
                    title: 'Tax Rates',
                    icon: Icons.calculate_rounded,
                    children: [
                      _buildSliderField(
                        'CGST Rate (%)',
                        viewModel.settings.cgstRate,
                        (value) => viewModel.updateCgstRate(value),
                        min: 0.0,
                        max: 10.0,
                      ),
                      const SizedBox(height: 16),
                      _buildSliderField(
                        'SGST Rate (%)',
                        viewModel.settings.sgstRate,
                        (value) => viewModel.updateSgstRate(value),
                        min: 0.0,
                        max: 10.0,
                      ),
                      const SizedBox(height: 16),
                      _buildSliderField(
                        'IGST Rate (%)',
                        viewModel.settings.igstRate,
                        (value) => viewModel.updateIgstRate(value),
                        min: 0.0,
                        max: 10.0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'Invoice Numbering',
                    icon: Icons.numbers_rounded,
                    children: [
                      _buildTextField(
                        'Invoice Number Prefix',
                        _invoicePrefixController,
                        (value) => viewModel.updateInvoiceNumberPrefix(value),
                        hint: 'e.g., INV, INVOICE',
                        icon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        'Starting Invoice Number',
                        _startingNumberController,
                        (value) => viewModel.updateStartingInvoiceNumber(value),
                        icon: Icons.start_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Note: Changing the starting number will affect new invoices only. Use "Reset Invoice Numbering" to reset the current counter.',
                        Icons.info_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'Default Invoice Terms',
                    icon: Icons.description_rounded,
                    children: [
                      _buildTextField(
                        'Default Terms',
                        _defaultTermsController,
                        (value) => viewModel.updateDefaultTerms(value),
                        hint: 'Enter default terms and conditions',
                        icon: Icons.text_fields_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'App Preferences',
                    icon: Icons.tune_rounded,
                    children: [
                      _buildSwitchTile(
                        'Enable Notifications',
                        viewModel.settings.enableNotifications,
                        (value) => viewModel.updateEnableNotifications(value),
                        Icons.notifications_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildSwitchTile(
                        'Auto Save Draft',
                        viewModel.settings.autoSaveDraft,
                        (value) => viewModel.updateAutoSaveDraft(value),
                        Icons.save_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'Data Management',
                    icon: Icons.storage_rounded,
                    children: [
                      _buildActionButton(
                        'Export / Import',
                        'Backup and restore your invoices',
                        Icons.import_export_rounded,
                        Colors.blue,
                        () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExportImportView(),
                            ),
                          );
                          // If import was successful, we could refresh settings if needed
                          if (result == true && context.mounted) {
                            // Settings don't need refresh, but we could show a message
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Reset Invoice Numbering',
                        'Reset the invoice number counter to start from beginning',
                        Icons.refresh_rounded,
                        Colors.orange,
                        () => _handleResetInvoiceNumbering(context, viewModel),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Reset All Settings',
                        'Reset all settings to default values',
                        Icons.restore_rounded,
                        Colors.red,
                        () => _handleResetSettings(context, viewModel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: viewModel.isSaving
                  ? null
                  : () => _handleSaveSettings(context, viewModel),
              icon: viewModel.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                viewModel.isSaving ? 'Saving...' : 'Save Settings',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: _accent.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7EEFF),
            Color(0xFFF9FBFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _blurredCircle(220, _accent.withOpacity(0.22)),
          ),
          Positioned(
            top: 140,
            left: -90,
            child: _blurredCircle(200, _deepAccent.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _blurredCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceTint,
                ),
                child: Icon(icon, color: _accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderField(
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _accent,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 100).toInt(),
          label: '${value.toStringAsFixed(2)}%',
          activeColor: _accent,
          inactiveColor: _surfaceTint,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    String? hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          maxLines: maxLines,
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: _accent) : null,
            filled: true,
            fillColor: _surfaceTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accent.withOpacity(0.9), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    Function(int) onChanged, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: _accent) : null,
            filled: true,
            fillColor: _surfaceTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accent.withOpacity(0.9), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
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

  Widget _buildSwitchTile(
    String title,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _accent,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveSettings(BuildContext context, SettingsViewModel viewModel) async {
    final success = await viewModel.saveSettings();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear messages after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          viewModel.clearMessages();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error saving settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResetInvoiceNumbering(BuildContext context, SettingsViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Invoice Numbering'),
        content: const Text('Are you sure you want to reset the invoice numbering? This will reset the counter to start from the beginning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.resetInvoiceNumbering();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice numbering reset successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? 'Error resetting invoice numbering'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResetSettings(BuildContext context, SettingsViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text('Are you sure you want to reset all settings to default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.resetSettings();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to default!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? 'Error resetting settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
