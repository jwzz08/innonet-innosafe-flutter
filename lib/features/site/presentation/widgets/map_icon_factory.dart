import 'package:flutter/material.dart';
import 'package:innosafe/features/site/presentation/widgets/total_sum_badge.dart';
import 'package:innosafe/features/site/presentation/widgets/tvws_icon_widget.dart';
import '../../data/model/dashboard_models.dart';
import 'ble_sum_icon_widget.dart';
import 'equipment_sum_badge.dart';
import 'excavation_rate_bar.dart';
import 'icon_types.dart';
import 'material_sum_badge.dart';

class MapIconFactory {
  // ✅ 웹 기준 크기 (백엔드 계산 기준)
  static const double webBaseWidth = 2000.0;
  static const double webBaseHeight = 500.0;

  /// 아이콘 타입에 따라 적절한 위젯 반환
  static Widget buildIcon({
    required MapIconModel icon,
    required int humanCount,
    required double imageWidth,
    required double imageHeight,
    required VoidCallback onTap,
  }) {
    // ✅ 1단계: Percent → 웹 픽셀
    final webX = (icon.xPercent / 100) * webBaseWidth;
    final webY = (icon.yPercent / 100) * webBaseHeight;

    // ✅ 2단계: 웹 픽셀 → 앱 픽셀 (비율 변환)
    final appX = (webX / webBaseWidth) * imageWidth;
    final appY = (webY / webBaseHeight) * imageHeight;

    switch (icon.type.toLowerCase()) {
      case 'ble':
      // ✅ 웹: 좌상단 기준 (40x40 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: BleIconWidget(
            icon: icon,
            humanCount: humanCount,
            onTap: onTap,
          ),
        );

      case 'blesum':
      // ✅ 웹: 좌상단 기준 (60x60 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: BleSumIconWidget(
            icon: icon,
            humanCount: humanCount,
            onTap: onTap,
          ),
        );

      case 'totalsum':
      // ✅ 웹: 좌상단 기준 (250x150 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: TotalSumBadge(
            icon: icon,
            totalCount: humanCount,
            onTap: onTap,
          ),
        );

      case 'equipmentsum':
      // ✅ 웹: 좌상단 기준 (60x60 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: EquipmentSumBadge(
            icon: icon,
            equipmentCount: icon.equipmentNames.length,
            onTap: onTap,
          ),
        );

      case 'materialsum':
      // ✅ 웹: 좌상단 기준 (60x60 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: MaterialSumBadge(
            icon: icon,
            materialCount: icon.materialNames.length,
            onTap: onTap,
          ),
        );

      case 'excavationrate':
      // ✅ 웹: 좌상단 기준 (700x80 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: ExcavationRateBar(
            icon: icon,
            onTap: onTap,
          ),
        );

      case 'master':
      case 'slave':
      // ✅ 웹: 좌상단 기준 (24x60 컨테이너)
        return Positioned(
          left: appX,
          top: appY,
          child: TvwsIconWidget(
            icon: icon,
            isMaster: icon.type.toLowerCase() == 'master',
            onTap: onTap,
          ),
        );

      default:
      // 알 수 없는 타입
        return Positioned(
          left: appX - 16,
          top: appY - 16,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: const Icon(Icons.help_outline, color: Colors.white, size: 16),
            ),
          ),
        );
    }
  }
}