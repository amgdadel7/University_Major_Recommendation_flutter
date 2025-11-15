import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.terms_required'.tr()),
            backgroundColor: AppColors.errorLight,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      context.read<AuthBloc>().add(
        RegisterEvent(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
          role: 'student',
          age: _ageController.text.isNotEmpty 
              ? int.tryParse(_ageController.text) 
              : null,
          gender: _selectedGender,
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.email_required'.tr();
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'auth.email_invalid'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.password_required'.tr();
    }
    if (value.length < 8) {
      return 'auth.password_weak'.tr();
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.age_required'.tr();
    }
    final age = int.tryParse(value);
    if (age == null || age < 16 || age > 100) {
      return 'auth.age_invalid'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          setState(() {
            _isLoading = false;
          });
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.registration_success'.tr()),
              backgroundColor: AppColors.successLight,
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate to home
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/');
            }
          });
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
          });
          
          // Handle specific error messages
          String errorMessage = state.message;
          if (errorMessage.toLowerCase().contains('email') && 
              errorMessage.toLowerCase().contains('exists')) {
            errorMessage = 'auth.email_exists'.tr();
          } else if (errorMessage.toLowerCase().contains('registration failed')) {
            errorMessage = 'auth.registration_failed'.tr();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.errorLight,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'common.close'.tr(),
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Button
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: isDark 
                              ? AppColors.textPrimaryDark 
                              : AppColors.textPrimaryLight,
                        ),
                        onPressed: () => context.go('/login'),
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Logo/Icon
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryLight,
                              AppColors.secondaryLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'auth.create_account'.tr(),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark 
                            ? AppColors.textPrimaryDark 
                            : AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'auth.welcome_message'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 40),
                    
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'auth.full_name'.tr(),
                        hintText: 'auth.enter_full_name'.tr(),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primaryLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? AppColors.surfaceDark 
                            : AppColors.surfaceLight,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.name_required'.tr();
                        }
                        if (value.trim().length < 3) {
                          return 'auth.name_min_length'.tr();
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'auth.email'.tr(),
                        hintText: 'auth.enter_email'.tr(),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.primaryLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? AppColors.surfaceDark 
                            : AppColors.surfaceLight,
                      ),
                      validator: _validateEmail,
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Age and Gender Row
                    Row(
                      children: [
                        // Age Field
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'auth.age'.tr(),
                              hintText: 'auth.enter_age'.tr(),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.primaryLight,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: isDark 
                                  ? AppColors.surfaceDark 
                                  : AppColors.surfaceLight,
                            ),
                            validator: _validateAge,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gender Dropdown
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'auth.gender'.tr(),
                              hintText: 'auth.select_gender'.tr(),
                              prefixIcon: Icon(
                                Icons.wc_outlined,
                                color: AppColors.primaryLight,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: isDark 
                                  ? AppColors.surfaceDark 
                                  : AppColors.surfaceLight,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('auth.male'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('auth.female'.tr()),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.gender_required'.tr();
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'auth.password'.tr(),
                        hintText: 'auth.enter_password'.tr(),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primaryLight,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? AppColors.surfaceDark 
                            : AppColors.surfaceLight,
                      ),
                      validator: _validatePassword,
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'auth.confirm_password'.tr(),
                        hintText: 'auth.enter_confirm_password'.tr(),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primaryLight,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? AppColors.surfaceDark 
                            : AppColors.surfaceLight,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.confirm_password_required'.tr();
                        }
                        if (value != _passwordController.text) {
                          return 'auth.passwords_not_match'.tr();
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Terms and Conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'auth.terms_acceptance'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark 
                                    ? AppColors.textSecondaryDark 
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Register Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading || _isLoading;
                        
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryLight,
                                AppColors.secondaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'auth.register'.tr(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.9, 0.9)),
                    
                    const SizedBox(height: 32),
                    
                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'auth.already_have_account'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'auth.sign_in'.tr(),
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1100.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
