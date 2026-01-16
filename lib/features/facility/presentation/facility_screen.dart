import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});
  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  String _selectedFilter = "All";

  // main.dart에 있던 기존 데이터 유지
  final List<Map<String, dynamic>> _items = [
    {"name": "TVWS", "type": "Equipment", "zone": "Zone A", "status": "Active", "time": "5m ago"},
    {"name": "Temp Sensor", "type": "Sensor", "zone": "Zone A", "status": "Active", "time": "1m ago"},
    {"name": "홍길동길동", "type": "Worker", "zone": "Zone B", "status": "Active", "time": "Just now"},
    {"name": "Drill Machine", "type": "Equipment", "zone": "Zone D", "status": "Active", "time": "3m ago"},
    {"name": "Gas Sensor", "type": "Sensor", "zone": "Zone C", "status": "Active", "time": "10m ago"},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedFilter == "All" ? _items : _items.where((i) => i['type'] == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Facility")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const SearchField(hint: "Search equipment, sensors..."),
                const SizedBox(height: 12),
                FilterBar(
                  filters: const ["All", "Equipment", "Sensor", "Worker"],
                  selectedFilter: _selectedFilter,
                  onSelect: (val) => setState(() => _selectedFilter = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                IconData icon = Icons.help;
                if (item['type'] == 'Equipment') icon = Icons.handyman;
                if (item['type'] == 'Sensor') icon = Icons.sensors;
                if (item['type'] == 'Worker') icon = Icons.person;

                return DarkCard(
                  onTap: () {},
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.surfaceHighlight, borderRadius: BorderRadius.circular(8)),
                        child: Icon(icon, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("${item['zone']} • ${item['type']}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: AppTheme.success),
                                const SizedBox(width: 4),
                                Text(item['status'], style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      Text(item['time'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}