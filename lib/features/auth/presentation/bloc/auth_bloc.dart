import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final String role;
  
  LoginEvent({
    required this.email,
    required this.password,
    required this.role,
  });
  
  @override
  List<Object?> get props => [email, password, role];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  final int? age;
  final String? gender;
  
  RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.age,
    this.gender,
  });
  
  @override
  List<Object?> get props => [name, email, password, role, age, gender];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class AutoLoginEvent extends AuthEvent {}

class UpdateUserEvent extends AuthEvent {
  final UserModel user;
  
  UpdateUserEvent(this.user);
  
  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  
  AuthAuthenticated({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final SharedPreferences? prefs;
  
  AuthBloc({this.prefs}) 
    : _apiService = ApiService(), 
      super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<AutoLoginEvent>(_onAutoLogin);
    on<UpdateUserEvent>(_onUpdateUser);
  }
  
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final response = await _apiService.login(
        event.email,
        event.password,
        event.role,
      );
      
      if (response['data'] != null && response['data']['user'] != null) {
        final userData = response['data']['user'];
        // Use role from API response instead of event.role (API auto-detects role)
        final detectedRole = userData['role'] ?? event.role;
        final user = UserModel.fromJson(userData, detectedRole);
        
        // Save token and user data to storage
        if (prefs != null) {
          await prefs!.setString('token', response['data']['token']);
          await prefs!.setString('user_data', user.toJson().toString());
          // Clear logout flag on successful login
          await prefs!.setBool('user_logged_out', false);
        }
        
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError('Invalid response from server'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final response = await _apiService.register(
        event.name,
        event.email,
        event.password,
        event.role,
        age: event.age,
        gender: event.gender,
      );
      
      if (response['data'] != null) {
        // Clear logout flag before login (will be set again on successful login)
        if (prefs != null) {
          await prefs!.setBool('user_logged_out', false);
        }
        
        // After successful registration, perform login
        add(LoginEvent(
          email: event.email,
          password: event.password,
          role: event.role,
        ));
      } else {
        emit(AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      // Clear API token
      _apiService.clearToken();
      
      if (prefs != null) {
        // Clear authentication data
        await prefs!.remove('token');
        await prefs!.remove('user_data');
        
        // Set flag to prevent auto-login after logout
        await prefs!.setBool('user_logged_out', true);
        
        // Optionally clear remember me data (uncomment if needed)
        // await prefs!.remove('remember_me');
        // await prefs!.remove('remembered_email');
        // await prefs!.remove('remembered_password');
      }
      
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if there's an error, emit unauthenticated state
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    try {
      // Check if token exists in storage
      if (prefs != null) {
        final token = prefs!.getString('token');
        if (token != null && token.isNotEmpty) {
          _apiService.setToken(token);
          
          // Try to get user data
          try {
            final user = await _apiService.getMe();
            
            // Clear logout flag on successful token check
            await prefs!.setBool('user_logged_out', false);
            
            emit(AuthAuthenticated(user: user));
            return;
          } catch (e) {
            // Token expired or invalid
            await prefs!.remove('token');
            await prefs!.remove('user_data');
          }
        }
      }
      
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAutoLogin(AutoLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      if (prefs == null) {
        emit(AuthUnauthenticated());
        return;
      }
      
      // Check if user logged out manually - if so, don't auto-login
      final userLoggedOut = prefs!.getBool('user_logged_out') ?? false;
      if (userLoggedOut) {
        emit(AuthUnauthenticated());
        return;
      }
      
      // First check if token exists and is valid
      final token = prefs!.getString('token');
      if (token != null && token.isNotEmpty) {
        _apiService.setToken(token);
        
        try {
          final user = await _apiService.getMe();
          
          // Clear logout flag on successful token validation
          await prefs!.setBool('user_logged_out', false);
          
          emit(AuthAuthenticated(user: user));
          return;
        } catch (e) {
          // Token expired or invalid, clear it and try with saved credentials
          await prefs!.remove('token');
          await prefs!.remove('user_data');
        }
      }
      
      // Try auto login with saved credentials if "Remember Me" is enabled
      final shouldRemember = prefs!.getBool('remember_me') ?? false;
      if (shouldRemember) {
        final savedEmail = prefs!.getString('remembered_email');
        final savedPassword = prefs!.getString('remembered_password');
        
        if (savedEmail != null && 
            savedPassword != null && 
            savedEmail.isNotEmpty && 
            savedPassword.isNotEmpty) {
          try {
            // Attempt to login with saved credentials
            final response = await _apiService.login(
              savedEmail,
              savedPassword,
              'student', // Default role
            );
            
            if (response['data'] != null && response['data']['user'] != null) {
              final userData = response['data']['user'];
              final detectedRole = userData['role'] ?? 'student';
              final user = UserModel.fromJson(userData, detectedRole);
              
              // Save token and user data to storage
              await prefs!.setString('token', response['data']['token']);
              await prefs!.setString('user_data', user.toJson().toString());
              
              // Clear logout flag on successful auto-login
              await prefs!.setBool('user_logged_out', false);
              
              emit(AuthAuthenticated(user: user));
              return;
            }
          } catch (e) {
            // Login failed, clear saved credentials
            await prefs!.remove('remembered_email');
            await prefs!.remove('remembered_password');
            await prefs!.setBool('remember_me', false);
          }
        }
      }
      
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onUpdateUser(UpdateUserEvent event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      emit(AuthAuthenticated(user: event.user));
      // Update stored user data
      if (prefs != null) {
        await prefs!.setString('user_data', event.user.toJson().toString());
      }
    }
  }
}

