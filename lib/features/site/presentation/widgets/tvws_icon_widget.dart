import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class TvwsIconWidget extends StatelessWidget {
  final MapIconModel icon;
  final bool isMaster;
  final VoidCallback onTap;

  const TvwsIconWidget({
    super.key,
    required this.icon,
    required this.isMaster,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ✅ 변경: 명시적 크기 지정 (세로로 1.5배 길쭉하게)
        width: 40,
        height: 60,
        // ✅ 변경: padding을 상하 더 크게 조정
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          // ✅ 변경: shape: BoxShape.circle → borderRadius로 변경
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMaster ? AppTheme.primary : const Color(0xFF64D2FF),
            width: 2,
          ),
        ),
        // ✅ 변경: Icon을 Column으로 감싸서 중앙 정렬
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMaster ? Icons.router : Icons.cell_tower,
              color: isMaster ? AppTheme.primary : const Color(0xFF64D2FF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}