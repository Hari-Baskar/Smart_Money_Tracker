class CustomAssetModel {
  final String id;
  final String name;
  final String type; // 'bank' or 'payment_method'
  final bool isArchived;

  CustomAssetModel({
    required this.id,
    required this.name,
    required this.type,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory CustomAssetModel.fromMap(Map<String, dynamic> map) {
    return CustomAssetModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      isArchived: map['isArchived'] == 1 || map['isArchived'] == true,
    );
  }
}
