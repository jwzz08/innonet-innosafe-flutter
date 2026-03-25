import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/model/site_group_model.dart';
import '../data/model/dashboard_models.dart';
import '../data/repository/site_repository.dart';
import '../../auth/provider/auth_provider.dart';

// ─────────────────────────────────────────────
// Site Select Screen (로그인 후 첫 화면)
// ─────────────────────────────────────────────
class SiteSelectScreen extends ConsumerWidget {
  const SiteSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteListAsync = ref.watch(siteListProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────
            _SiteSelectHeader(userName: authState.userName ?? '관리자'),

            // ── Site Grid ───────────────────────────
            Expanded(
              child: siteListAsync.when(
                data: (sites) => _SiteGridView(sites: sites),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 12),
                      Text('현장 목록을 불러올 수 없습니다.\n$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(siteListProvider),
                        child: const Text('다시 시도', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _SiteSelectHeader extends ConsumerWidget {
  final String userName;
  const _SiteSelectHeader({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    children: [
                      const TextSpan(text: '안녕하세요 '),
                      TextSpan(
                        text: userName,
                        style: const TextStyle(color: AppTheme.primary),
                      ),
                      const TextSpan(text: ' 님'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // 총 현장 수는 siteListProvider에서 받아오지 않고
                // 부모에서 내려주는 대신 여기서 다시 watch
                Consumer(builder: (context, ref, _) {
                  final sites = ref.watch(siteListProvider).asData?.value ?? [];
                  final count = sites.where((s) => s.type != 'Region').length;
                  return RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: '접근 가능한 사이트는 '),
                        TextSpan(
                          text: '$count',
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const TextSpan(text: ' 개 입니다.'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // 로그아웃 버튼
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            tooltip: '로그아웃',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Site Grid View
// ─────────────────────────────────────────────
class _SiteGridView extends ConsumerWidget {
  final List<SiteGroupModel> sites;
  const _SiteGridView({required this.sites});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Region 타입 제외한 현장만 필터링
    final filteredSites = sites.where((s) => s.type != 'Region').toList();

    if (filteredSites.isEmpty) {
      return const Center(
        child: Text('접근 가능한 현장이 없습니다.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredSites.length,
      itemBuilder: (context, index) {
        final site = filteredSites[index];
        return _SiteCard(site: site);
      },
    );
  }
}

// ─────────────────────────────────────────────
// Site Card (현장 카드)
// ─────────────────────────────────────────────
class _SiteCard extends ConsumerWidget {
  final SiteGroupModel site;
  const _SiteCard({required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 해당 사이트의 dashboard 목록 미리 fetch
    final dashboardListAsync = ref.watch(dashboardListProvider(site.id));

    return GestureDetector(
      onTap: () {
        final dashboards = dashboardListAsync.asData?.value ?? [];
        if (dashboards.isEmpty) return;

        if (dashboards.length == 1) {
          // 작업구가 1개면 바로 이동
          context.push('/site-detail', extra: {
            'siteId': site.id,
            'siteName': site.name,
            'dashboardId': dashboards.first.id,
            'dashboardName': dashboards.first.name,
          });
        } else {
          // 작업구가 여러 개면 선택 바텀시트
          _showDashboardBottomSheet(context, site, dashboards);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 썸네일 영역 ──────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _SiteThumbnail(siteId: site.id),
              ),
            ),

            // ── 정보 영역 ────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  dashboardListAsync.when(
                    data: (dashboards) => Text(
                      dashboards.isEmpty
                          ? 'Dashboard 없음'
                          : dashboards.length == 1
                          ? dashboards.first.name
                          : '작업구 ${dashboards.length}개',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppTheme.textSecondary),
                    ),
                    error: (_, __) => const Text('--',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDashboardBottomSheet(
      BuildContext context,
      SiteGroupModel site,
      List<DashboardSummaryModel> dashboards,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DashboardPickerSheet(site: site, dashboards: dashboards),
    );
  }
}

// ─────────────────────────────────────────────
// Site Thumbnail (도면 이미지 혹은 플레이스홀더)
// ─────────────────────────────────────────────
class _SiteThumbnail extends ConsumerWidget {
  final int siteId;
  const _SiteThumbnail({required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // dashboard 목록에서 첫 번째 dashboard의 첫 site_image 위젯 이미지 사용
    final dashboardListAsync = ref.watch(dashboardListProvider(siteId));

    return dashboardListAsync.when(
      data: (dashboards) {
        if (dashboards.isEmpty) {
          return _placeholder();
        }
        // 첫 번째 dashboard의 widgetId로 이미지 시도
        // (실제 구현: fetchWidgetDrawing 호출)
        // 현재는 placeholder로 표시
        return _placeholder();
      },
      loading: () => _placeholder(),
      error: (_, __) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF0D1117),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined,
                size: 40, color: Color(0xFF30363D)),
            SizedBox(height: 8),
            Text('이미지 없음',
                style: TextStyle(color: Color(0xFF30363D), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashboard Picker Bottom Sheet (작업구 선택)
// ─────────────────────────────────────────────
class _DashboardPickerSheet extends StatelessWidget {
  final SiteGroupModel site;
  final List<DashboardSummaryModel> dashboards;

  const _DashboardPickerSheet({
    required this.site,
    required this.dashboards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 타이틀
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                site.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '작업구를 선택하세요',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // 작업구 리스트
          ...dashboards.map((dashboard) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dashboard_outlined,
                  color: AppTheme.primary, size: 20),
            ),
            title: Text(
              dashboard.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              dashboard.type,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppTheme.textSecondary, size: 14),
            onTap: () {
              Navigator.pop(context);
              context.push('/site-detail', extra: {
                'siteId': site.id,
                'siteName': site.name,
                'dashboardId': dashboard.id,
                'dashboardName': dashboard.name,
              });
            },
          )),
        ],
      ),
    );
  }
}