import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../viewmodels/export_import_viewmodel.dart';
import '../../services/export_import_service.dart';

class ExportImportView extends StatelessWidget {
  const ExportImportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExportImportViewModel(),
      child: const _ExportImportViewContent(),
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
              const Text('Export / Import'),
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
                    title: 'Export Invoices',
                    icon: Icons.upload_file_rounded,
                    description: 'Export all your invoices to a JSON backup file',
                    children: [
                      _buildInfoCard(
                        'This will create a backup file containing all your invoices. You can share this file or save it for later restoration.',
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
                            viewModel.isExporting ? 'Exporting...' : 'Export All Invoices',
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
                    title: 'Import Invoices',
                    icon: Icons.file_upload_rounded,
                    description: 'Import invoices from a backup file',
                    children: [
                      _buildInfoCard(
                        'Select a backup file (JSON format) to import invoices. Existing invoices will not be overwritten.',
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
                            viewModel.isImporting ? 'Importing...' : 'Import from Backup',
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
                    title: 'Backup Information',
                    icon: Icons.description_rounded,
                    children: [
                      _buildInfoCard(
                        '• Backup files are in JSON format\n'
                        '• All invoice data is included\n'
                        '• Files can be shared across devices\n'
                        '• Imported invoices get new IDs to avoid conflicts',
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
          const SnackBar(
            content: Text('Invoices exported successfully! Check your share options.'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          viewModel.clearMessages();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error exporting invoices'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context, ExportImportViewModel viewModel) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Invoices'),
            content: Text(
              'This will import invoices from the selected backup file.\n\n'
              'File: ${result.files.single.name}\n\n'
              'Existing invoices will not be overwritten. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          final importResult = await viewModel.importInvoices(filePath);
          
          if (context.mounted) {
            if (importResult != null) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Import Complete'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${importResult.totalCount} invoices'),
                      Text('Success: ${importResult.successCount}'),
                      if (importResult.errorCount > 0)
                        Text('Errors: ${importResult.errorCount}', style: const TextStyle(color: Colors.red)),
                      if (importResult.errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...importResult.errors.take(3).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
                      ],
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, true); // Return to previous screen with refresh flag
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage ?? 'Error importing invoices'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

