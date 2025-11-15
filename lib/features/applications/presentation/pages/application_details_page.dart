import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/application_model.dart';

class ApplicationDetailsPage extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailsPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  final ApiService _apiService = ApiService();
  ApplicationModel? _application;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplicationDetails();
  }

  Future<void> _loadApplicationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final applicationId = int.tryParse(widget.applicationId);
      if (applicationId == null) {
        throw Exception('application.invalid_application_id'.tr());
      }

      // Load application details from API
      final application = await _apiService.getApplicationById(applicationId);

      setState(() {
        _application = application;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'applications_status.error_loading'.tr()}: ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            action: SnackBarAction(
              label: 'common.retry'.tr(),
              textColor: Colors.white,
              onPressed: _loadApplicationDetails,
            ),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getStatusInfo(String? status) {
    final statusValue = status ?? 'pending';
    switch (statusValue.toLowerCase()) {
      case 'pending':
        return {
          'label': 'applications_status.pending'.tr(),
          'icon': Icons.schedule_rounded,
          'color': AppColors.warningLight,
          'bgColor': const Color(0xFFFFF9E6),
        };
      case 'under-review':
      case 'under_review':
        return {
          'label': 'applications_status.under_review'.tr(),
          'icon': Icons.hourglass_empty_rounded,
          'color': AppColors.accentLight,
          'bgColor': const Color(0xFFE6F7FF),
        };
      case 'accepted':
        return {
          'label': 'applications_status.accepted'.tr(),
          'icon': Icons.check_circle_rounded,
          'color': AppColors.successLight,
          'bgColor': const Color(0xFFE6F7F0),
        };
      case 'rejected':
        return {
          'label': 'applications_status.rejected'.tr(),
          'icon': Icons.cancel_rounded,
          'color': AppColors.errorLight,
          'bgColor': const Color(0xFFFFE6E6),
        };
      default:
        return {
          'label': 'applications_status.pending'.tr(),
          'icon': Icons.schedule_rounded,
          'color': AppColors.warningLight,
          'bgColor': const Color(0xFFFFF9E6),
        };
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'application.today'.tr();
    } else if (difference.inDays == 1) {
      return 'application.yesterday'.tr();
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('application.details'.tr()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _application == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('application.details'.tr()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.errorLight),
              const SizedBox(height: 16),
              Text(
                'applications_status.error_loading'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'applications_status.no_applications'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadApplicationDetails,
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final statusInfo = _getStatusInfo(_application!.status);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('application.details'.tr()),
        actions: [
          if (_application!.status?.toLowerCase() == 'pending')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                context.push(
                  '/application/edit/${_application!.applicationId}',
                  extra: _application,
                ).then((_) {
                  // Refresh the details when returning from edit
                  _loadApplicationDetails();
                });
              },
              tooltip: 'applications_status.edit'.tr(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusInfo['bgColor'],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusInfo['color'].withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      statusInfo['icon'],
                      color: statusInfo['color'],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusInfo['label'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusInfo['color'],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_application!.appliedAt),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: statusInfo['color'].withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 24),

            // University & Major Info
            _DetailSection(
              title: 'application.university_major'.tr(),
              children: [
                _DetailItem(
                  icon: Icons.school_outlined,
                  label: 'application.university'.tr(),
                  value: _application!.universityName ?? 'N/A',
                ),
                const SizedBox(height: 16),
                _DetailItem(
                  icon: Icons.menu_book_outlined,
                  label: 'application.major'.tr(),
                  value: _application!.majorName ?? 'N/A',
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

            const SizedBox(height: 20),

            // Student Info
            _DetailSection(
              title: 'application.student_info'.tr(),
              children: [
                _DetailItem(
                  icon: Icons.person_outline,
                  label: 'application.name'.tr(),
                  value: _application!.studentName ?? 'N/A',
                ),
                if (_application!.studentEmail != null) ...[
                  const SizedBox(height: 16),
                  _DetailItem(
                    icon: Icons.email_outlined,
                    label: 'application.email'.tr(),
                    value: _application!.studentEmail!,
                  ),
                ],
                if (_application!.appliedAt != null) ...[
                  const SizedBox(height: 16),
                  _DetailItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'application.applied_date'.tr(),
                    value: _formatDate(_application!.appliedAt),
                  ),
                ],
              ],
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

            // Notes
            if (_application!.notes != null && _application!.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailSection(
                title: 'application.notes'.tr(),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _application!.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
            ],

            // Status Progress (for under-review)
            if (_application!.status?.toLowerCase() == 'under-review' ||
                _application!.status?.toLowerCase() == 'under_review') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'application.review_progress'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color']),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 12),
                      Text(
                        'applications_status.application_reviewed'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusInfo['color'],
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

