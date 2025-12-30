class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;

  Profile({required this.id, this.email, this.fullName, this.avatarUrl});

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        email: m['email'] as String?,
        fullName: m['full_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
      };
}
