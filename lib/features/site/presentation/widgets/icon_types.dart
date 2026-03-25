import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class BleIconWidget extends StatelessWidget {
  final MapIconModel icon;
  final int humanCount;
  final VoidCallback onTap;

  const BleIconWidget({
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: humanCount > 0 ? AppTheme.success : AppTheme.textSecondary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: humanCount > 0 ? AppTheme.success : AppTheme.textSecondary,
              size: 20,
            ),
          ),
          if (humanCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTheme.danger,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$humanCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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