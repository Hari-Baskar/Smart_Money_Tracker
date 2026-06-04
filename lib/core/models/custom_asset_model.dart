class CustomAssetModel {
  final String id;
  final String name;
  final String type; // 'bank' or 'payment_method'

  CustomAssetModel({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  factory CustomAssetModel.fromMap(Map<String, dynamic> map) {
    return CustomAssetModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
    );
  }
}
