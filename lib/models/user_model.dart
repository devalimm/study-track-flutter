class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? department;
  final String? grade;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.department,
    this.grade,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      department: map['department'],
      grade: map['grade'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'department': department,
      'grade': grade,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? department,
    String? grade,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      department: department ?? this.department,
      grade: grade ?? this.grade,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
