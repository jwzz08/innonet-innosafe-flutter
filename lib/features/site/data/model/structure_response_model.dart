import 'package:flutter/foundation.dart';

// 1. 최상위 Structure 응답 모델
class StructureResponseModel {
  final int id;
  final String name;
  final String type;
  final List<StructureWidgetModel> widgets;

  StructureResponseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.widgets,
  });

  factory StructureResponseModel.fromJson(Map<String, dynamic> json) {
    return StructureResponseModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      widgets: (json['widgets'] as List? ?? [])
          .map((i) => StructureWidgetModel.fromJson(i))
          .toList(),
    );
  }
}

// 2. 위젯 모델 (좌표 및 속성 포함)
class StructureWidgetModel {
  final int id;
  final String type;
  final int x;
  final int y;
  final int w;
  final int h;
  final Map<String, dynamic> properties;
  final StructureImagePropertiesModel? structureImageProperties; // site_image일 때만 파싱

  StructureWidgetModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.properties,
    this.structureImageProperties,
  });

  factory StructureWidgetModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final props = json['properties'] as Map<String, dynamic>? ?? {};

    // type이 'site_image'인 경우 별도 모델로 파싱
    StructureImagePropertiesModel? imageProps;
    if (type == 'site_image') {
      imageProps = StructureImagePropertiesModel.fromJson(props);
    }

    return StructureWidgetModel(
      id: json['id'] as int,
      type: type,
      x: json['x'] as int,
      y: json['y'] as int,
      w: json['w'] as int,
      h: json['h'] as int,
      properties: props,
      structureImageProperties: imageProps,
    );
  }
}

// 3. Structure Image(도면) 전용 속성 모델
class StructureImagePropertiesModel {
  final List<MapIconModel> iconList;
  final List<TableItemModel> tableList;
  final List<int> deviceRemoveList;

  StructureImagePropertiesModel({
    required this.iconList,
    required this.tableList,
    required this.deviceRemoveList,
  });

  factory StructureImagePropertiesModel.fromJson(Map<String, dynamic> json) {
    return StructureImagePropertiesModel(
      iconList: (json['iconList'] as List? ?? [])
          .map((i) => MapIconModel.fromJson(i))
          .toList(),
      tableList: (json['tableList'] as List? ?? [])
          .map((i) => TableItemModel.fromJson(i))
          .toList(),
      deviceRemoveList: (json['deviceRemoveList'] as List? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }
}

// 4. 아이콘 모델 (ID 가변성 처리)
class MapIconModel {
  final dynamic id;
  final String name;
  final String type;
  final double xPercent;
  final double yPercent;
  final String? reactKey;
  final int? humanCount;
  final String? serialNumber;
  final Map<String, dynamic> properties;

  MapIconModel({
    required this.id,
    required this.name,
    required this.type,
    required this.xPercent,
    required this.yPercent,
    this.reactKey,
    this.humanCount,
    this.serialNumber,
    required this.properties,
  });

  factory MapIconModel.fromJson(Map<String, dynamic> json) {
    return MapIconModel(
      id: json['id'],
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      xPercent: (json['xPercent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['yPercent'] as num?)?.toDouble() ?? 0.0,
      reactKey: json['reactKey'] as String?,
      humanCount: json['humanCount'] as int?,
      serialNumber: json['serialNumber'] as String?,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  // ID를 리스트로 안전하게 반환하는 헬퍼
  List<int> getIds() {
    if (id is int) return [id];
    if (id is List) return List<int>.from(id);
    return [];
  }

  // 특수 속성 접근 헬퍼 (굴진률 등)
  double get progressValue => (properties['progressValue'] as num?)?.toDouble() ?? 0.0;
  String get targetColor => properties['targetColor'] as String? ?? '#000000';
  String get progressColor => properties['progressColor'] as String? ?? '#000000';
  double? get sizeX => (properties['sizeX'] as num?)?.toDouble();
  double? get sizeY => (properties['sizeY'] as num?)?.toDouble();
}

// 5. 테이블 아이템 모델 (리스트 뷰용)
class TableItemModel {
  final int id;
  final String name;
  final String type;
  final int? humanCount;
  final String? serialNumber;
  // 필요 시 properties 추가

  TableItemModel({
    required this.id,
    required this.name,
    required this.type,
    this.humanCount,
    this.serialNumber,
  });

  factory TableItemModel.fromJson(Map<String, dynamic> json) {
    return TableItemModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      humanCount: json['humanCount'] as int?,
      serialNumber: json['serialNumber'] as String?,
    );
  }
}