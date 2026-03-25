import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class BleSumIconWidget extends StatelessWidget {
  final MapIconModel icon;
  final int humanCount;
  final VoidCallback onTap;

  const BleSumIconWidget({
    super.key,
    required this.icon,
    required this.humanCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.groups, color: AppTheme.primary, size: 24),
          ),
          if (humanCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.warning,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$humanCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
