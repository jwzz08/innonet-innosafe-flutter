import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class CompanyManagementScreen extends StatelessWidget {
  const CompanyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Company Management"),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(36),
            child: TabBar(tabs: [Tab(text: "Company"), Tab(text: "Team"), Tab(text: "Worker")]),
          ),
        ),
        body: const TabBarView(
          children: [
            SimpleListTab(type: "Company"),
            SimpleListTab(type: "Team"),
            SimpleListTab(type: "Worker"),
          ],
        ),
      ),
    );
  }
}

class SimpleListTab extends StatelessWidget {
  final String type;
  const SimpleListTab({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    // main.dart의 SimpleListTab 로직 그대로 사용
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (context, index) {
        return DarkCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text("$type Name ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text("ID: #829${index} • Active", style: const TextStyle(color: AppTheme.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ),
        );
      },
    );
  }
}