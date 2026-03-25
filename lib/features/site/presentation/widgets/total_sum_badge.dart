import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class TotalSumBadge extends StatelessWidget {
  final MapIconModel icon;
  final int totalCount;
  final VoidCallback onTap;

  const TotalSumBadge({
    super.key,
    required this.icon,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '$totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}