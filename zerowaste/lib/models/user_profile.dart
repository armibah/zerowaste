class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.avatarPath,
  });

  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? avatarPath;

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
      avatarPath: clearAvatar ? null : avatarPath ?? this.avatarPath,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? email}) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      email: email ?? (map['email'] as String? ?? ''),
      fullName: map['full_name'] as String? ?? 'Eco Hero',
      avatarUrl: map['avatar_url'] as String?,
      avatarPath: map['avatar_path'] as String?,
    );
  }
}
