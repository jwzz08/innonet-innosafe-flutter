import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Media & Broadcast"),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: "Live Stream", icon: Icon(Icons.live_tv)),
              Tab(text: "CCTV / RTSP", icon: Icon(Icons.videocam)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlaceholder("Broadcast Server Connection\n(WebSocket)"),
            _buildPlaceholder("RTSP Camera List\n(Select Camera to View)"),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.developer_board_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}