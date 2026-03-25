import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// 1. 최상위 응답 모델 (Dashboard)
// ---------------------------------------------------------------------------
class StructureResponseModelV2 {
  final int id;
  final String name;
  final String type;
  final List<StructureWidgetModelV2> widgets;

  StructureResponseModelV2({
    required this.id,
    required this.name,
    required this.type,
    required this.widgets,
  });

  factory StructureResponseModelV2.fromJson(Map<String, dynamic> json) {
    return StructureResponseModelV2(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Dashboard',
      type: json['type'] as String? ?? 'overview',
      widgets: (json['widgets'] as List<dynamic>? ?? [])
          .map((e) => StructureWidgetModelV2.fromJson(e))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. 위젯 모델 (Grid Layout용)
// 설명: 대시보드 그리드 상에서의 위치(x,y)와 크기(w,h)를 정의합니다.
// ---------------------------------------------------------------------------
class StructureWidgetModelV2 {
  final int id;
  final String type; // 'site_image', 'sensor', 'alarmSummary' 등

  // Grid 좌표 (정수형)
  final int x;
  final int y;
  final int w;
  final int h;

  // 타입별 상세 속성 (Polymorphism)
  final SiteImageProperties? imageProperties;
  // 추후 SensorProperties 등 추가 가능

  StructureWidgetModelV2({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.imageProperties,
  });

  factory StructureWidgetModelV2.fromJson(Map<String, dynamic> json) {
    final String type = json['type'] as String? ?? 'unknown';
    final Map<String, dynamic> props = json['properties'] as Map<String, dynamic>? ?? {};

    return StructureWidgetModelV2(
      id: json['id'] as int? ?? 0,
      type: type,
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      w: json['w'] as int? ?? 1,
      h: json['h'] as int? ?? 1,
      // type이 'site_image'일 때만 properties를 파싱
      imageProperties: type == 'site_image'
          ? SiteImageProperties.fromJson(props)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Site Image 상세 속성
// 설명: 배경 이미지 위젯 내부에 들어갈 아이콘들과 테이블 리스트를 담습니다.
// ---------------------------------------------------------------------------
class SiteImageProperties {
  final List<IconModel> iconList;
  final List<TableItemModel> tableList;

  SiteImageProperties({
    required this.iconList,
    required this.tableList,
  });

  factory SiteImageProperties.fromJson(Map<String, dynamic> json) {
    return SiteImageProperties(
      iconList: (json['iconList'] as List<dynamic>? ?? [])
          .map((e) => IconModel.fromJson(e))
          .toList(),
      tableList: (json['tableList'] as List<dynamic>? ?? [])
          .map((e) => TableItemModel.fromJson(e))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. 아이콘 모델 (Overlay용)
// 설명: 이미지 위에 절대 위치(%)로 찍힐 아이콘 정보입니다.
// ---------------------------------------------------------------------------
class IconModel {
  final int id; // number | number[] 라고 되어있으나 보통 id는 int로 처리
  final String name;
  final String type; // 아이콘 타입
  final String? reactKey;

  // 위치 좌표 (실수형, %)
  final double xPercent;
  final double yPercent;

  final int humanCount;
  final String? serialNumber;

  // 아이콘 내부 상세 (devices, colors 등)
  final IconDetailProperties details;

  IconModel({
    required this.id,
    required this.name,
    required this.type,
    this.reactKey,
    required this.xPercent,
    required this.yPercent,
    required this.humanCount,
    this.serialNumber,
    required this.details,
  });

  factory IconModel.fromJson(Map<String, dynamic> json) {
    // id가 배열로 올 수도 있다는 문서 내용 대응 (첫번째 요소 사용 혹은 0)
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is List && val.isNotEmpty) return val.first as int;
      return 0;
    }

    return IconModel(
      id: parseId(json['id']),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'default',
      reactKey: json['reactKey'] as String?,
      xPercent: (json['xPercent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['yPercent'] as num?)?.toDouble() ?? 0.0,
      humanCount: json['humanCount'] as int? ?? 0,
      serialNumber: json['serialNumber'] as String?,
      details: IconDetailProperties.fromJson(json['properties'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. 아이콘 내부 상세 속성
// 설명: 아이콘의 색상, 진행률, 사이즈 등을 정의합니다.
// ---------------------------------------------------------------------------
class IconDetailProperties {
  final double sizeX;
  final double sizeY;
  final String title;
  final String targetColor;
  final String progressColor;
  final double progressValue;
  // 필요시 devices 리스트 추가

  IconDetailProperties({
    this.sizeX = 32.0,
    this.sizeY = 32.0,
    this.title = '',
    this.targetColor = '#000000',
    this.progressColor = '#000000',
    this.progressValue = 0.0,
  });

  factory IconDetailProperties.fromJson(Map<String, dynamic> json) {
    return IconDetailProperties(
      sizeX: (json['sizeX'] as num?)?.toDouble() ?? 32.0,
      sizeY: (json['sizeY'] as num?)?.toDouble() ?? 32.0,
      title: json['title'] as String? ?? '',
      targetColor: json['targetColor'] as String? ?? '#000000',
      progressColor: json['progressColor'] as String? ?? '#000000',
      progressValue: (json['progressValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ---------------------------------------------------------------------------
// 6. 테이블 아이템 모델
// ---------------------------------------------------------------------------
class TableItemModel {
  final int id;
  final String name;
  final String type;
  final String? serialNumber;

  TableItemModel({
    required this.id,
    required this.name,
    required this.type,
    this.serialNumber,
  });

  factory TableItemModel.fromJson(Map<String, dynamic> json) {
    return TableItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      serialNumber: json['serialNumber'] as String?,
    );
  }
}