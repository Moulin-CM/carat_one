import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../models/invoice_reminder_model.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReminderViewModel(),
      child: const _RemindersViewContent(),
    );
  }
}

class _RemindersViewContent extends StatelessWidget {
  const _RemindersViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReminderViewModel>();
    final reminders = viewModel.reminders.where((r) => r.isActive).toList();
    reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

    final Color _accent = const Color(0xFF4F8AF4);
    final Color _deepAccent = const Color(0xFF1E3C72);

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
                child: Icon(Icons.notifications_active_rounded, color: _accent),
              ),
              const SizedBox(width: 10),
              const Text('Invoice Reminders'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => viewModel.loadReminders(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackdrop(_accent, _deepAccent),
          SafeArea(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reminders.isEmpty
                    ? _buildEmptyState(_accent, _deepAccent)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.loadReminders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: reminders.length,
                          itemBuilder: (context, index) {
                            return _buildReminderCard(context, reminders[index], viewModel, _accent, _deepAccent);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop(Color accent, Color deepAccent) {
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
            child: _blurredCircle(220, accent.withOpacity(0.22)),
          ),
          Positioned(
            top: 140,
            left: -90,
            child: _blurredCircle(200, deepAccent.withOpacity(0.12)),
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

  Widget _buildEmptyState(Color accent, Color deepAccent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.notifications_none_rounded, size: 54, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Reminders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: deepAccent),
          ),
          const SizedBox(height: 6),
          Text(
            'Set reminders for your invoices to get notified',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    InvoiceReminder reminder,
    ReminderViewModel viewModel,
    Color accent,
    Color deepAccent,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isOverdue = reminder.reminderDate.isBefore(DateTime.now());
    final isDueSoon = reminder.reminderDate.difference(DateTime.now()).inHours < 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade200
              : isDueSoon
                  ? Colors.orange.shade200
                  : Colors.white.withOpacity(0.8),
          width: isOverdue || isDueSoon ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverdue
                      ? Icons.warning_rounded
                      : isDueSoon
                          ? Icons.schedule_rounded
                          : Icons.notifications_rounded,
                  color: isOverdue
                      ? Colors.red
                      : isDueSoon
                          ? Colors.orange
                          : accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.buyerName.isNotEmpty ? reminder.buyerName : 'Unnamed Buyer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${reminder.invoiceNo}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancel Reminder'),
                      content: const Text('Are you sure you want to cancel this reminder?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Yes, Cancel'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    final success = await viewModel.cancelReminder(reminder.notificationId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Reminder cancelled' : 'Failed to cancel reminder'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                color: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOverdue
                  ? Colors.red.shade50
                  : isDueSoon
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: isOverdue
                      ? Colors.red.shade700
                      : isDueSoon
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder: ${dateFormat.format(reminder.reminderDate)} at ${timeFormat.format(reminder.reminderDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? Colors.red.shade700
                              : isDueSoon
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due Date: ${dateFormat.format(reminder.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

