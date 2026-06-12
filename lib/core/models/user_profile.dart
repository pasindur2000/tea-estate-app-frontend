class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? estateId;
  final String status;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.estateId,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        estateId: json['estateId'] as String?,
        status: json['status'] as String,
      );

  bool get isDirector => role == 'director';
  bool get isSupervisor => role == 'supervisor';
}
