import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/application_model.dart';

class ApplicationFormPage extends StatefulWidget {
  final String? universityId;
  final String? majorId;
  final String? applicationId;
  final dynamic application; // ApplicationModel for editing

  const ApplicationFormPage({
    super.key,
    this.universityId,
    this.majorId,
    this.applicationId,
    this.application,
  }) : assert(
          (universityId != null && majorId != null) || 
          (applicationId != null && application != null),
          'Either universityId/majorId or applicationId/application must be provided',
        );

  @override
  State<ApplicationFormPage> createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  int _currentStep = 0;
  bool _isEditMode = false;
  
  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gpaController = TextEditingController();
  final _satController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedEducationLevel;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.application != null;
    if (_isEditMode && widget.application is ApplicationModel) {
      final app = widget.application as ApplicationModel;
      // Pre-fill form with existing data if editing
      // Note: API might not return all fields, so we populate what we can
      if (app.studentName != null) {
        final nameParts = app.studentName!.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
        _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }
      _emailController.text = app.studentEmail ?? '';
      if (app.notes != null) {
        _notesController.text = app.notes!;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gpaController.dispose();
    _satController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'application.edit_title'.tr() : 'application.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep++;
              });
            } else {
              _submitApplication();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            }
          },
          steps: [
            // Personal Information
            Step(
              title: Text('application.personal_info'.tr()),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'application.first_name'.tr(),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'application.required'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'application.last_name'.tr(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'application.required'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'application.email'.tr(),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'application.required'.tr();
                      }
                      if (!value.contains('@')) {
                        return 'application.invalid_email'.tr();
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'application.phone'.tr(),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'application.required'.tr();
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'application.address'.tr(),
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'application.required'.tr();
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
            
            // Academic Information
            Step(
              title: Text('application.academic_info'.tr()),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _gpaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'application.gpa'.tr(),
                      prefixIcon: const Icon(Icons.school_outlined),
                      suffixText: '/ 4.0',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'application.required'.tr();
                      }
                      final gpa = double.tryParse(value);
                      if (gpa == null || gpa < 0 || gpa > 4) {
                        return 'application.invalid_gpa'.tr();
                      }
                      return null;
                    },
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _satController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'application.sat_score'.tr(),
                      prefixIcon: const Icon(Icons.assessment_outlined),
                      suffixText: '/ 1600',
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'application.previous_education'.tr(),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    value: _selectedEducationLevel,
                    items: [
                      // Education levels - should be fetched from API
                      // For now, using empty list - data should come from API
                      // This can be replaced when API endpoint for education levels is available
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEducationLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'application.required'.tr();
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
            
            // Documents
            Step(
              title: Text('application.documents'.tr()),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  _DocumentUploadCard(
                    title: 'application.transcript'.tr(),
                    icon: Icons.description_outlined,
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                  _DocumentUploadCard(
                    title: 'application.id_passport'.tr(),
                    icon: Icons.credit_card_outlined,
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                  _DocumentUploadCard(
                    title: 'application.recommendation_letter'.tr(),
                    icon: Icons.mail_outline,
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                  _DocumentUploadCard(
                    title: 'application.personal_statement'.tr(),
                    icon: Icons.article_outlined,
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _isEditMode 
                          ? 'application.additional_notes'.tr() 
                          : 'application.notes_optional'.tr(),
                      hintText: 'application.notes_hint'.tr(),
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
          ],
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: Text('application.back'.tr()),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? 'application.submit'.tr() : 'application.continue'.tr()),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      BuildContext? dialogContext;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'application.submitting'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        if (_isEditMode) {
          // Update existing application
          final applicationId = int.tryParse(widget.applicationId ?? '');
          if (applicationId == null) {
            throw Exception('application.invalid_application_id'.tr());
          }

          // Get university and major IDs from the application or form
          int? universityId;
          int? majorId;
          
          if (widget.application is ApplicationModel) {
            final app = widget.application as ApplicationModel;
            universityId = app.universityId;
            majorId = app.majorId;
          }

          // Update application via API
          await _apiService.updateApplication(
            applicationId: applicationId,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            universityId: universityId,
            majorId: majorId,
          );
        } else {
          // Submit new application
          final universityId = int.tryParse(widget.universityId ?? '');
          final majorId = int.tryParse(widget.majorId ?? '');
          
          if (universityId == null || majorId == null) {
            throw Exception('application.invalid_university_major'.tr());
          }

          // Submit application via API
          await _apiService.submitApplication(universityId, majorId);
        }
        
        // Close loading dialog
        if (mounted && dialogContext != null) {
          Navigator.pop(dialogContext!);
        }
        
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.successLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 60,
                        color: AppColors.successLight,
                      ),
                    ).animate().scale(),
                    const SizedBox(height: 24),
                    Text(
                      _isEditMode
                          ? 'application.updated_success'.tr()
                          : 'application.submitted_success'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    Text(
                      _isEditMode
                          ? 'application.updated_message'.tr()
                          : 'application.success_message'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (_isEditMode) {
                            // Pop back to details page or list
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'application.done'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted && dialogContext != null) {
          Navigator.pop(dialogContext!);
        }
        
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.errorLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 32,
                        color: AppColors.errorLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'application.error_submitting'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${'application.error_message'.tr()}: $e',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('application.ok'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DocumentUploadCard({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryLight,
          ),
        ),
        title: Text(title),
        subtitle: Text('application.no_file_selected'.tr()),
        trailing: IconButton(
          icon: const Icon(Icons.upload_file_rounded),
          onPressed: () {
            // Handle file upload
          },
        ),
      ),
    );
  }
}

