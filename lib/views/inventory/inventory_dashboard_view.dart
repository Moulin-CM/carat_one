import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/inventory_viewmodel.dart';

import '../../widgets/list_skeleton.dart';
import 'inventory_list_view.dart';
import 'inventory_form_view.dart';
import '../../constants/app_translations.dart';


import 'package:invoice_generator/constants/app_translations.dart';

class InventoryDashboardView extends StatelessWidget {
  const InventoryDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryViewModel()..loadItems(),
      child: const _InventoryDashboardViewContent(),
    );
  }
}

class _InventoryDashboardViewContent extends StatelessWidget {
  const _InventoryDashboardViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InventoryViewModel>();
    const accent = Color(0xFF4F8AF4);
    const deepAccent = Color(0xFF1E3C72);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    if (viewModel.isLoading) {
      return const Scaffold(body: ListSkeleton());
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
                child: Icon(Icons.dashboard_rounded, color: accent),
              ),
              const SizedBox(width: 10),
              Text('Inventory Dashboard'.tr),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => viewModel.loadItems(),
            tooltip: 'Refresh'.tr,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackdrop(accent, deepAccent),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => viewModel.loadItems(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(context, viewModel, accent, deepAccent, currencyFormat),
                    const SizedBox(height: 20),
                    _buildRecentItems(context, viewModel, accent, deepAccent, currencyFormat),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, accent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryFormView()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Stock'.tr),
        backgroundColor: accent,
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

  Widget _buildStatsCards(
    BuildContext context,
    InventoryViewModel viewModel,
    Color accent,
    Color deepAccent,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Items'.tr,
                viewModel.totalItems.toString(),
                Icons.inventory_2_rounded,
                accent,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Carat'.tr,
                viewModel.totalCarat.toStringAsFixed(2),
                Icons.scale_rounded,
                Colors.orange,
                deepAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Value'.tr,
                currencyFormat.format(viewModel.totalValue),
                Icons.currency_rupee_rounded,
                Colors.green,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Price/Carat'.tr,
                currencyFormat.format(viewModel.averagePricePerCarat),
                Icons.trending_up_rounded,
                Colors.purple,
                deepAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month'.tr,
                viewModel.thisMonthItems.toString(),
                Icons.calendar_month_rounded,
                Colors.blue,
                deepAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Month Value'.tr,
                currencyFormat.format(viewModel.thisMonthValue),
                Icons.account_balance_wallet_rounded,
                Colors.teal,
                deepAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color deepAccent) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: deepAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItems(
    BuildContext context,
    InventoryViewModel viewModel,
    Color accent,
    Color deepAccent,
    NumberFormat currencyFormat,
  ) {
    final recent = viewModel.recentItems;
    final dateFormat = DateFormat('dd MMM yyyy'.tr);

    return Container(
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F7FB),
                ),
                child: Icon(Icons.history_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Items'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No inventory items yet'.tr,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...recent.take(5).map((item) => _buildRecentItemCard(
                  context,
                  item,
                  dateFormat,
                  currencyFormat,
                  accent,
                  deepAccent,
                )),
          if (recent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryListView()),
                    );
                  },
                  child: Text('View All Items'.tr),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentItemCard(
    BuildContext context,
    item,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
    Color accent,
    Color deepAccent,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventoryFormView(item: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.diamond_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.invoiceNumber.isNotEmpty ? item.invoiceNumber : 'No Invoice Number'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${dateFormat.format(item.invoiceDate)} • ${item.carat.toStringAsFixed(2)} ct'.tr,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              currencyFormat.format(item.totalPrice),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: deepAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color accent) {
    return Container(
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F7FB),
                ),
                child: Icon(Icons.flash_on_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Add Stock'.tr,
                  Icons.add_rounded,
                  accent,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryFormView()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'All Items'.tr,
                  Icons.list_rounded,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryListView()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

