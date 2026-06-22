import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/export_import_viewmodel.dart';
import '../../services/import/data_import_service.dart';
import '../../services/modern_ui_service.dart';
import '../../constants/app_translations.dart';
import 'modern_export_import_view.dart';

class ExportImportView extends StatelessWidget {
  const ExportImportView({super.key});

  @override
  Widget build(BuildContext context) {
    final modernUiEnabled = context.watch<ModernUiService>().enabled;
    return ChangeNotifierProvider(
      create: (_) => ExportImportViewModel(),
      child: modernUiEnabled
          ? const ModernExportImportContent()
          : const _ExportImportViewContent(),
    );
  }
}

class _ExportImportViewContent extends StatefulWidget {
  const _ExportImportViewContent();

  @override
  State<_ExportImportViewContent> createState() => _ExportImportViewContentState();
}

class _ExportImportViewContentState extends State<_ExportImportViewContent> {
  final Color _accent = const Color(0xFF4F8AF4);
  final Color _deepAccent = const Color(0xFF1E3C72);
  final Color _surfaceTint = const Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExportImportViewModel>();

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
                child: Icon(Icons.import_export_rounded, color: _accent),
              ),
              const SizedBox(width: 10),
              Text('Export / Import'.tr),
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
                    title: 'Export Invoices'.tr,
                    icon: Icons.upload_file_rounded,
                    description: 'Export all your invoices to a JSON backup file'.tr,
                    children: [
                      _buildInfoCard(
                        'This will create a backup file containing all your invoices. You can share this file or save it for later restoration.'.tr,
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: viewModel.isExporting
                              ? null
                              : () => _handleExport(context, viewModel),
                          icon: viewModel.isExporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.file_download_rounded),
                          label: Text(
                            viewModel.isExporting ? 'Exporting...'.tr : 'Export All Invoices'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'Import Data'.tr,
                    icon: Icons.file_upload_rounded,
                    description: 'Import purchases or sells from Excel, CSV, PDF or JSON'.tr,
                    children: [
                      _buildKindSelector(viewModel),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Select what you want to import, then pick a file. Column headers in the file are matched to fields automatically (e.g. "Amount", "Total" or "Price" all map to amount).'.tr,
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: viewModel.isImporting
                              ? null
                              : () => _handleImport(context, viewModel),
                          icon: viewModel.isImporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.file_upload_rounded),
                          label: Text(
                            viewModel.isImporting ? 'Importing...'.tr : 'Pick File and Import'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    title: 'Supported Formats'.tr,
                    icon: Icons.description_rounded,
                    children: [
                      _buildInfoCard(
                        '• Excel (.xlsx, .xls) — first sheet, first row as headers\n'
                        '• CSV (.csv) — comma-separated, first row as headers\n'
                        '• JSON (.json) — array of objects, or a backup file\n'
                        '• PDF (.pdf) — best with table-style PDFs; arbitrary supplier PDFs may not parse cleanly\n\n'
                        'Imported records get fresh IDs and appear in the corresponding list immediately.'.tr,
                        Icons.help_outline_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKindSelector(ExportImportViewModel vm) {
    final isPurchase = vm.selectedKind == ImportDataKind.purchase;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKindOption(
              label: 'Purchases'.tr,
              icon: Icons.shopping_cart_rounded,
              selected: isPurchase,
              onTap: () => vm.setSelectedKind(ImportDataKind.purchase),
            ),
          ),
          Expanded(
            child: _buildKindOption(
              label: 'Sells / Invoices'.tr,
              icon: Icons.receipt_long_rounded,
              selected: !isPurchase,
              onTap: () => vm.setSelectedKind(ImportDataKind.sell),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKindOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _deepAccent : Colors.grey[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? _deepAccent : Colors.grey[700],
                ),
              ),
            ),
          ],
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
    String? description,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
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

  Future<void> _handleExport(BuildContext context, ExportImportViewModel viewModel) async {
    final success = await viewModel.exportInvoices();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoices exported successfully! Check your share options.'.tr),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          viewModel.clearMessages();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error exporting invoices'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context, ExportImportViewModel viewModel) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls', 'csv', 'json', 'pdf'],
        withData: false,
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final kindLabel = viewModel.selectedKind == ImportDataKind.purchase
          ? 'purchases'.tr
          : 'sells'.tr;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Import $kindLabel'),
          content: Text(
            '${'This will import'.tr} $kindLabel ${'from the selected file.'.tr}\n\n'
            '${'File'.tr}: $fileName\n\n'
            '${'Continue?'.tr}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Import'.tr),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;

      final importResult =
          await viewModel.importData(filePath, viewModel.selectedKind);
      if (!context.mounted) return;

      if (importResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Import failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Import Complete'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'Total rows'.tr}: ${importResult.totalRows}'),
                Text('${'Success'.tr}: ${importResult.successCount}'),
                if (importResult.errorCount > 0)
                  Text(
                    '${'Errors'.tr}: ${importResult.errorCount}',
                    style: const TextStyle(color: Colors.red),
                  ),
                if (importResult.matchedHeaders.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Matched columns:'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    importResult.matchedHeaders.join(', '),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (importResult.unmatchedHeaders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Ignored columns (no field match):'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    importResult.unmatchedHeaders.join(', '),
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                if (importResult.errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Errors:'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...importResult.errors.take(5).map(
                        (e) => Text('• $e',
                            style: const TextStyle(fontSize: 12)),
                      ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return with refresh flag
              },
              child: Text('OK'.tr),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Error'.tr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
