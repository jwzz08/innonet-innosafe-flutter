import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/provider/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Stub (main.dart 데이터 유지)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: AppTheme.surfaceHighlight, child: Icon(Icons.person, color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("superadmin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("superadmin@innonet.com", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text("Edit"))
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("Management", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // [New] Company Management Link (Moved from Bottom Tab)
          _buildSettingsTile(
              context,
              icon: Icons.business,
              title: "Company Management",
              subtitle: "Manage Companies, Teams, Workers",
              onTap: () {
                // 라우터 설정 필요: /settings/company
                context.push('/settings/company');
              }
          ),

          const SizedBox(height: 24),
          const Text("General", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // History Screen Link
          _buildSettingsTile(
              context,
              icon: Icons.history,
              title: "History Logs",
              subtitle: "View alarm and event history",
              onTap: () {
                // 라우터 설정 필요: /settings/history
                context.push('/settings/history');
              }
          ),

          _buildSettingsTile(context, icon: Icons.notifications, title: "Notification Settings", subtitle: "Manage push alerts"),
          _buildSettingsTile(context, icon: Icons.language, title: "Language", subtitle: "English"),

          const SizedBox(height: 24),
          const Text("System", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSettingsTile(context, icon: Icons.info_outline, title: "About App", subtitle: "Version 1.0.0"),

          // Logout Logic
          _buildSettingsTile(
              context,
              icon: Icons.logout,
              title: "Log Out",
              color: AppTheme.danger,
              onTap: () {
                ref.read(authProvider.notifier).logout();
              }
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    VoidCallback? onTap
  }) {
    return DarkCard(
      onTap: onTap ?? () {},
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.border, size: 18),
        ],
      ),
    );
  }
}