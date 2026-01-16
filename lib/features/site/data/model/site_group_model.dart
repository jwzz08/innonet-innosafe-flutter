class SiteGroupModel {
  final int id;
  final String name;
  final String type;

  SiteGroupModel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory SiteGroupModel.fromJson(Map<String, dynamic> json) {
    return SiteGroupModel(
      id: json['id'],
      name: json['name'] ?? 'Unknown Site',
      type: json['type'] ?? 'Unknown',
    );
  }
}