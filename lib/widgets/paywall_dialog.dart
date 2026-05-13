import 'package:flutter/material.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import '../views/subscription/subscription_plans_view.dart';


class PaywallDialog extends StatelessWidget {
  final String message;
  const PaywallDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text('Limit Reached'.tr),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Maybe Later'.tr),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionPlansView()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('Upgrade Now'.tr),
        ),
      ],
    );
  }
}
