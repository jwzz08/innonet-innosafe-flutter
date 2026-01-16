import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

class SiteOverviewTab extends StatelessWidget {
  const SiteOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Metric Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: const [
            MetricCard(title: "O2 Level", value: "20.9%", trend: "Normal", icon: Icons.air, color: AppTheme.success),
            MetricCard(title: "Gas (CO)", value: "0 ppm", trend: "-0.0", icon: Icons.cloud, color: AppTheme.success),
            MetricCard(title: "H2S", value: "2 ppm", trend: "Warning", icon: Icons.warning, color: AppTheme.warning),
            MetricCard(title: "LEL", value: "0 %", trend: "Safe", icon: Icons.check_circle, color: AppTheme.primary),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Recent Alerts List
        const Text("Recent Alerts", style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildAlertItem("ShortTerm O2 Alarm", "GAS 추가작업구 S2", "Dec 25", AppTheme.danger),
        _buildAlertItem("Normal O2 Alarm", "GAS 환기구", "Dec 10", AppTheme.warning),
        _buildAlertItem("Emergency Button", "월판 현장", "Dec 10", AppTheme.primary),
      ],
    );
  }

  Widget _buildAlertItem(String title, String loc, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(loc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}