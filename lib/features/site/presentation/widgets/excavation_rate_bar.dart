import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class ExcavationRateBar extends StatelessWidget {
  final MapIconModel icon;
  final VoidCallback onTap;

  const ExcavationRateBar({
    super.key,
    required this.icon,
    required this.onTap,
  });

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = icon.progressValue / 100;
    final targetColor = _parseColor(icon.targetColor);
    final progressColor = _parseColor(icon.progressColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: icon.sizeX,
        height: icon.sizeY,
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          children: [
            // 배경
            Container(
              decoration: BoxDecoration(
                color: progressColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // 진행 바
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: targetColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // 텍스트
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon.title.isNotEmpty)
                    Text(
                      icon.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    '${icon.progressValue.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}