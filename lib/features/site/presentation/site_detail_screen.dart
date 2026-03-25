import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'tabs/site_overview_tab.dart';
import 'tabs/site_monitoring_tab.dart';
import 'tabs/site_structure_sidetab.dart';
import '../data/repository/site_repository.dart';
import '../data/model/dashboard_models.dart';

/// 현장 카드 클릭 후 진입하는 상세 화면
/// route: /site-detail
/// extra: { siteId, siteName, dashboardId, dashboardName }
class SiteDetailScreen extends ConsumerStatefulWidget {
  final int siteId;
  final String siteName;
  final int dashboardId;
  final String dashboardName;

  const SiteDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.dashboardId,
    required this.dashboardName,
  });

  @override
  ConsumerState<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends ConsumerState<SiteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 현재 선택된 dashboard (다른 작업구로 전환 가능)
  late int _currentDashboardId;
  late String _currentDashboardName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentDashboardId = widget.dashboardId;
    _currentDashboardName = widget.dashboardName;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 작업구 전환 (같은 현장 내에서)
  void _switchDashboard(int dashboardId, String dashboardName) {
    setState(() {
      _currentDashboardId = dashboardId;
      _currentDashboardName = dashboardName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardListAsync = ref.watch(dashboardListProvider(widget.siteId));

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: isLandscape
              ? null
              : AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: _buildTitleWithDashboardPicker(context, dashboardListAsync),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Monitoring'),
                Tab(text: 'Structure'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const SiteOverviewTab(),
              const SiteMonitoringTab(),
              SiteStructureSideTab(
                siteId: widget.siteId,
                dashboardId: _currentDashboardId,
              ),
            ],
          ),
        );
      },
    );
  }

  /// AppBar 타이틀: 현장명 + 작업구 선택 드롭다운
  Widget _buildTitleWithDashboardPicker(
      BuildContext context,
      AsyncValue dashboardListAsync,
      ) {
    return dashboardListAsync.when(
      data: (dashboards) {
        // 작업구가 1개면 그냥 이름만 표시
        if (dashboards.length <= 1) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.siteName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _currentDashboardName,
                style: const TextStyle(color: AppTheme.primary, fontSize: 12),
              ),
            ],
          );
        }

        // 작업구가 여러 개면 드롭다운
        return PopupMenuButton<DashboardSummaryModel>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: AppTheme.surfaceHighlight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.siteName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentDashboardName,
                    style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 16),
                ],
              ),
            ],
          ),
          onSelected: (DashboardSummaryModel dashboard) {
            _switchDashboard(dashboard.id, dashboard.name);
          },
          itemBuilder: (context) {
            return (dashboards as List<DashboardSummaryModel>).map((dashboard) {
              final isSelected = dashboard.id == _currentDashboardId;
              return PopupMenuItem<DashboardSummaryModel>(
                value: dashboard,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.dashboard_outlined,
                      size: 16,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dashboard.name,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
      loading: () => Text(
        widget.siteName,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      error: (_, __) => Text(
        widget.siteName,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}