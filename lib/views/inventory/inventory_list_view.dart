import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/inventory_model.dart';
import '../../viewmodels/inventory_viewmodel.dart';

import '../../widgets/ads/native_ad_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/paywall_dialog.dart';
import '../../services/quota_service.dart';
import '../subscription/subscription_plans_view.dart';
import 'inventory_form_view.dart';
import '../../constants/app_translations.dart';


class InventoryListView extends StatefulWidget {
  const InventoryListView({super.key});

  @override
  State<InventoryListView> createState() => _InventoryListViewState();
}

class _InventoryListViewState extends State<InventoryListView>
    with AutomaticKeepAliveClientMixin {

  late final InventoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InventoryViewModel()..loadItems();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider<InventoryViewModel>.value(
      value: _viewModel,
      child: const _InventoryListViewContent(),
    );
  }
}

class _InventoryListViewContent extends StatefulWidget {
  const _InventoryListViewContent();

  @override
  State<_InventoryListViewContent> createState() => _InventoryListViewContentState();
}

class _InventoryListViewContentState extends State<_InventoryListViewContent> {
  final Color _accent = const Color(0xFF4F8AF4);
  final Color _deepAccent = const Color(0xFF1E3C72);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InventoryViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy'.tr);

    // Filter items based on search query
    final filteredItems = _searchQuery.isEmpty
        ? viewModel.items
        : viewModel.items.where((item) {
            final query = _searchQuery.toLowerCase();
            return item.invoiceNumber.toLowerCase().contains(query) ||
                (item.description?.toLowerCase() ?? '').contains(query);
          }).toList();

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
                child: Icon(Icons.inventory_2_rounded, color: _accent),
              ),
              const SizedBox(width: 10),
              Text('Inventory'.tr),
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
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(viewModel),
                Expanded(
                  child: viewModel.isLoading
                      ? const ListSkeleton(dense: true)
                      : filteredItems.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => viewModel.loadItems(),
                              child: _buildInventoryListWithAds(
                                context,
                                viewModel,
                                filteredItems,
                                currencyFormat,
                                dateFormat,
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _startNewInventory(context, viewModel),
            icon: const Icon(Icons.add_rounded),
            label: Text('Add Inventory'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 8,
              shadowColor: _accent.withOpacity(0.4),
            ),
          ),
        ),
      ),

    );
  }

  Future<void> _startNewInventory(BuildContext context, InventoryViewModel viewModel) async {
    final canAdd = await QuotaService().canAddEntry(true); // Inventory counted as purchase entry
    if (!canAdd && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => PaywallDialog(
          message: 'You have reached your monthly limit for adding inventory. Please upgrade your plan to continue adding unlimited entries.'.tr,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryFormView(),
      ),
    );
    if (result == true && context.mounted) {
      viewModel.loadItems();
    }
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

  Widget _buildSearchBar(InventoryViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E3C72),
        ),
        decoration: InputDecoration(
          hintText: 'Search inventory...'.tr,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search_rounded,
                color: _accent,
                size: 20,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 56,
            minHeight: 38,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 38,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
          filled: false,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No inventory items yet'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first diamond stock to get started'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Native ad cadence — same constant used across the app's lists.
  static const int _adInterval = 7;

  Widget _buildInventoryListWithAds(
    BuildContext context,
    InventoryViewModel viewModel,
    List<InventoryModel> filteredItems,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final adCount = filteredItems.length ~/ _adInterval;
    // +1 for the totals footer row.
    final totalSlots = filteredItems.length + adCount + 1;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        // Footer always last.
        if (index == totalSlots - 1) {
          return _buildTotalsFooter(viewModel, currencyFormat);
        }
        const groupSize = _adInterval + 1;
        final positionInGroup = index % groupSize;
        if (positionInGroup == _adInterval) {
          return const NativeAdCard();
        }
        final itemIndex =
            (index ~/ groupSize) * _adInterval + positionInGroup;
        if (itemIndex >= filteredItems.length) {
          return const SizedBox.shrink();
        }
        return _buildInventoryCard(
          context,
          filteredItems[itemIndex],
          viewModel,
          currencyFormat,
          dateFormat,
        );
      },
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    InventoryModel item,
    InventoryViewModel viewModel,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryFormView(item: item),
            ),
          );
          if (result == true && context.mounted) {
            viewModel.loadItems();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.diamond_rounded, color: _accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.invoiceNumber.isNotEmpty ? item.invoiceNumber : 'No Invoice Number'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'Invoice Date'.tr}: ${dateFormat.format(item.invoiceDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit'.tr,
                        child: Row(
                          children: [
                            const Icon(Icons.edit_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Edit'.tr),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete'.tr,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Delete'.tr, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit'.tr) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventoryFormView(item: item),
                          ),
                        );
                        if (result == true && context.mounted) {
                          viewModel.loadItems();
                        }
                      } else if (value == 'delete'.tr) {
                        _confirmDelete(context, item, viewModel);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Carat'.tr,
                        '${item.carat.toStringAsFixed(2)} ct',
                        Icons.scale_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Price/Carat'.tr,
                        currencyFormat.format(item.pricePerCarat),
                        Icons.currency_rupee_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Total'.tr,
                        currencyFormat.format(item.totalPrice),
                        Icons.account_balance_wallet_rounded,
                        isTotal: true,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {bool isTotal = false}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: isTotal ? Colors.green : _accent),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? Colors.green.shade800 : _deepAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsFooter(InventoryViewModel viewModel, NumberFormat currencyFormat) {
    final totalCarat = viewModel.totalCarat;
    final totalValue = viewModel.totalValue;
    final remainingCarat = viewModel.remainingTotalCarat;
    final remainingAmount = viewModel.remainingTotalAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory totals'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Total Carat'.tr,
                  '${totalCarat.toStringAsFixed(2)} ct',
                  Icons.scale_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey[300]),
              Expanded(
                child: _buildInfoItem(
                  'Total Amount'.tr,
                  currencyFormat.format(totalValue),
                  Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Remaining Carat'.tr,
                  '${remainingCarat.toStringAsFixed(2)} ct',
                  Icons.scale_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey[300]),
              Expanded(
                child: _buildInfoItem(
                  'Remaining Amount'.tr,
                  currencyFormat.format(remainingAmount),
                  Icons.account_balance_wallet_rounded,
                  isTotal: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, InventoryModel item, InventoryViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Inventory Item'.tr),
        content: Text('${'Are you sure you want to delete invoice'.tr} "${item.invoiceNumber.isNotEmpty ? item.invoiceNumber : 'this item'.tr}"? ${'This action cannot be undone.'.tr}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.deleteItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Item deleted successfully'.tr : 'Failed to delete item'.tr),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
