import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadThemeEvent extends ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  
  SetThemeEvent(this.themeMode);
  
  @override
  List<Object?> get props => [themeMode];
}

// States
class ThemeState extends Equatable {
  final ThemeMode themeMode;
  
  const ThemeState({required this.themeMode});
  
  @override
  List<Object?> get props => [themeMode];
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences prefs;
  static const String _themeKey = 'theme_mode';
  
  ThemeBloc(this.prefs) : super(const ThemeState(themeMode: ThemeMode.system)) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ToggleThemeEvent>(_onToggleTheme);
    on<SetThemeEvent>(_onSetTheme);
  }
  
  Future<void> _onLoadTheme(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    final themeModeString = prefs.getString(_themeKey);
    ThemeMode themeMode;
    
    switch (themeModeString) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    
    emit(ThemeState(themeMode: themeMode));
  }
  
  Future<void> _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    ThemeMode newThemeMode;
    
    if (state.themeMode == ThemeMode.light) {
      newThemeMode = ThemeMode.dark;
    } else {
      newThemeMode = ThemeMode.light;
    }
    
    await _saveThemeMode(newThemeMode);
    emit(ThemeState(themeMode: newThemeMode));
  }
  
  Future<void> _onSetTheme(SetThemeEvent event, Emitter<ThemeState> emit) async {
    await _saveThemeMode(event.themeMode);
    emit(ThemeState(themeMode: event.themeMode));
  }
  
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    String themeModeString;
    
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await prefs.setString(_themeKey, themeModeString);
  }
}

