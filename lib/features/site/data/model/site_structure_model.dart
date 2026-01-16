import 'package:flutter/foundation.dart';

// [메인 모델] 현장 구조 데이터 통합 객체
class SiteStructureModel {
  final String siteName;
  final String mapImageUrl; // API에 없으면 로컬 에셋 사용
  final double width;
  final double height;
  final List<EquipmentModel> equipments;
  final List<WorkerGroupModel> workerGroups;

  SiteStructureModel({
    required this.siteName,
    required this.mapImageUrl,
    required this.width,
    required this.height,
    required this.equipments,
    required this.workerGroups,
  });
}

// [장비 모델] /api/v1/sitegroups/{id}/position/equipments 대응
class EquipmentModel {
  final int id;
  final String name;
  final String uid;
  final double x; // UI 표시용 (Reader ID 매핑 필요)
  final double y;
  final String status;
  final bool hasCamera;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.uid,
    required this.x,
    required this.y,
    this.status = 'Normal',
    this.hasCamera = false,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    // API 응답 예시: { "equipmentId": 201, "equipmentName": "Excavator...", "position": {...} }
    final pos = json['position']?['currentPos'] ?? {};

    // TODO: 실제로는 readerSerialNumber를 이용해 좌표를 매핑해야 함
    // 현재는 테스트를 위해 랜덤 또는 고정 좌표 할당
    return EquipmentModel(
      id: json['equipmentId'] ?? 0,
      name: json['equipmentName'] ?? 'Unknown Equipment',
      uid: json['equipmentUid'] ?? '',
      x: 200.0 + (json['equipmentId'] ?? 0) * 50, // 임시 좌표 로직
      y: 500.0,
      status: 'Active',
      hasCamera: true, // 로직에 따라 true/false 설정
    );
  }
}

// [작업자 그룹 모델] UI에서 그룹핑하여 보여주기 위한 모델
class WorkerGroupModel {
  final String zoneName;
  final double x;
  final double y;
  final List<WorkerDetailModel> workers;

  WorkerGroupModel({
    required this.zoneName,
    required this.x,
    required this.y,
    required this.workers,
  });

  int get count => workers.length;
}

// [작업자 상세 모델] /api/v1/sitegroups/{id}/position/entrants 대응
class WorkerDetailModel {
  final int id;
  final String name;
  final String teamName;
  final String status;
  final String readerSerial; // 위치 파악용 Reader ID

  WorkerDetailModel({
    required this.id,
    required this.name,
    required this.teamName,
    required this.status,
    required this.readerSerial,
  });

  factory WorkerDetailModel.fromJson(Map<String, dynamic> json) {
    final pos = json['position']?['currentPos'] ?? json['position']?['previousPos'] ?? {};

    return WorkerDetailModel(
      id: json['workerId'] ?? 0,
      name: json['workerName'] ?? 'Unknown',
      teamName: json['teamName'] ?? 'Unknown Team',
      status: 'Normal', // RSSI 값 등에 따라 상태 결정 가능
      readerSerial: pos['readerSerialNumber'] ?? '',
    );
  }
}