import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/theme/bloc/theme_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  
  String? _selectedGender;
  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _loadUserData();
    
    // Listen to controller changes
    _fullNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _apiService.getMe();
      setState(() {
        _user = user;
        _fullNameController.text = user.fullName;
        _emailController.text = user.email;
        _ageController.text = user.age?.toString() ?? '';
        // Normalize gender value to match dropdown items
        if (user.gender != null) {
          final genderLower = user.gender!.toLowerCase();
          if (genderLower == 'male' || genderLower == 'm') {
            _selectedGender = 'male';
          } else if (genderLower == 'female' || genderLower == 'f') {
            _selectedGender = 'female';
          } else {
            _selectedGender = null;
          }
        } else {
          _selectedGender = null;
        }
        _hasChanges = false;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading user data', 'SettingsPage', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.error_loading'.tr()),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = await _apiService.updateProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        age: _ageController.text.isNotEmpty 
            ? int.tryParse(_ageController.text) 
            : null,
        gender: _selectedGender,
      );

      // Update AuthBloc with new user data
      if (mounted) {
        context.read<AuthBloc>().add(UpdateUserEvent(updatedUser));
      }

      setState(() {
        _user = updatedUser;
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.profile_updated'.tr()),
            backgroundColor: AppColors.successLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error saving profile', 'SettingsPage', e);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.errorLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'common.retry'.tr(),
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('profile.edit_profile'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.edit_profile'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                _isSaving ? 'common.saving'.tr() : 'common.save'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .slideX(begin: 0.2, end: 0),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header Card
              _buildProfileHeader(isDark)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionTitle('profile.personal_info'.tr(), isDark)
                  .animate()
                  .fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              _buildPersonalInfoCard(isDark)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Account Settings Section
              _buildSectionTitle('settings.title'.tr(), isDark)
                  .animate()
                  .fadeIn(delay: 300.ms),

              const SizedBox(height: 12),

              _buildAccountSettingsCard(isDark)
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideX(begin: -0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
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
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.primaryDark.withOpacity(0.4),
                AppColors.secondaryDark.withOpacity(0.3),
              ]
            : [
                AppColors.primaryLight.withOpacity(0.3),
                AppColors.secondaryLight.withOpacity(0.2),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.primaryDark, AppColors.secondaryDark]
                        : [AppColors.primaryLight, AppColors.secondaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user?.fullName ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [AppColors.primaryDark, AppColors.secondaryDark]
                  : [AppColors.primaryLight, AppColors.secondaryLight],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(bool isDark) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 450, // Approximate height, will adjust based on content
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.topCenter,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.primaryDark.withOpacity(0.2),
                AppColors.secondaryDark.withOpacity(0.1),
              ]
            : [
                AppColors.primaryLight.withOpacity(0.15),
                AppColors.secondaryLight.withOpacity(0.1),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _fullNameController,
              label: 'auth.full_name'.tr(),
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'profile.name_required'.tr();
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'auth.email'.tr(),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'profile.email_required'.tr();
                }
                if (!value.contains('@')) {
                  return 'profile.email_invalid'.tr();
                }
                return null;
              },
              isDark: isDark,
            ),
            if (_user?.role == 'student' || _user?.role == 'teacher') ...[
              const SizedBox(height: 20),
              _buildTextField(
                controller: _ageController,
                label: 'profile.age'.tr(),
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'profile.age_invalid'.tr();
                    }
                  }
                  return null;
                },
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildGenderDropdown(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryLight),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.errorLight,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.errorLight,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'profile.gender'.tr(),
        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryLight),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'male',
          child: Text('profile.male'.tr()),
        ),
        DropdownMenuItem(
          value: 'female',
          child: Text('profile.female'.tr()),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
          _hasChanges = true;
        });
      },
    );
  }

  Widget _buildAccountSettingsCard(bool isDark) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 200, // Approximate height for settings items
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.topCenter,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.primaryDark.withOpacity(0.2),
                AppColors.secondaryDark.withOpacity(0.1),
              ]
            : [
                AppColors.primaryLight.withOpacity(0.15),
                AppColors.secondaryLight.withOpacity(0.1),
              ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.language_rounded,
            title: 'settings.language'.tr(),
            subtitle: context.locale.languageCode == 'ar' ? 'العربية' : 'English',
            onTap: () => _showLanguageDialog(context),
            isDark: isDark,
          ),
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return _buildSettingTile(
                icon: Icons.palette_rounded,
                title: 'settings.theme'.tr(),
                subtitle: _getThemeModeLabel(state.themeMode, context),
                onTap: () => _showThemeDialog(context),
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryLight),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }

  String _getThemeModeLabel(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.light:
        return 'settings.light_mode'.tr();
      case ThemeMode.dark:
        return 'settings.dark_mode'.tr();
      case ThemeMode.system:
        return 'settings.system_default'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('settings.language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: context.locale.languageCode,
              onChanged: (value) {
                context.setLocale(const Locale('en'));
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: context.locale.languageCode,
              onChanged: (value) {
                context.setLocale(const Locale('ar'));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('settings.theme'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('settings.light_mode'.tr()),
                  value: ThemeMode.light,
                  groupValue: state.themeMode,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(SetThemeEvent(value!));
                    Navigator.pop(dialogContext);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text('settings.dark_mode'.tr()),
                  value: ThemeMode.dark,
                  groupValue: state.themeMode,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(SetThemeEvent(value!));
                    Navigator.pop(dialogContext);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text('settings.system_default'.tr()),
                  value: ThemeMode.system,
                  groupValue: state.themeMode,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(SetThemeEvent(value!));
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('profile.discard_changes'.tr()),
        content: Text('profile.discard_changes_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: Colors.white,
            ),
            child: Text('common.discard'.tr()),
          ),
        ],
      ),
    );
  }
}
