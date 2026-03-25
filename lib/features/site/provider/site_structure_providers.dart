import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/repository/dashboard_repository.dart';
import '../data/repository/position_repository.dart';
import '../data/model/dashboard_models.dart';
import '../data/model/position_models.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());
final positionRepositoryProvider = Provider((ref) => PositionRepository());

final dashboardListProvider = FutureProvider.family.autoDispose<List<DashboardSummaryModel>, int>(
      (ref, siteGroupId) async {
    final repository = ref.watch(dashboardRepositoryProvider);
    return repository.fetchDashboardList(siteGroupId);
  },
);

final dashboardDetailProvider = FutureProvider.family<DashboardDetailModel, int>(
      (ref, dashboardId) async {
    final repository = ref.watch(dashboardRepositoryProvider);
    return repository.fetchDashboardDetail(dashboardId);
  },
);

final positionAggregationProvider = FutureProvider.family<PositionAggregation, int>(
      (ref, siteGroupId) async {
    final repository = ref.watch(positionRepositoryProvider);
    return repository.fetchPositionAggregation(siteGroupId);
  },
);

final autoRefreshPositionProvider = StreamProvider.family<PositionAggregation, int>(
      (ref, siteGroupId) async* {
    while (true) {
      try {
        final repository = ref.watch(positionRepositoryProvider);
        final data = await repository.fetchPositionAggregation(siteGroupId);
        yield data;
      } catch (e) {
        print('âš ï¸ Position ìžë™ ê°±ì‹  ì‹¤íŒ¨: $e');
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  },
);

final enrichedStructureProvider = FutureProvider.family<StructureViewModel, EnrichedStructureParams>(
      (ref, params) async {

    final dashboard = await ref.watch(dashboardDetailProvider(params.dashboardId).future);


    final positions = await ref.watch(positionAggregationProvider(params.siteGroupId).future);

    final siteImageWidget = dashboard.siteImageWidgets.firstOrNull;

    if (siteImageWidget == null || siteImageWidget.siteImageProperties == null) {
      print('âš ï¸ [Provider] site_image ìœ„ì ¯ì´ ì—†ìŠµë‹ˆë‹¤. ê¸°ë³¸ê°’ ì‚¬ìš©');

      final defaultWidget = DashboardWidgetModel(
        id: 0,
        type: 'site_image',
        x: 0,
        y: 0,
        w: 16,
        h: 7,
        properties: {},
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        dashboardId: params.dashboardId,
        siteImageProperties: SiteImageProperties(
          iconList: [],
          tableList: [],
          deviceRemoveList: [],
        ),
      );

      return StructureViewModel(
        dashboard: dashboard,
        widget: defaultWidget,
        enrichedIcons: [],
        tableList: [],
        deviceRemoveList: [],
        totalWorkerCount: positions.getTotalCount(),
        positions: positions,
      );
    }

    final props = siteImageWidget.siteImageProperties!;

    final enrichedIcons = props.iconList.map((icon) {
      int liveCount = icon.humanCount; // ê¸°ë³¸ê°’

      if (icon.serialNumber != null && icon.serialNumber!.isNotEmpty) {
        liveCount = positions.getCountForReader(icon.serialNumber!);
      }

      return IconViewModel(
        original: icon,
        liveHumanCount: liveCount,
      );
    }).toList();

    return StructureViewModel(
      dashboard: dashboard,
      widget: siteImageWidget,
      enrichedIcons: enrichedIcons,
      tableList: props.tableList,
      deviceRemoveList: props.deviceRemoveList,
      totalWorkerCount: positions.getTotalCount(),
      positions: positions, // âœ… ì¶”ê°€: Worker ìƒì„¸ ì •ë³´ìš©
    );
  },
);

class EnrichedStructureParams {
  final int siteGroupId;
  final int dashboardId;

  EnrichedStructureParams({
    required this.siteGroupId,
    required this.dashboardId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EnrichedStructureParams &&
              runtimeType == other.runtimeType &&
              siteGroupId == other.siteGroupId &&
              dashboardId == other.dashboardId;

  @override
  int get hashCode => siteGroupId.hashCode ^ dashboardId.hashCode;
}

class StructureViewModel {
  final DashboardDetailModel dashboard;
  final DashboardWidgetModel widget;
  final List<IconViewModel> enrichedIcons;
  final List<TableItemModel> tableList;
  final List<int> deviceRemoveList;
  final int totalWorkerCount;
  final PositionAggregation positions;

  StructureViewModel({
    required this.dashboard,
    required this.widget,
    required this.enrichedIcons,
    required this.tableList,
    required this.deviceRemoveList,
    required this.totalWorkerCount,
    required this.positions,
  });
}

class IconViewModel {
  final MapIconModel original;
  final int liveHumanCount;

  IconViewModel({
    required this.original,
    required this.liveHumanCount,
  });
}

final selectedDashboardIdProvider = StateProvider<int?>((ref) => null);