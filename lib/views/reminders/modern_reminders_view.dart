import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../models/invoice_reminder_model.dart';
import '../../widgets/list_skeleton.dart';
import '../../constants/app_translations.dart';

/// Modern UI surface for the Invoice Reminders screen.
///
/// Same `ReminderViewModel`, same load + cancel-with-confirm flow.
/// Only the visual layer is restyled.
class ModernRemindersContent extends StatelessWidget {
  const ModernRemindersContent({super.key});

  // Website tokens
  static const _bg0 = Color(0xFF07091C);
  static const _bg1 = Color(0xFF0C1230);
  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  // Status colors
  static const _amber = Color(0xFFFBBF24);
  static const _rose = Color(0xFFFCA5A5);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);

  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _accent, _violet],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReminderViewModel>();
    final reminders = vm.reminders.where((r) => r.isActive).toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

    return Scaffold(
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, vm),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: vm.isLoading
                ? const ListSkeleton(dark: true)
                : reminders.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: _accent,
                        backgroundColor: _bg1,
                        onRefresh: () => vm.loadReminders(),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: reminders.length,
                          itemBuilder: (context, index) =>
                              _reminderCard(context, reminders[index], vm),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ReminderViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          'Invoice Reminders'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh'.tr,
          onPressed: () => vm.loadReminders(),
        ),
      ],
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

  // ─────────────────────────────  EMPTY STATE  ────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: _grad,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              'No Active Reminders'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set reminders for your invoices to get notified'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────  REMINDER CARD  ──────────────────────────

  Widget _reminderCard(
      BuildContext context, InvoiceReminder reminder, ReminderViewModel vm) {
    final dateFormat = DateFormat('dd MMM yyyy'.tr);
    final timeFormat = DateFormat('hh:mm a'.tr);
    final now = DateTime.now();
    final isOverdue = reminder.reminderDate.isBefore(now);
    final isDueSoon =
        !isOverdue && reminder.reminderDate.difference(now).inHours < 24;

    final statusColor = isOverdue
        ? _rose
        : isDueSoon
            ? _amber
            : _accent;
    final statusGradient = isOverdue
        ? const [_red, Color(0xFFF87171)]
        : isDueSoon
            ? const [_amber, _orange]
            : const [_primary, _accent];
    final statusIcon = isOverdue
        ? Icons.warning_rounded
        : isDueSoon
            ? Icons.schedule_rounded
            : Icons.notifications_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isOverdue || isDueSoon)
              ? statusColor.withOpacity(0.45)
              : Colors.white.withOpacity(0.08),
          width: (isOverdue || isDueSoon) ? 1.5 : 1,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: statusGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: statusGradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.buyerName.isNotEmpty
                          ? reminder.buyerName
                          : 'Unnamed Buyer'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'Invoice'.tr}: ${reminder.invoiceNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      _handleCancel(context, reminder, vm),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.30)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'Reminder'.tr}: ${dateFormat.format(reminder.reminderDate)} ${'at'.tr} ${timeFormat.format(reminder.reminderDate)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'Due Date'.tr}: ${dateFormat.format(reminder.dueDate)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue || isDueSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: statusColor.withOpacity(0.45)),
                    ),
                    child: Text(
                      isOverdue ? 'Overdue'.tr : 'Due Soon'.tr,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context,
      InvoiceReminder reminder, ReminderViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Reminder'.tr),
        content: Text('Are you sure you want to cancel this reminder?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, Cancel'.tr),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final success = await vm.cancelReminder(reminder.notificationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Reminder cancelled'.tr
                : 'Failed to cancel reminder'.tr),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
