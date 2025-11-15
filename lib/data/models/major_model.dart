import 'dart:convert';

class MajorModel {
  final int majorId;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final List<String>? skills;
  final List<Map<String, dynamic>>? careerOpportunities;
  final List<String>? admissionRequirements;

  MajorModel({
    required this.majorId,
    required this.name,
    this.description,
    this.createdAt,
    this.skills,
    this.careerOpportunities,
    this.admissionRequirements,
  });

  factory MajorModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and PascalCase from API
    final id = json['id'] ?? json['MajorID'] ?? json['majorId'] ?? json['majorID'];
    final nameValue = json['Name'] ?? json['name'] ?? '';
    final descriptionValue = json['Description'] ?? json['description'];
    
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Parse skills - support both array and comma-separated string
    List<String>? parseSkills(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return null;
    }

    // Parse career opportunities - support both array and JSON string
    List<Map<String, dynamic>>? parseCareerOpportunities(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e is Map<String, dynamic> ? e : {'title': e.toString(), 'salary': ''}).toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e is Map<String, dynamic> ? e : {'title': e.toString(), 'salary': ''}).toList();
          }
        } catch (e) {
          // If parsing fails, return null
        }
      }
      return null;
    }

    // Parse admission requirements - support both array and comma-separated string
    List<String>? parseAdmissionRequirements(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return null;
    }

    return MajorModel(
      majorId: _parseInt(id) ?? 0,
      name: nameValue as String? ?? '',
      description: descriptionValue as String?,
      createdAt: parseDate(json['CreatedAt'] ?? json['createdAt']),
      skills: parseSkills(json['Skills'] ?? json['skills']),
      careerOpportunities: parseCareerOpportunities(json['CareerOpportunities'] ?? json['careerOpportunities'] ?? json['career_opportunities']),
      admissionRequirements: parseAdmissionRequirements(json['AdmissionRequirements'] ?? json['admissionRequirements'] ?? json['admission_requirements']),
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
      'id': majorId,
      'MajorID': majorId,
      'Name': name,
      'Description': description,
      'CreatedAt': createdAt?.toIso8601String(),
      'Skills': skills,
      'CareerOpportunities': careerOpportunities,
      'AdmissionRequirements': admissionRequirements,
    };
  }
}

