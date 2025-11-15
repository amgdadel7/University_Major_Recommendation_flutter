/// API Configuration
/// 
/// IMPORTANT: For Android/iOS emulators and physical devices:
/// - Use '10.0.2.2' for Android Emulator (points to host machine's localhost)
/// - Use your computer's IP address for physical devices (e.g., '192.168.1.100')
/// - Use 'localhost' only for web/desktop testing
/// 
/// To find your computer's IP address:
/// - Windows: ipconfig (look for IPv4 Address)
/// - Mac/Linux: ifconfig (look for inet)
/// 
/// Example for physical device: 'http://192.168.1.100:8000/api/v1'
class ApiConfig {
  // Development URLs (kept for local development - can be switched via baseUrl getter)
  // ignore: unused_field
  static const String _devBaseUrl = 'https://university-major-recommendation-api.onrender.com/api/v1';
  // ignore: unused_field
  static const String _androidEmulatorBaseUrl = 'https://university-major-recommendation-api.onrender.com/api/v1';
  
  // Production URL
  static const String _prodBaseUrl = 'https://university-major-recommendation-api.onrender.com/api/v1';
  
  // Get base URL based on platform
  // For physical devices, replace 'localhost' with your computer's IP
  // Example: 'http://192.168.1.100:8000/api/v1'
  static String get baseUrl {
    // Production URL - using Render.com hosted API
    return _prodBaseUrl;
    
    // For local development, uncomment one of the options below:
    
    // Option 1: For Android Emulator
    // return _androidEmulatorBaseUrl;
    
    // Option 2: For physical devices - Use your computer's IP address
    // Found IPs: 10.5.0.2, 10.0.0.66
    // Use the IP that matches your device's network
    // Try 10.0.0.66 first (most common local network IP)
    //return 'http://10.0.0.66:8000/api/v1'; // For physical Android device
    
    // If 10.0.0.66 doesn't work, try the other IP:
    // return 'http://10.5.0.2:8000/api/v1';
    
    // Option 3: For web/desktop/iOS Simulator
    // return _devBaseUrl;
  }
  
  // Check if running on physical device
  static bool get isPhysicalDevice {
    // This will be set dynamically based on platform detection
    // For now, you can manually set this
    return false;
  }
}

