import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innosafe/features/site/presentation/tabs/site_overview_tab.dart';
import '../../../core/theme/app_theme.dart';
import 'tabs/site_monitoring_tab.dart';
import 'tabs/site_structure_tab.dart';
import '../provider/site_structure_provider.dart';
import '../data/model/site_group_model.dart';

class SiteScreen extends ConsumerStatefulWidget {
  const SiteScreen({super.key});

  @override
  ConsumerState<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends ConsumerState<SiteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 현재 선택된 현장 ID와 이름
  int? currentSiteId;
  String currentSiteName = "Select Site";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 사이트 목록 데이터 구독
    final siteListAsync = ref.watch(siteListProvider);

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          appBar: isLandscape
              ? null
              : AppBar(
            // 2. AppBar Title을 Dropdown으로 교체
            title: siteListAsync.when(
              data: (sites) {
                // 데이터가 처음 로드되었고, 아직 선택된 게 없다면 '기본값' 설정
                if (currentSiteId == null && sites.isNotEmpty) {
                  // 'Region'(최상위)이 아닌 첫 번째 현장을 찾거나, 없으면 0번째 사용
                  final defaultSite = sites.firstWhere(
                        (s) => s.type != 'Region',
                    orElse: () => sites.first,
                  );

                  // 빌드 중 setState 오류 방지
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        currentSiteId = defaultSite.id;
                        currentSiteName = defaultSite.name;
                      });
                    }
                  });
                }

                // 드롭다운 버튼 구성
                return PopupMenuButton<SiteGroupModel>(
                  offset: const Offset(0, 40), // 메뉴 위치 조정
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: AppTheme.surfaceHighlight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSiteName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                    ],
                  ),
                  onSelected: (SiteGroupModel site) {
                    // 현장 변경 -> setState -> 하위 탭 리빌드 -> Provider 재호출
                    setState(() {
                      currentSiteId = site.id;
                      currentSiteName = site.name;
                    });
                  },
                  itemBuilder: (context) {
                    return sites.map((site) {
                      // Region 타입은 선택 못하게 하거나 시각적으로 구분
                      final isRegion = site.type == 'Region';
                      return PopupMenuItem<SiteGroupModel>(
                        value: site,
                        enabled: !isRegion, // Region 선택 불가 처리 (선택사항)
                        child: Row(
                          children: [
                            // 타입에 따라 아이콘 다르게
                            Icon(
                              isRegion ? Icons.public : Icons.location_on,
                              size: 16,
                              color: isRegion ? Colors.grey : AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site.name,
                                  style: TextStyle(
                                    color: isRegion ? Colors.grey : Colors.white,
                                    fontWeight: isRegion ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                if (site.type.isNotEmpty)
                                  Text(site.type, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                );
              },
              loading: () => const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)
              ),
              error: (_, __) => const Text("Error loading sites", style: TextStyle(fontSize: 14)),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: "Dashboard"),
                Tab(text: "Monitoring"),
                Tab(text: "Structure"),
              ],
            ),
          ),

          // 3. 하위 탭에 currentSiteId 전달
          body: currentSiteId == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // DashboardTab에도 siteId 전달 필요시 수정
              const SiteOverviewTab(),

              // MonitoringTab에도 ID 전달 (구현 필요 시)
              const SiteMonitoringTab(),

              // [핵심] ID가 바뀌면 이 위젯이 다시 빌드됨 -> API 재호출
              SiteStructureTab(siteId: currentSiteId!),
            ],
          ),
        );
      },
    );
  }
}