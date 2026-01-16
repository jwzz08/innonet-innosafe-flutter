import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});
  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SearchField(hint: "Search alerts..."),
                const SizedBox(height: 12),
                FilterBar(
                  filters: const ["All", "Active", "Critical", "Resolved"],
                  selectedFilter: _selectedFilter,
                  onSelect: (val) => setState(() => _selectedFilter = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if(_selectedFilter == "All" || _selectedFilter == "Critical")
                  _buildAlertItem("emergency button", "월판 현장", "2m ago", AppTheme.danger, "Active"),
                if(_selectedFilter == "All" || _selectedFilter == "Active")
                  _buildAlertItem("ShortTerm O2 Alarm", "월판 현장", "15m ago", AppTheme.warning, "Ack"),
                if(_selectedFilter == "All" || _selectedFilter == "Resolved")
                  _buildAlertItem("Normal O2 Alarm", "월판 현장", "1h ago", AppTheme.success, "Resolved"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String sub, String time, Color color, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}