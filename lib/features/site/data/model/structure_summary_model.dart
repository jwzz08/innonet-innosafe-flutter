class StructureSummaryModel {
  final int id;
  final String name;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int siteGroupId;

  StructureSummaryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.siteGroupId,
  });

  factory StructureSummaryModel.fromJson(Map<String, dynamic> json) {
    return StructureSummaryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      siteGroupId: json['siteGroupId'] as int,
    );
  }
}