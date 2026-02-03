class UserProfile {
  final String id;
  final String email;
  final String? fullName;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
  });

  // Construtor que pega os dados vindos do Supabase
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'],
    );
  }
}