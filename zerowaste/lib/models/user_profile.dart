class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final String email;
  final String avatarUrl;

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) {
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Eco Hero',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
    );
  }
}
