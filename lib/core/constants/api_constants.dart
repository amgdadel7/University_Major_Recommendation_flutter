import 'api_config.dart';

class ApiConstants {
  // Base URL - Get from ApiConfig (supports different platforms)
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  
  // Universities endpoints
  static const String universities = '/universities';
  
  // Majors endpoints
  static const String majors = '/majors';
  
  // Recommendations endpoints
  static const String recommendations = '/recommendations';
  static const String recommendationsGenerate = '/recommendations/generate';
  
  // AI endpoints
  static const String aiSettings = '/ai/settings';
  
  // Applications endpoints
  static const String applications = '/applications';
  
  // Survey endpoints
  static const String survey = '/survey';
  static const String surveyQuestions = '/survey/questions';
  static const String surveySubmit = '/survey/submit';
  static const String surveyMyAnswers = '/survey/my-answers';
  static const String surveySaveAnswer = '/survey/save-answer';
  static const String surveyCompletionStatus = '/survey/completion-status';
  
  // Students endpoints
  static const String studentsMeGrades = '/students/me/grades';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}

