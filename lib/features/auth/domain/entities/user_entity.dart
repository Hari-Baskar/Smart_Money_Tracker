class UserEntity {
  final String id;
  final String? phoneNumber;
  final String? name;

  const UserEntity({
    required this.id,
    this.phoneNumber,
    this.name,
  });
}
