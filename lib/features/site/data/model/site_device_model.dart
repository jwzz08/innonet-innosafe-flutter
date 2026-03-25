/// ========================================================================
/// Site Device Model (GET /api/v1/sitegroups/{id} 응답의 devices 배열)
/// ========================================================================

class SiteDeviceModel {
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

  SiteDeviceModel({
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
  });

  factory SiteDeviceModel.fromJson(Map<String, dynamic> json) {
    return SiteDeviceModel(
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

/// ========================================================================
/// Site Group Detail Model (devices 배열 포함)
/// ========================================================================
class SiteGroupDetailModel {
  final int id;
  final String name;
  final String type;
  final List<SiteDeviceModel> devices;
  final String createdAt;
  final String updatedAt;

  SiteGroupDetailModel({
    required this.id,
    required this.name,
    required this.type,
    required this.devices,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SiteGroupDetailModel.fromJson(Map<String, dynamic> json) {
    return SiteGroupDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      devices: (json['devices'] as List<dynamic>?)
          ?.map((e) => SiteDeviceModel.fromJson(e))
          .toList() ?? [],
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}