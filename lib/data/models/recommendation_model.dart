import '../../core/utils/logger.dart';

class RecommendationModel {
  final int recommendationId;
  final int? studentId;
  final int majorId;
  final String? recommendationText;
  final double? confidenceScore;
  final bool? biasDetected;
  final String? modelVersion;
  final String? majorName;
  final String? majorDescription;
  final String? universityName;
  final int? universityId;
  final String? studentName;
  final String? feedback;
  final DateTime? createdAt;

  RecommendationModel({
    required this.recommendationId,
    this.studentId,
    required this.majorId,
    this.recommendationText,
    this.confidenceScore,
    this.biasDetected,
    this.modelVersion,
    this.majorName,
    this.majorDescription,
    this.universityName,
    this.universityId,
    this.studentName,
    this.feedback,
    this.createdAt,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both camelCase (from API) and PascalCase (legacy) field names
      final id = json['id'] ?? json['RecommendationID'] ?? json['recommendationId'];
      final majorIdValue = json['majorId'] ?? json['MajorID'] ?? json['majorID'];
      final studentIdValue = json['studentId'] ?? json['StudentID'] ?? json['studentID'];
      
      // Safely parse dates
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) return DateTime.tryParse(value);
        return null;
      }
      
      // Safely parse biasDetected - handle all possible types
      // Check all possible field names
      dynamic biasValue;
      if (json.containsKey('BiasDetected')) {
        biasValue = json['BiasDetected'];
      } else if (json.containsKey('biasDetected')) {
        biasValue = json['biasDetected'];
      } else if (json.containsKey('bias_detected')) {
        biasValue = json['bias_detected'];
      } else {
        biasValue = null;
      }
      
      // Use safe parsing method
      final parsedBias = _parseBool(biasValue);
      
      // Helper to safely get string value
      String? _getString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        return value.toString();
      }
      
      final recommendation = RecommendationModel(
        recommendationId: _parseInt(id) ?? 0,
        studentId: _parseInt(studentIdValue),
        majorId: _parseInt(majorIdValue) ?? 0,
        recommendationText: _getString(json['RecommendationText'] ?? json['recommendationText']),
        confidenceScore: _parseDouble(json['ConfidenceScore'] ?? json['confidenceScore']),
        biasDetected: parsedBias,
        modelVersion: _getString(json['ModelVersion'] ?? json['modelVersion']),
        majorName: _getString(json['majorName'] ?? json['MajorName']),
        majorDescription: _getString(json['majorDescription'] ?? json['MajorDescription']),
        universityName: _getString(json['universityName'] ?? json['UniversityName']),
        universityId: _parseInt(json['universityId'] ?? json['UniversityID'] ?? json['universityID']),
        studentName: _getString(json['studentName'] ?? json['StudentName']),
        feedback: _getString(json['Feedback'] ?? json['feedback']),
        createdAt: parseDate(json['GeneratedAt'] ?? json['generatedAt'] ?? json['CreatedAt'] ?? json['createdAt']),
      );
      
      return recommendation;
    } catch (e, stackTrace) {
      Logger.error('Error parsing RecommendationModel', 'RecommendationModel', e, stackTrace);
      Logger.debug('JSON data: $json', 'RecommendationModel');
      rethrow;
    }
  }
  
  // Helper method to safely parse double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  // Helper method to safely parse int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
  
  // Helper method to safely parse bool
  static bool? _parseBool(dynamic value) {
    try {
      // Handle null
      if (value == null) {
        return null;
      }
      
      // Handle bool directly
      if (value is bool) {
        return value;
      }
      
      // Handle int (MySQL TINYINT(1) returns 0 or 1)
      if (value is int) {
        return value != 0; // 0 = false, anything else = true
      }
      
      // Handle double (in case of type coercion)
      if (value is double) {
        return value != 0.0;
      }
      
      // Handle String
      if (value is String) {
        final lower = value.toLowerCase().trim();
        if (lower == 'true' || lower == '1' || lower == 'yes') {
          return true;
        } else if (lower == 'false' || lower == '0' || lower == 'no' || lower == '') {
          return false;
        } else {
          return null;
        }
      }
      
      // If we reach here, the type is not supported
      Logger.warning('Unsupported type for _parseBool: ${value.runtimeType}', 'RecommendationModel');
      return null;
    } catch (e) {
      Logger.error('Error in _parseBool', 'RecommendationModel', e);
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'RecommendationID': recommendationId,
      'StudentID': studentId,
      'MajorID': majorId,
      'RecommendationText': recommendationText,
      'ConfidenceScore': confidenceScore,
      'BiasDetected': biasDetected,
      'ModelVersion': modelVersion,
      'MajorName': majorName,
      'MajorDescription': majorDescription,
      'UniversityName': universityName,
      'UniversityID': universityId,
      'StudentName': studentName,
      'Feedback': feedback,
      'GeneratedAt': createdAt?.toIso8601String(),
      'CreatedAt': createdAt?.toIso8601String(),
    };
  }
}

