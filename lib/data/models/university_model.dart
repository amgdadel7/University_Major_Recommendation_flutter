class UniversityModel {
  final int universityId;
  final String name;
  final String? englishName;
  final String? location;
  final String? email;
  final String? phone;
  final String? website;
  final String? status;
  final int? totalMajors;
  final int? totalApplications;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  UniversityModel({
    required this.universityId,
    required this.name,
    this.englishName,
    this.location,
    this.email,
    this.phone,
    this.website,
    this.status,
    this.totalMajors,
    this.totalApplications,
    this.createdAt,
    this.approvedAt,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and PascalCase from API
    final id = json['id'] ?? json['UniversityID'] ?? json['universityId'];
    final nameValue = json['Name'] ?? json['name'] ?? '';
    final englishNameValue = json['EnglishName'] ?? json['englishName'];
    final locationValue = json['Location'] ?? json['location'];
    final emailValue = json['email'] ?? json['Email'];
    final phoneValue = json['phone'] ?? json['Phone'];
    final websiteValue = json['website'] ?? json['Website'];
    final statusValue = json['Status'] ?? json['status'] ?? json['accountStatus'] ?? json['AccountStatus'];
    
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UniversityModel(
      universityId: _parseInt(id) ?? 0,
      name: nameValue as String? ?? '',
      englishName: englishNameValue as String?,
      location: locationValue as String?,
      email: emailValue as String?,
      phone: phoneValue as String?,
      website: websiteValue as String?,
      status: statusValue as String?,
      totalMajors: _parseInt(json['totalMajors'] ?? json['TotalMajors']),
      totalApplications: _parseInt(json['totalApplications'] ?? json['TotalApplications']),
      createdAt: parseDate(json['CreatedAt'] ?? json['createdAt']),
      approvedAt: parseDate(json['approvedAt'] ?? json['ApprovedAt']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': universityId,
      'UniversityID': universityId,
      'Name': name,
      'EnglishName': englishName,
      'Location': location,
      'email': email,
      'phone': phone,
      'website': website,
      'Status': status,
      'totalMajors': totalMajors,
      'totalApplications': totalApplications,
      'CreatedAt': createdAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}

