/// ========================================================================
/// 실시간 위치 데이터 모델 (Layout과 분리)
/// ========================================================================

/// 1. 작업자 위치 모델 (GET /api/v1/sitegroups/{id}/position/entrants)
class WorkerPositionModel {
  final int workerId;
  final String workerName;
  final String workerUid;
  final int teamId;
  final String? teamName;
  final String? workerPhoneNumber;
  final int? workerAge;
  final String? workerBloodType;
  final String? workerNationality;
  final PositionInfo position;

  WorkerPositionModel({
    required this.workerId,
    required this.workerName,
    required this.workerUid,
    required this.teamId,
    this.teamName,
    this.workerPhoneNumber,
    this.workerAge,
    this.workerBloodType,
    this.workerNationality,
    required this.position,
  });

  factory WorkerPositionModel.fromJson(Map<String, dynamic> json) {
    return WorkerPositionModel(
      workerId: json['workerId'] as int,
      workerName: json['workerName'] as String? ?? 'Unknown',
      workerUid: json['workerUid'] as String? ?? '',
      teamId: json['teamId'] as int,
      teamName: json['teamName'] as String?,
      workerPhoneNumber: json['workerPhoneNumber'] as String?,
      workerAge: json['workerAge'] as int?,
      workerBloodType: json['workerBloodType'] as String?,
      workerNationality: json['workerNationality'] as String?,
      position: PositionInfo.fromJson(json['position'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// 2. 장비 위치 모델 (GET /api/v1/sitegroups/{id}/position/equipments)
class EquipmentPositionModel {
  final int equipmentId;
  final String equipmentName;
  final String equipmentUid;
  final String siteGroupId;
  final PositionInfo position;

  EquipmentPositionModel({
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentUid,
    required this.siteGroupId,
    required this.position,
  });

  factory EquipmentPositionModel.fromJson(Map<String, dynamic> json) {
    return EquipmentPositionModel(
      equipmentId: json['equipmentId'] as int,
      equipmentName: json['equipmentName'] as String? ?? 'Unknown',
      equipmentUid: json['equipmentUid'] as String? ?? '',
      siteGroupId: json['siteGroupId'] as String? ?? '',
      position: PositionInfo.fromJson(json['position'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// 3. 위치 정보 (공통)
class PositionInfo {
  final ReaderPosition? previousPos;
  final ReaderPosition? currentPos;
  final int? timestamp;

  PositionInfo({
    this.previousPos,
    this.currentPos,
    this.timestamp,
  });

  factory PositionInfo.fromJson(Map<String, dynamic> json) {
    return PositionInfo(
      previousPos: json['previousPos'] != null
          ? ReaderPosition.fromJson(json['previousPos'])
          : null,
      currentPos: json['currentPos'] != null
          ? ReaderPosition.fromJson(json['currentPos'])
          : null,
      timestamp: json['timestamp'] as int?,
    );
  }

  bool get hasPosition => currentPos != null || previousPos != null;
  String get readerSerial => currentPos?.readerSerialNumber ?? previousPos?.readerSerialNumber ?? '';
  int get rssiValue => currentPos?.rssiValue ?? previousPos?.rssiValue ?? -100;
}

/// 4. 리더 위치 (RSSI 포함)
class ReaderPosition {
  final String readerSerialNumber;
  final int rssiValue;

  ReaderPosition({
    required this.readerSerialNumber,
    required this.rssiValue,
  });

  factory ReaderPosition.fromJson(Map<String, dynamic> json) {
    return ReaderPosition(
      readerSerialNumber: json['readerSerialNumber'] as String? ?? '',
      rssiValue: json['RSSIvalue'] as int? ?? -100,
    );
  }
}

/// 5. 집계 데이터 (아이콘의 humanCount 업데이트용)
class PositionAggregation {
  final Map<String, int> workerCountByReader; // Reader Serial -> 인원수
  final Map<int, WorkerPositionModel> workerById; // Worker ID -> 상세정보

  PositionAggregation({
    required this.workerCountByReader,
    required this.workerById,
  });

  factory PositionAggregation.fromWorkerList(List<WorkerPositionModel> workers) {
    final countMap = <String, int>{};
    final workerMap = <int, WorkerPositionModel>{};

    for (var worker in workers) {
      workerMap[worker.workerId] = worker;

      if (worker.position.hasPosition) {
        final serial = worker.position.readerSerial;
        countMap[serial] = (countMap[serial] ?? 0) + 1;
      }
    }

    return PositionAggregation(
      workerCountByReader: countMap,
      workerById: workerMap,
    );
  }

  int getCountForReader(String serialNumber) {
    return workerCountByReader[serialNumber] ?? 0;
  }

  int getTotalCount() {
    return workerCountByReader.values.fold(0, (sum, count) => sum + count);
  }
}