import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/dashboard_models.dart';
import '../model/position_models.dart';
import '../model/site_group_model.dart';
import '../model/site_device_model.dart';
import '../repository/dashboard_repository.dart';
import '../repository/position_repository.dart';

/// ========================================================================
/// Repository Classes
/// ========================================================================
class SiteRepository {
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://220.76.77.250:5003/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<SiteGroupModel>> fetchSiteGroups() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception("로그인 정보가 없습니다.");
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/sitegroups');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => SiteGroupModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching site groups: $e");
      return [];
    }
  }

  /// ✅ 새로 추가: Site Group 상세 정보 (devices 포함)
  Future<SiteGroupDetailModel> fetchSiteGroupDetail(int siteGroupId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception("로그인 정보가 없습니다.");
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/sitegroups/$siteGroupId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return SiteGroupDetailModel.fromJson(response.data);
      }
      throw Exception('Site group detail 조회 실패');
    } catch (e) {
      print("Error fetching site group detail: $e");
      rethrow;
    }
  }
}

/// ========================================================================
/// Repository Providers
/// ========================================================================
final siteRepositoryProvider = Provider((ref) => SiteRepository());
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());
final positionRepositoryProvider = Provider((ref) => PositionRepository());

/// ========================================================================
/// 1. Site 목록 Provider
/// ========================================================================
final siteListProvider = FutureProvider<List<SiteGroupModel>>((ref) async {
  final repository = ref.watch(siteRepositoryProvider);
  return repository.fetchSiteGroups();
});

/// ========================================================================
/// 2. Site Group 상세 Provider (✅ 새로 추가)
/// ========================================================================
final siteGroupDetailProvider = FutureProvider.family<SiteGroupDetailModel, int>(
      (ref, siteGroupId) async {
    final repository = ref.watch(siteRepositoryProvider);
    return repository.fetchSiteGroupDetail(siteGroupId);
  },
);

/// ========================================================================
/// 3. Site Devices Provider (✅ 새로 추가)
/// ========================================================================
final siteDevicesProvider = FutureProvider.family<List<SiteDeviceModel>, int>(
      (ref, siteGroupId) async {
    final siteDetail = await ref.watch(siteGroupDetailProvider(siteGroupId).future);
    return siteDetail.devices;
  },
);

/// ========================================================================
/// 4. Dashboard 목록 Provider (Site별)
/// ========================================================================
final dashboardListProvider = FutureProvider.family.autoDispose<List<DashboardSummaryModel>, int>(
      (ref, siteGroupId) async {
    final repository = ref.watch(dashboardRepositoryProvider);
    return repository.fetchDashboardList(siteGroupId);
  },
);

/// ========================================================================
/// 5. Dashboard 상세 Provider (선택된 Dashboard)
/// ========================================================================
final dashboardDetailProvider = FutureProvider.family<DashboardDetailModel, int>(
      (ref, dashboardId) async {
    final repository = ref.watch(dashboardRepositoryProvider);
    return repository.fetchDashboardDetail(dashboardId);
  },
);

/// ========================================================================
/// 6. 실시간 Position Provider
/// ========================================================================
final positionAggregationProvider = FutureProvider.family<PositionAggregation, int>(
      (ref, siteGroupId) async {
    final repository = ref.watch(positionRepositoryProvider);
    return repository.fetchPositionAggregation(siteGroupId);
  },
);

/// ========================================================================
/// 7. 자동 갱신 Provider (30초 주기)
/// ========================================================================
final autoRefreshPositionProvider = StreamProvider.family<PositionAggregation, int>(
      (ref, siteGroupId) async* {
    while (true) {
      try {
        final repository = ref.watch(positionRepositoryProvider);
        final data = await repository.fetchPositionAggregation(siteGroupId);
        yield data;
      } catch (e) {
        print('⚠️ Position 자동 갱신 실패: $e');
        // 에러 무시하고 계속 진행
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  },
);

/// ========================================================================
/// 8. 통합 Structure Provider (Layout + Position 결합)
/// ========================================================================
final enrichedStructureProvider = FutureProvider.family<StructureViewModel, EnrichedStructureParams>(
      (ref, params) async {
    // Dashboard Layout 가져오기
    final dashboard = await ref.watch(dashboardDetailProvider(params.dashboardId).future);

    // 실시간 Position 가져오기
    final positions = await ref.watch(positionAggregationProvider(params.siteGroupId).future);

    // site_image 위젯만 필터링
    final siteImageWidget = dashboard.siteImageWidgets.firstOrNull;

    // site_image 위젯이 없으면 기본값으로 빈 데이터 생성
    if (siteImageWidget == null || siteImageWidget.siteImageProperties == null) {
      print('⚠️ [Provider] site_image 위젯이 없습니다. 기본값 사용');

      // 기본 위젯 생성 (빈 iconList, tableList)
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

    // iconList에 실시간 humanCount 적용
    final enrichedIcons = props.iconList.map((icon) {
      int liveCount = icon.humanCount; // 기본값

      // serialNumber가 있으면 실시간 카운트로 업데이트
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
      positions: positions,
    );
  },
);

/// ========================================================================
/// 파라미터 클래스
/// ========================================================================
class EnrichedStructureParams {
  final int siteGroupId;
  final int dashboardId;

  EnrichedStructureParams({
    required this.siteGroupId,
    required this.dashboardId,
  });

  // 캐싱을 위한 equality 구현
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

/// ========================================================================
/// View Model Classes
/// ========================================================================
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

/// ========================================================================
/// 선택된 Dashboard ID 상태 관리 (Site Screen용)
/// ========================================================================
final selectedDashboardIdProvider = StateProvider.family<int?, int>((ref, siteId) => null);