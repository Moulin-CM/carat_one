import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../models/subscription_plan.dart';
import '../views/subscription/subscription_plans_view.dart';

class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionViewModel>(
      builder: (context, viewModel, child) {
        final status = viewModel.status;
        
        if (status.plan != SubscriptionTier.trial || !status.isActive) {
          if (status.plan == SubscriptionTier.expired) {
            return _buildBanner(
              context,
              'Your trial has expired. Subscribe to continue using all features.',
              Colors.red.shade800,
              true,
            );
          }
          return const SizedBox.shrink();
        }

        final daysLeft = status.trialEndsAt?.difference(DateTime.now()).inDays ?? 0;
        if (daysLeft > 7) return const SizedBox.shrink();

        return _buildBanner(
          context,
          '⏳ $daysLeft days left in your free trial. Upgrade now for unlimited access!',
          daysLeft <= 2 ? Colors.orange.shade900 : Colors.blue.shade800,
          false,
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context, String message, Color color, bool isUrgent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPlansView()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View Plans',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
