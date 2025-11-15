class ApplicationModel {
  final int applicationId;
  final int studentId;
  final int majorId;
  final int? universityId;
  final String? status;
  final DateTime? appliedAt;
  final String? notes;
  final String? majorName;
  final String? universityName;
  final String? studentName;
  final String? studentEmail;

  ApplicationModel({
    required this.applicationId,
    required this.studentId,
    required this.majorId,
    this.universityId,
    this.status,
    this.appliedAt,
    this.notes,
    this.majorName,
    this.universityName,
    this.studentName,
    this.studentEmail,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and PascalCase from API
    final id = json['id'] ?? json['ApplicationID'] ?? json['applicationId'];
    final studentIdValue = json['studentId'] ?? json['StudentID'] ?? json['studentID'];
    final majorIdValue = json['majorId'] ?? json['MajorID'] ?? json['majorID'];
    final universityIdValue = json['universityId'] ?? json['UniversityID'] ?? json['universityID'];
    
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ApplicationModel(
      applicationId: _parseInt(id) ?? 0,
      studentId: _parseInt(studentIdValue) ?? 0,
      majorId: _parseInt(majorIdValue) ?? 0,
      universityId: _parseInt(universityIdValue),
      status: json['Status'] as String? ?? json['status'] as String?,
      appliedAt: parseDate(json['AppliedAt'] ?? json['appliedAt'] ?? json['SubmissionDate'] ?? json['submissionDate']),
      notes: json['Notes'] as String? ?? json['notes'] as String?,
      majorName: json['majorName'] as String? ?? json['MajorName'] as String?,
      universityName: json['universityName'] as String? ?? json['UniversityName'] as String?,
      studentName: json['studentName'] as String? ?? json['StudentName'] as String?,
      studentEmail: json['studentEmail'] as String? ?? json['StudentEmail'] as String?,
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
      'id': applicationId,
      'ApplicationID': applicationId,
      'studentId': studentId,
      'StudentID': studentId,
      'majorId': majorId,
      'MajorID': majorId,
      'universityId': universityId,
      'UniversityID': universityId,
      'Status': status,
      'AppliedAt': appliedAt?.toIso8601String(),
      'Notes': notes,
      'majorName': majorName,
      'MajorName': majorName,
      'universityName': universityName,
      'UniversityName': universityName,
      'studentName': studentName,
      'StudentName': studentName,
      'studentEmail': studentEmail,
      'StudentEmail': studentEmail,
    };
  }
}

