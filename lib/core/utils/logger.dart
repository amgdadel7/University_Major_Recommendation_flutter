import 'package:flutter/foundation.dart';

/// Professional logging utility for the application
/// 
/// Provides different log levels and automatically filters logs in production
class Logger {
  static const String _tagPrefix = '🚀 [University Major]';
  
  /// Log debug information (development only)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_tagPrefix DEBUG$tagStr: $message');
    }
  }
  
  /// Log informational messages
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_tagPrefix INFO$tagStr: $message');
    }
  }
  
  /// Log warning messages
  static void warning(String message, [String? tag, dynamic error]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      final errorStr = error != null ? ' - Error: $error' : '';
      debugPrint('$_tagPrefix ⚠️  WARNING$tagStr: $message$errorStr');
    }
  }
  
  /// Log error messages
  static void error(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      final errorStr = error != null ? ' - Error: $error' : '';
      final stackStr = stackTrace != null ? '\nStack Trace:\n$stackTrace' : '';
      debugPrint('$_tagPrefix ❌ ERROR$tagStr: $message$errorStr$stackStr');
    }
  }
  
  /// Log success messages
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_tagPrefix ✅ SUCCESS$tagStr: $message');
    }
  }
  
  /// Log API request
  static void apiRequest(String method, String url, [Map<String, dynamic>? headers]) {
    if (kDebugMode) {
      debugPrint('$_tagPrefix 📡 API REQUEST: $method $url');
      if (headers != null && headers.isNotEmpty) {
        debugPrint('$_tagPrefix 📡 Headers: $headers');
      }
    }
  }
  
  /// Log API response
  static void apiResponse(int statusCode, String url, [dynamic data]) {
    if (kDebugMode) {
      final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint('$_tagPrefix $statusEmoji API RESPONSE: $statusCode $url');
      if (data != null) {
        debugPrint('$_tagPrefix 📥 Response Data: $data');
      }
    }
  }
}

