import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/export_import_viewmodel.dart';
import '../../services/import/data_import_service.dart';
import '../../constants/app_translations.dart';

/// Modern UI surface for the Export / Import screen.
///
/// Same VM, same export + file-pick + import + result flows. Only the
/// visual layer changes — dark navy backdrop, gradient action pills,
/// glass kind selector with animated active tab.
class ModernExportImportContent extends StatefulWidget {
  const ModernExportImportContent({super.key});

  @override
  State<ModernExportImportContent> createState() =>
      _ModernExportImportContentState();
}

class _ModernExportImportContentState
    extends State<ModernExportImportContent> {
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

  static const _exportGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExportImportViewModel>();

    return Scaffold(
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.errorMessage != null)
                    _buildErrorBanner(vm.errorMessage!),
                  if (vm.successMessage != null)
                    _buildSuccessBanner(vm.successMessage!),
                  _glassSection(
                    title: 'Export Invoices'.tr,
                    description:
                        'Export all your invoices to a JSON backup file'.tr,
                    icon: Icons.upload_file_rounded,
                    gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                    children: [
                      _infoCard(
                        'This will create a backup file containing all your invoices. You can share this file or save it for later restoration.'
                            .tr,
                      ),
                      const SizedBox(height: 14),
                      _gradientButton(
                        label: vm.isExporting
                            ? 'Exporting...'.tr
                            : 'Export All Invoices'.tr,
                        icon: Icons.file_download_rounded,
                        gradient: _exportGrad,
                        glow: const Color(0xFF34D399),
                        busy: vm.isExporting,
                        onTap: vm.isExporting
                            ? null
                            : () => _handleExport(context, vm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassSection(
                    title: 'Import Data'.tr,
                    description:
                        'Import purchases or sells from Excel, CSV, PDF or JSON'
                            .tr,
                    icon: Icons.file_upload_rounded,
                    gradient: const [_primary, _accent],
                    children: [
                      _kindSelector(vm),
                      const SizedBox(height: 12),
                      _infoCard(
                        'Select what you want to import, then pick a file. Column headers in the file are matched to fields automatically (e.g. "Amount", "Total" or "Price" all map to amount).'
                            .tr,
                      ),
                      const SizedBox(height: 14),
                      _gradientButton(
                        label: vm.isImporting
                            ? 'Importing...'.tr
                            : 'Pick File and Import'.tr,
                        icon: Icons.file_upload_rounded,
                        gradient: _grad,
                        glow: _accent,
                        busy: vm.isImporting,
                        onTap: vm.isImporting
                            ? null
                            : () => _handleImport(context, vm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassSection(
                    title: 'Supported Formats'.tr,
                    icon: Icons.description_rounded,
                    gradient: const [_accent, _violet],
                    children: [
                      _infoCard(
                        '• Excel (.xlsx, .xls) — first sheet, first row as headers\n'
                                '• CSV (.csv) — comma-separated, first row as headers\n'
                                '• JSON (.json) — array of objects, or a backup file\n'
                                '• PDF (.pdf) — best with table-style PDFs; arbitrary supplier PDFs may not parse cleanly\n\n'
                                'Imported records get fresh IDs and appear in the corresponding list immediately.'
                            .tr,
                        icon: Icons.help_outline_rounded,
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

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
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
            child: const Icon(Icons.import_export_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
            ).createShader(rect),
            child: Text(
              'Export / Import'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
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
            top: 220,
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
        border:
            Border.all(color: const Color(0xFFEF4444).withOpacity(0.45)),
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
        border:
            Border.all(color: const Color(0xFF34D399).withOpacity(0.45)),
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
    String? description,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55),
                          height: 1.35,
                        ),
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

  // ─────────────────────────────  KIND SELECTOR  ──────────────────────────

  Widget _kindSelector(ExportImportViewModel vm) {
    final isPurchase = vm.selectedKind == ImportDataKind.purchase;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _kindOption(
              label: 'Purchases'.tr,
              icon: Icons.shopping_cart_rounded,
              selected: isPurchase,
              onTap: () => vm.setSelectedKind(ImportDataKind.purchase),
            ),
          ),
          Expanded(
            child: _kindOption(
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

  Widget _kindOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected ? _grad : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : Colors.white.withOpacity(0.55),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────  INFO CARD  ──────────────────────────────

  Widget _infoCard(String message, {IconData icon = Icons.info_outline_rounded}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  GRADIENT BUTTON  ────────────────────────

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required Color glow,
    required bool busy,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: onTap == null ? null : gradient,
              color: onTap == null
                  ? Colors.white.withOpacity(0.10)
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: onTap == null
                  ? null
                  : [
                      BoxShadow(
                        color: glow.withOpacity(0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

  Future<void> _handleExport(
      BuildContext context, ExportImportViewModel vm) async {
    final success = await vm.exportInvoices();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Invoices exported successfully! Check your share options.'
                    .tr),
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
                Text(vm.errorMessage ?? 'Error exporting invoices'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(
      BuildContext context, ExportImportViewModel vm) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls', 'csv', 'json', 'pdf'],
        withData: false,
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final kindLabel = vm.selectedKind == ImportDataKind.purchase
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Import'.tr),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;

      final importResult =
          await vm.importData(filePath, vm.selectedKind);
      if (!context.mounted) return;

      if (importResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Import failed'.tr),
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
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    importResult.matchedHeaders.join(', '),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (importResult.unmatchedHeaders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Ignored columns (no field match):'.tr,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    importResult.unmatchedHeaders.join(', '),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                if (importResult.errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Errors:'.tr,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
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
                Navigator.pop(context);
                Navigator.pop(context, true);
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
