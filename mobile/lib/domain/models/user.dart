
class TokenResponse {
  final String accessToken;
  final String tokenType;
  final String role;

  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.role,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        role: json['role'] as String,
      );
}

class StudentProfile {
  final String id;
  final String enrollmentNumber;
  final String? firstName;
  final String? lastName;
  final bool faceRegistered;

  const StudentProfile({
    required this.id,
    required this.enrollmentNumber,
    this.firstName,
    this.lastName,
    this.faceRegistered = false,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        id: json['id'] as String,
        enrollmentNumber: json['enrollment_number'] as String,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        faceRegistered: json['face_registered'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'enrollment_number': enrollmentNumber,
        'first_name': firstName,
        'last_name': lastName,
        'face_registered': faceRegistered,
      };
}

class UserProfile {
  final String id;
  final String email;
  final String role;
  final bool isActive;
  final StudentProfile? studentProfile;

  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.studentProfile,
  });

  bool get hasFaceRegistered => studentProfile?.faceRegistered ?? false;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final studentJson = json['student_profile'] as Map<String, dynamic>?;
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      studentProfile:
          studentJson != null ? StudentProfile.fromJson(studentJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'is_active': isActive,
        'student_profile': studentProfile?.toJson(),
      };
}
