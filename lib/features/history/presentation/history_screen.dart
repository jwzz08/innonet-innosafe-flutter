import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("History"),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: TabBar(tabs: [Tab(text: "Alarm History"), Tab(text: "Event History")]),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAlarmList(),
            _buildEventList(),
          ],
        ),
      ),
    );
  }

  // 알람 리스트 빌드 (Alarm Tab)
  Widget _buildAlarmList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Showing recent alarms", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.filter_list, size: 14),
                label: const Text("Filter", style: TextStyle(fontSize: 12)),
              )
            ],
          ),
        ),
        _buildDateGroup("Dec 10, 2025", [
          _buildHistoryCard(
            title: "ShortTerm O2 Alarm",
            badgeText: "CRITICAL",
            time: "22:46:18",
            desc: "GAS Sensor S2 :: ShortTerm O2 Alarm",
            location: "Site Group: 월판 현장",
            icon: Icons.warning_amber_rounded,
            color: AppTheme.danger,
          ),
          _buildHistoryCard(
            title: "Normal O2 Alarm",
            badgeText: "CRITICAL",
            time: "22:23:41",
            desc: "GAS Vent S5 :: Normal O2 Alarm",
            location: "Site Group: 월판 현장",
            icon: Icons.error_outline,
            color: AppTheme.danger,
          ),
        ]),
      ],
    );
  }

  // 이벤트 리스트 빌드 (Event Tab)
  Widget _buildEventList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Showing recent events", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.filter_list, size: 14),
                label: const Text("Filter", style: TextStyle(fontSize: 12)),
              )
            ],
          ),
        ),
        _buildDateGroup("Dec 23, 2025", [
          _buildHistoryCard(
            title: "EXIT",
            badgeText: "EVENT",
            time: "05:04:40",
            desc: "Worker ID: 385 • TEAM: 이노넷",
            location: "GAS 추가작업구 S2",
            icon: Icons.exit_to_app,
            color: const Color(0xFF3B82F6),
          ),
          _buildHistoryCard(
            title: "LOCATION_CHANGED",
            badgeText: "EVENT",
            time: "05:04:11",
            desc: "Worker ID: 413 • TEAM: 협력업체",
            location: "GAS 환기구 S5",
            icon: Icons.swap_horiz,
            color: AppTheme.success,
          ),
        ]),
      ],
    );
  }

  Widget _buildDateGroup(String date, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: AppTheme.border)),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String badgeText,
    required String time,
    required String desc,
    required String location,
    required IconData icon,
    required Color color,
  }) {
    final bool isAlarm = badgeText != "EVENT";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badgeText, style: TextStyle(color: isAlarm ? color : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Text(desc, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(isAlarm ? Icons.location_on : Icons.settings_input_antenna, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}