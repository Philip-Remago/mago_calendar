import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    this.primaryWidget,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final Widget? primaryWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 10),
          primaryWidget ??
              ElevatedButton(
                onPressed: onPrimaryPressed,
                child: Text(primaryLabel),
              ),
          const SizedBox(height: 6),
          Text(secondaryLabel, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
