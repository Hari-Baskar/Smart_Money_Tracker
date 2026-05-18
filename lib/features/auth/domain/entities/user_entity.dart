class UserEntity {
  final String id;
  final String? name;
  final String? photoUrl;
  final bool isAnonymous;

  const UserEntity({
    required this.id,
    this.name,
    this.photoUrl,
    this.isAnonymous = false,
  });
}
