import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../widgets/site_map_layout.dart';

class SiteMonitoringTab extends StatelessWidget {
  const SiteMonitoringTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 맵의 원본 비율/크기 설정
    const double originalMapWidth = 2000;
    const double originalMapHeight = 1000;

    return Column(
      children: [
        // 1. 상단 지도 영역 (Structure 탭에 있던 방식 그대로 이식)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0B0D10),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            // FittedBox를 사용하여 비율 유지하며 맵 표시
            child: const FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SiteMapLayout(width: originalMapWidth, height: originalMapHeight),
            ),
          ),
        ),

        // 2. 리스트 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                  "Zone Monitoring List",
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  )
              ),
              Row(
                children: [
                  const Text("Filter", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.filter_list, color: AppTheme.textSecondary, size: 18),
                ],
              )
            ],
          ),
        ),

        // 3. 하단 구역 리스트 (Structure 탭에 있던 리스트 로직)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 8,
            itemBuilder: (context, index) {
              final String zoneChar = String.fromCharCode(65 + index);

              return DarkCard(
                onTap: () {
                  // 상세 이동 로직 등
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40, height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(
                        zoneChar,
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(
                      "Monitoring Zone $zoneChar",
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        "Sensors: ${2 + index} • Workers: ${3 + index}",
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}