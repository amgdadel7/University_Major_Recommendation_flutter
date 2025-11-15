import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait a bit for splash animation (minimum 1 second)
    await Future.delayed(const Duration(seconds: 1));
    
    // Trigger auto login check
    if (!_hasCheckedAuth && mounted) {
      _hasCheckedAuth = true;
      context.read<AuthBloc>().add(AutoLoginEvent());
    }
  }

  void _handleAuthState(AuthState state) {
    if (!mounted || _hasNavigated) return;

    if (state is AuthAuthenticated) {
      // User is authenticated, go to main page
      _hasNavigated = true;
      Future.microtask(() {
        if (mounted) {
          context.go('/');
        }
      });
    } else if (state is AuthUnauthenticated || state is AuthError) {
      // Wait a bit more if still loading
      if (state is! AuthLoading) {
        _hasNavigated = true;
        // User is not authenticated, go to login page
        Future.microtask(() {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    }
    // If AuthLoading, wait for next state
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _handleAuthState(state);
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? AppColors.primaryGradientDark
                  : AppColors.primaryGradientLight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: AppColors.primaryLight,
                  ),
                )
                    .animate()
                    .scale(delay: 200.ms, duration: 600.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 30),

                // App Name
                Text(
                  'app_name'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 60),

                // Loading Indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ), // <- This parenthesis was missing
    ); // <- This semicolon was missing
  }
}