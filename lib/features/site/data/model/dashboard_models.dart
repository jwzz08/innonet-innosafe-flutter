/// ========================================================================
/// Dashboard 관련 모델 (API 문서 6.5 Dashboard/MonitoringBoard 관리 기준)
/// ========================================================================

/// 1. Dashboard 목록 조회용 (GET /api/v1/sitegroups/{id}/dashboards)
class DashboardSummaryModel {
  final int id;
  final String name;
  final String type; // "overview" | "monitoring"
  final String createdAt;
  final String updatedAt;
  final int siteGroupId;

  DashboardSummaryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.siteGroupId,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Dashboard',
      type: json['type'] as String? ?? 'overview',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      siteGroupId: json['siteGroupId'] as int,
    );
  }
}

/// 2. Dashboard 상세 조회용 (GET /api/v1/dashboards/{id})
class DashboardDetailModel {
  final int id;
  final String name;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int siteGroupId;
  final List<DashboardWidgetModel> widgets;

  DashboardDetailModel({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.siteGroupId,
    required this.widgets,
  });

  factory DashboardDetailModel.fromJson(Map<String, dynamic> json) {
    return DashboardDetailModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'overview',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      siteGroupId: json['siteGroupId'] as int,
      widgets: (json['widgets'] as List<dynamic>? ?? [])
          .map((w) => DashboardWidgetModel.fromJson(w))
          .toList(),
    );
  }

  /// site_image 타입 위젯만 필터링 (도면 표시용)
  List<DashboardWidgetModel> get siteImageWidgets {
    return widgets.where((w) => w.type == 'site_image').toList();
  }
}

/// 3. 위젯 모델 (Grid 좌표 포함)
class DashboardWidgetModel {
  final int id;
  final String type; // "site_image", "sensor", "alarmStatus" 등
  final int x;
  final int y;
  final int w; // width (grid units)
  final int h; // height (grid units)
  final Map<String, dynamic> properties;
  final String createdAt;
  final String updatedAt;
  final int dashboardId;

  // Parsed properties (type별 분기)
  final SiteImageProperties? siteImageProperties;

  DashboardWidgetModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.properties,
    required this.createdAt,
    required this.updatedAt,
    required this.dashboardId,
    this.siteImageProperties,
  });

  factory DashboardWidgetModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'unknown';
    final props = json['properties'] as Map<String, dynamic>? ?? {};

    return DashboardWidgetModel(
      id: json['id'] as int,
      type: type,
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      w: json['w'] as int? ?? 1,
      h: json['h'] as int? ?? 1,
      properties: props,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      dashboardId: json['dashboardId'] as int,
      // site_image일 때만 파싱
      siteImageProperties: type == 'site_image'
          ? SiteImageProperties.fromJson(props)
          : null,
    );
  }
}

/// 4. Site Image 속성 (도면 위젯 전용)
class SiteImageProperties {
  final List<MapIconModel> iconList;
  final List<TableItemModel> tableList;
  final List<int> deviceRemoveList;

  SiteImageProperties({
    required this.iconList,
    required this.tableList,
    required this.deviceRemoveList,
  });

