import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/logger.dart';
import '../../data/models/university_model.dart';
import '../../data/models/major_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/application_model.dart';
import '../../data/models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _handleResponse(http.Response response) async {
    Logger.apiResponse(response.statusCode, response.request?.url.toString() ?? 'Unknown');
    
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        Logger.debug('Response data keys: ${data.keys.toList()}', 'API');
        
        if (data['success'] == true) {
          return data;
        } else {
          Logger.warning('API returned success=false', 'API', data['message']);
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 401) {
        Logger.error('Unauthorized (401)', 'API');
        throw Exception('Unauthorized - Please login again');
      } else {
        Logger.error('Error status code: ${response.statusCode}', 'API');
        try {
          final data = json.decode(response.body);
          throw Exception(data['message'] ?? 'Request failed');
        } catch (e) {
          Logger.error('Error parsing error response', 'API', e);
          throw Exception('Request failed with status ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error in _handleResponse', 'API', e, stackTrace);
      rethrow;
    }
  }

  // Authentication
  Future<Map<String, dynamic>> login(
      String email, String password, String role) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
            headers: _headers,
            body: json.encode({
              'email': email,
              'password': password,
              // Note: API auto-detects role from email, but we send it for compatibility
              'role': role,
            }),
          )
          .timeout(ApiConstants.timeout);

      final data = await _handleResponse(response);
      if (data['data'] != null && data['data']['token'] != null) {
        setToken(data['data']['token']);
      }
      return data;
    } catch (e) {
      // Improve error messages for connection issues
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to API server.\n'
          'Please check:\n'
          '1. API server is running (cd university-major-recommendation-api && npm start)\n'
          '2. Correct API URL in lib/core/constants/api_config.dart\n'
          '3. For Android Emulator: use 10.0.2.2\n'
          '4. For physical devices: use your computer\'s IP address'
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
      String fullName, String email, String password, String role,
      {int? age, String? gender}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
            headers: _headers,
            body: json.encode({
              'fullName': fullName,
              'email': email,
              'password': password,
              'role': role,
              if (age != null) 'age': age,
              if (gender != null) 'gender': gender,
            }),
          )
          .timeout(ApiConstants.timeout);

      return await _handleResponse(response);
    } catch (e) {
      // Improve error messages for connection issues
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to API server.\n'
          'Please check:\n'
          '1. API server is running (cd university-major-recommendation-api && npm start)\n'
          '2. Correct API URL in lib/core/constants/api_config.dart\n'
          '3. For Android Emulator: use 10.0.2.2\n'
          '4. For physical devices: use your computer\'s IP address'
        );
      }
      rethrow;
    }
  }

  Future<UserModel> getMe() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    // Get role from user data or from token/context
    final userData = data['data'];
    final role = userData['role'] ?? 
                 (userData['Role'] ?? 'student');
    return UserModel.fromJson(userData, role);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? email,
    int? age,
    String? gender,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;

      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      final data = await _handleResponse(response);
      final userData = data['data'];
      final role = userData['role'] ?? 
                   (userData['Role'] ?? 'student');
      return UserModel.fromJson(userData, role);
    } catch (e) {
      Logger.error('Error updating profile', 'API', e);
      rethrow;
    }
  }

  // Universities
  Future<List<UniversityModel>> getUniversities() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.universities}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    final List<dynamic> universitiesJson = data['data'];
    return universitiesJson.map((json) => UniversityModel.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getAISettings() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiSettings}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    if (data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  Future<UniversityModel> getUniversityById(int universityId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.universities}/$universityId'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    return UniversityModel.fromJson(data['data']);
  }

  Future<List<MajorModel>> getUniversityMajors(int universityId) async {
    final response = await http
        .get(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.universities}/$universityId/majors'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    final List<dynamic> majorsJson = data['data'];
    return majorsJson.map((json) => MajorModel.fromJson(json)).toList();
  }

  // Majors
  Future<List<MajorModel>> getMajors() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.majors}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    final List<dynamic> majorsJson = data['data'];
    return majorsJson.map((json) => MajorModel.fromJson(json)).toList();
  }

  Future<MajorModel> getMajor(int majorId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.majors}/$majorId'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    return MajorModel.fromJson(data['data']);
  }

  // Recommendations
  Future<List<RecommendationModel>> getRecommendations() async {
    Logger.apiRequest('GET', '${ApiConstants.baseUrl}${ApiConstants.recommendations}', _headers);
    
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recommendations}'),
            headers: _headers,
          )
          .timeout(ApiConstants.timeout);

      final data = await _handleResponse(response);
      final List<dynamic> recommendationsJson = data['data'];
      Logger.info('Received ${recommendationsJson.length} recommendations', 'API');
    
      final recommendations = recommendationsJson
          .map((json) => RecommendationModel.fromJson(json))
          .toList();
      
      Logger.success('Successfully parsed ${recommendations.length} recommendations', 'API');
      return recommendations;
    } catch (e, stackTrace) {
      Logger.error('Error in getRecommendations', 'API', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateRecommendations({String? additionalContext}) async {
    Logger.apiRequest('POST', '${ApiConstants.baseUrl}${ApiConstants.recommendationsGenerate}', _headers);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recommendationsGenerate}'),
            headers: _headers,
            body: json.encode({
              if (additionalContext != null && additionalContext.trim().isNotEmpty)
                'additionalContext': additionalContext.trim(),
            }),
          )
          .timeout(ApiConstants.timeout);

      final data = await _handleResponse(response);
      return (data['data'] as Map<String, dynamic>? ?? {});
    } catch (e, stackTrace) {
      Logger.error('Error generating recommendations', 'API', e, stackTrace);
      rethrow;
    }
  }

  // Applications
  Future<List<ApplicationModel>> getApplications() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    final List<dynamic> applicationsJson = data['data'];
    return applicationsJson.map((json) => ApplicationModel.fromJson(json)).toList();
  }

  Future<ApplicationModel> getApplicationById(int applicationId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$applicationId'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    return ApplicationModel.fromJson(data['data']);
  }

  Future<Map<String, dynamic>> submitApplication(
      int universityId, int majorId) async {
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}'),
          headers: _headers,
          body: json.encode({
            'universityId': universityId,
            'majorId': majorId,
          }),
        )
        .timeout(ApiConstants.timeout);

    return await _handleResponse(response);
  }

  Future<ApplicationModel> updateApplication({
    required int applicationId,
    String? notes,
    int? universityId,
    int? majorId,
  }) async {
    final body = <String, dynamic>{};
    if (notes != null) body['notes'] = notes;
    if (universityId != null) body['universityId'] = universityId;
    if (majorId != null) body['majorId'] = majorId;

    final response = await http
        .put(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$applicationId'),
          headers: _headers,
          body: json.encode(body),
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    return ApplicationModel.fromJson(data['data']);
  }

  Future<Map<String, dynamic>> updateApplicationStatus(
      int applicationId, String status) async {
    final response = await http
        .patch(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.applications}/$applicationId/status'),
          headers: _headers,
          body: json.encode({'status': status}),
        )
        .timeout(ApiConstants.timeout);

    return await _handleResponse(response);
  }

  // Survey
  Future<List<Map<String, dynamic>>> getSurveyQuestions({
    String? type,
    String? category,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surveyQuestions}')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http
        .get(
          uri,
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    final List<dynamic> questionsJson = data['data'] ?? [];
    return questionsJson.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> submitSurveyAnswers(
      List<Map<String, dynamic>> answers) async {
    try {
      Logger.apiRequest('POST', '${ApiConstants.baseUrl}${ApiConstants.surveySubmit}', _headers);
      Logger.info('Submitting ${answers.length} survey answers', 'API');
      Logger.debug('Answers data: ${json.encode({'answers': answers})}', 'API');
      
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surveySubmit}'),
            headers: _headers,
            body: json.encode({'answers': answers}),
          )
          .timeout(ApiConstants.timeout);

      Logger.debug('Response status: ${response.statusCode}', 'API');
      Logger.debug('Response body: ${response.body}', 'API');

      final result = await _handleResponse(response);
      Logger.success('Survey answers submitted successfully', 'API');
      return result;
    } catch (e, stackTrace) {
      Logger.error('Error submitting survey answers', 'API', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMySurveyAnswers() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surveyMyAnswers}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    final List<dynamic> answersJson = data['data'] ?? [];
    return answersJson.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> saveSurveyAnswer(
      int questionId, String answer) async {
    try {
      Logger.apiRequest('POST', '${ApiConstants.baseUrl}${ApiConstants.surveySaveAnswer}', _headers);
      Logger.info('Saving single answer for question $questionId', 'API');
      
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surveySaveAnswer}'),
            headers: _headers,
            body: json.encode({
              'questionId': questionId,
              'answer': answer,
            }),
          )
          .timeout(ApiConstants.timeout);

      final result = await _handleResponse(response);
      Logger.success('Answer saved successfully', 'API');
      return result;
    } catch (e, stackTrace) {
      Logger.error('Error saving answer', 'API', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSurveyCompletionStatus() async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surveyCompletionStatus}'),
          headers: _headers,
        )
        .timeout(ApiConstants.timeout);

    final data = await _handleResponse(response);
    return (data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<Map<String, dynamic>>> getStudentGrades() async {
    try {
      Logger.apiRequest('GET', '${ApiConstants.baseUrl}${ApiConstants.studentsMeGrades}', _headers);
      Logger.info('Fetching student grades', 'API');
      
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.studentsMeGrades}'),
            headers: _headers,
          )
          .timeout(ApiConstants.timeout);

      Logger.debug('Response status: ${response.statusCode}', 'API');
      Logger.debug('Response body: ${response.body}', 'API');

      final data = await _handleResponse(response);
      final gradesList = (data['data']?['grades'] as List<dynamic>?) ?? [];
      Logger.success('Retrieved ${gradesList.length} grades', 'API');
      
      return gradesList.map((grade) => grade as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      Logger.error('Error fetching grades', 'API', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveStudentGrades(
      List<Map<String, dynamic>> grades) async {
    try {
      Logger.apiRequest('POST', '${ApiConstants.baseUrl}${ApiConstants.studentsMeGrades}', _headers);
      Logger.info('Saving ${grades.length} grades', 'API');
      Logger.debug('Grades data: ${json.encode({'grades': grades})}', 'API');
      
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.studentsMeGrades}'),
            headers: _headers,
            body: json.encode({
              'grades': grades,
            }),
          )
          .timeout(ApiConstants.timeout);

      Logger.debug('Response status: ${response.statusCode}', 'API');
      Logger.debug('Response body: ${response.body}', 'API');

      final result = await _handleResponse(response);
      Logger.success('Grades saved successfully', 'API');
      return result;
    } catch (e, stackTrace) {
      Logger.error('Error saving grades', 'API', e, stackTrace);
      rethrow;
    }
  }
}

