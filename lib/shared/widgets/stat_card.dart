import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color? iconColor;
  final bool isAlert;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subValue,
    required this.icon,
    this.iconColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isAlert ? Border.all(color: AppTheme.danger.withOpacity(0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 20),
              if (isAlert)
                const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 16),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(subValue!, style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }
}