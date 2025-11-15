class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final int? age;
  final String? gender;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.age,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String role) {
    // API returns 'id' directly, but also check for role-specific IDs as fallback
    int userId;
    if (json['id'] != null) {
      userId = json['id'] as int? ?? 0;
    } else {
      final idKey = role == 'student' 
          ? 'StudentID' 
          : role == 'teacher' 
              ? 'TeacherID' 
              : role == 'university'
                  ? 'UserID'
                  : 'AdminID';
      userId = json[idKey] as int? ?? json['id'] as int? ?? 0;
    }
    
    return UserModel(
      id: userId,
      fullName: json['name'] as String? ?? json['FullName'] as String? ?? '',
      email: json['email'] as String? ?? json['Email'] as String? ?? '',
      role: role,
      age: json['Age'] as int? ?? json['age'] as int?,
      gender: json['Gender'] as String? ?? json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'FullName': fullName,
      'Email': email,
      'role': role,
      'Age': age,
      'Gender': gender,
    };
  }
}

