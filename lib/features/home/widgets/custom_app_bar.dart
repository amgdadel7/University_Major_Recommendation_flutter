import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/theme/bloc/theme_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String _userName = 'User';
  String _userRole = 'student';
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _apiService.getMe();
      if (mounted) {
        setState(() {
          _userName = user.fullName;
          final role = user.role;
          if (role.isNotEmpty) {
            _userRole = role.toLowerCase();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // If API call fails, try to get from AuthBloc
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          setState(() {
            _userName = authState.user.fullName;
            final role = authState.user.role;
            if (role.isNotEmpty) {
              _userRole = role.length > 1
                  ? role[0].toUpperCase() + role.substring(1).toLowerCase()
                  : role.toUpperCase();
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        // Reload user data when auth state changes
        if (authState is AuthAuthenticated) {
          _loadUserData();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // Update from AuthBloc if available (for immediate updates)
          String displayName = _userName;
          String displayRole = _userRole;
          
          if (authState is AuthAuthenticated) {
            displayName = authState.user.fullName;
            final role = authState.user.role;
            if (role.isNotEmpty) {
              displayRole = role.toLowerCase();
            }
          }
        
          return SafeArea(
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 64,
                borderRadius: 20,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.6),
                        ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryDark.withOpacity(0.3),
                          AppColors.secondaryDark.withOpacity(0.2),
                        ]
                      : [
                          AppColors.primaryLight.withOpacity(0.2),
                          AppColors.secondaryLight.withOpacity(0.1),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // User Profile with Animation (Non-clickable)
                      Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      AppColors.primaryDark,
                                      AppColors.secondaryDark,
                                    ]
                                  : [
                                      AppColors.primaryLight,
                                      AppColors.secondaryLight,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                      size: 24,
                                    ),
                            ),
                          ),
                      )
                          .animate(controller: _animationController)
                          .scale(delay: 0.ms, duration: 300.ms, curve: Curves.easeOutBack)
                          .fadeIn(delay: 0.ms, duration: 300.ms),
                      
                      const SizedBox(width: 12),
                      
                      // User Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                                .animate(controller: _animationController)
                                .slideX(begin: -0.2, end: 0, delay: 100.ms, duration: 300.ms)
                                .fadeIn(delay: 100.ms, duration: 300.ms),
                            const SizedBox(height: 2),
                            Text(
                              _getTranslatedRole(displayRole),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                                .animate(controller: _animationController)
                                .slideX(begin: -0.2, end: 0, delay: 150.ms, duration: 300.ms)
                                .fadeIn(delay: 150.ms, duration: 300.ms),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Language Toggle
                      _AnimatedIconButton(
                        icon: Icons.language_rounded,
                        tooltip: 'settings.language'.tr(),
                        isDark: isDark,
                        onPressed: () {
                          _showLanguageDialog(context);
                        },
                        animationDelay: 200,
                        animationController: _animationController,
                      ),
                      
                      // Theme Toggle
                      BlocBuilder<ThemeBloc, ThemeState>(
                        builder: (context, state) {
                          final isLight = state.themeMode == ThemeMode.light ||
                              (state.themeMode == ThemeMode.system &&
                                  MediaQuery.of(context).platformBrightness ==
                                      Brightness.light);
                          
                          return _AnimatedIconButton(
                            icon: isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            tooltip: 'settings.theme'.tr(),
                            isDark: isDark,
                            onPressed: () {
                              context.read<ThemeBloc>().add(ToggleThemeEvent());
                            },
                            animationDelay: 250,
                            animationController: _animationController,
                          );
                        },
                      ),
                      
                      // Settings
                      _AnimatedIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'settings.title'.tr(),
                        isDark: isDark,
                        onPressed: () {
                          context.push('/settings');
                        },
                        animationDelay: 300,
                        animationController: _animationController,
                      ),
                    ],
                  ),
                ),
              )
                  .animate(controller: _animationController)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.3, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
            ),
          );
        },
      ),
    );
  }
  
  String _getTranslatedRole(String role) {
    final roleKey = role.toLowerCase();
    switch (roleKey) {
      case 'student':
        return 'roles.student'.tr();
      case 'teacher':
        return 'roles.teacher'.tr();
      case 'admin':
        return 'roles.admin'.tr();
      case 'university':
        return 'roles.university'.tr();
      default:
        return role;
    }
  }
  
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'settings.language'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : AppColors.backgroundLight,
                  ),
                  child: Row(
                    children: [
                      const Text('🇺🇸', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      const Text(
                        'English',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.setLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : AppColors.backgroundLight,
                  ),
                  child: Row(
                    children: [
                      const Text('🇸🇦', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      const Text(
                        'العربية',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;
  final int animationDelay;
  final AnimationController animationController;

  const _AnimatedIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
    required this.animationDelay,
    required this.animationController,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _scaleController.value = 1.0;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleController,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              _scaleController.forward(from: 0.8).then((_) {
                _scaleController.reverse();
              });
              widget.onPressed();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                widget.icon,
                color: widget.isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: 22,
              ),
            ),
          ),
        ),
      )
          .animate(controller: widget.animationController)
          .scale(
            delay: widget.animationDelay.ms,
            duration: 250.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(
            delay: widget.animationDelay.ms,
            duration: 250.ms,
          ),
    );
  }
}