  factory SiteImageProperties.fromJson(Map<String, dynamic> json) {
    return SiteImageProperties(
      iconList: (json['iconList'] as List<dynamic>? ?? [])
          .map((i) => MapIconModel.fromJson(i))
          .toList(),
      tableList: (json['tableList'] as List<dynamic>? ?? [])
          .map((t) => TableItemModel.fromJson(t))
          .toList(),
      deviceRemoveList: (json['deviceRemoveList'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }
}

/// 5. 맵 아이콘 모델 (다형성 ID 처리)
class MapIconModel {
  final dynamic id; // int | List<int>
  final String name;
  final String type; // "ble", "bleSum", "TotalSum", "EquipmentSum", "MaterialSum", "ExcavationRate", "master", "slave"
  final String? reactKey;
  final double xPercent;
  final double yPercent;
  final int humanCount;
  final String? serialNumber;
  final Map<String, dynamic> properties;

  // 장비/자재 이름 (EquipmentSum, MaterialSum용)
  final List<String> equipmentNames;
  final List<String> materialNames;

  MapIconModel({
    required this.id,
    required this.name,
    required this.type,
    this.reactKey,
    required this.xPercent,
    required this.yPercent,
    required this.humanCount,
    this.serialNumber,
    required this.properties,
    this.equipmentNames = const [],
    this.materialNames = const [],
  });

  factory MapIconModel.fromJson(Map<String, dynamic> json) {
    return MapIconModel(
      id: json['id'], // int 또는 List<int> 그대로 저장
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'default',
      reactKey: json['reactKey'] as String?,
      xPercent: (json['xPercent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['yPercent'] as num?)?.toDouble() ?? 0.0,
      humanCount: json['humanCount'] as int? ?? 0,
      serialNumber: json['serialNumber'] as String?,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      equipmentNames: (json['equipmentNames'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      materialNames: (json['materialNames'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  /// ID를 리스트로 안전하게 변환
  List<int> getIdList() {
    if (id is int) return [id as int];
    if (id is List) return List<int>.from(id);
    return [];
  }

  /// 굴진율 전용 속성
  double get progressValue => (properties['progressValue'] as num?)?.toDouble() ?? 0.0;
  double get sizeX => (properties['sizeX'] as num?)?.toDouble() ?? 700.0;
  double get sizeY => (properties['sizeY'] as num?)?.toDouble() ?? 80.0;
  String get title => properties['title'] as String? ?? '';
  String get targetColor => properties['targetColor'] as String? ?? '#5856D6';
  String get progressColor => properties['progressColor'] as String? ?? '#64D2FF';

  /// 디바이스 정보 (ble, bleSum용)
  List<int> get deviceIds {
    final ids = properties['deviceIds'];
    if (ids is List) return List<int>.from(ids);
    return [];
  }
}

/// 6. 테이블 아이템 모델 (하단 디바이스 상세 리스트용)
/// deviceId 필드 추가
class TableItemModel {
  final int id;
  final String name;
  final String type;
  final int humanCount;
  final String? serialNumber;
  final Map<String, dynamic> properties;
  final int? deviceId; // ✅ 추가: GET /api/v1/devices/{deviceId} 호출용

  TableItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.humanCount,
    this.serialNumber,
    required this.properties,
    this.deviceId, // ✅ 추가
  });

  factory TableItemModel.fromJson(Map<String, dynamic> json) {
    return TableItemModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      humanCount: json['humanCount'] as int? ?? 0,
      serialNumber: json['serialNumber'] as String?,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      deviceId: json['deviceId'] as int?, // ✅ 추가: 서버에서 제공하는 deviceId
    );
  }
}

/// ========================================================================
/// 7. Device Detail Model (RTSP 스트림 정보 포함)
/// ✅ 새로 추가: GET /api/v1/devices/{deviceId} 응답 모델
/// ========================================================================
class DeviceDetailModel {
  final int id;
  final String name;
  final String serialNumber;
  final String? location;
  final String status;
  final DeviceProperties properties;
  final String createdAt;
  final String updatedAt;
  final int deviceModelId;
  final int siteGroupId;
  final int? controllerId;
  final String deviceType;
  final String deviceModel;

  DeviceDetailModel({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.location,
    required this.status,
    required this.properties,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceModelId,
    required this.siteGroupId,
    this.controllerId,
    required this.deviceType,
    required this.deviceModel,
  });

  factory DeviceDetailModel.fromJson(Map<String, dynamic> json) {
    return DeviceDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      serialNumber: json['serialNumber'] as String,
      location: json['location'] as String?,
      status: json['status'] as String,
      properties: DeviceProperties.fromJson(json['properties'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      deviceModelId: json['deviceModelId'] as int,
      siteGroupId: json['siteGroupId'] as int,
      controllerId: json['controllerId'] as int?,
      deviceType: json['deviceType'] as String,
      deviceModel: json['deviceModel'] as String,
    );
  }
}

class DeviceProperties {
  final String? mode;
  final int? port;
  final String? publicIp;
  final List<String> rtspList;
  final String? controllerType;
  final bool? checkConnection;
  final bool? hasWarningLight;
  final int? refreshInterval;
  final bool? supportLocation;
  final bool? useHandoverTime;

  DeviceProperties({
    this.mode,
    this.port,
    this.publicIp,
    this.rtspList = const [],
    this.controllerType,
    this.checkConnection,
    this.hasWarningLight,
    this.refreshInterval,
    this.supportLocation,
    this.useHandoverTime,
  });

  factory DeviceProperties.fromJson(Map<String, dynamic> json) {
    return DeviceProperties(
      mode: json['mode'] as String?,
      port: json['port'] as int?,
      publicIp: json['publicIp'] as String?,
      rtspList: (json['rtspList'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      controllerType: json['controllerType'] as String?,
      checkConnection: json['checkConnection'] as bool?,
      hasWarningLight: json['hasWarningLight'] as bool?,
      refreshInterval: json['refreshInterval'] as int?,
      supportLocation: json['supportLocation'] as bool?,
      useHandoverTime: json['useHandoverTime'] as bool?,
    );
  }

  bool get hasRtspStreams => rtspList.isNotEmpty;
}