import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/application_model.dart';

class ApplicationsListPage extends StatefulWidget {
  const ApplicationsListPage({super.key});

  @override
  State<ApplicationsListPage> createState() => _ApplicationsListPageState();
}

class _ApplicationsListPageState extends State<ApplicationsListPage> {
  final ApiService _apiService = ApiService();
  List<ApplicationModel> _applications = [];
  List<ApplicationModel> _filteredApplications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final applications = await _apiService.getApplications();
      setState(() {
        _applications = applications;
        _filteredApplications = applications;
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
            content: Text('Error loading applications: ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadApplications,
            ),
          ),
        );
      }
    }
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
      if (status == null) {
        _filteredApplications = _applications;
      } else {
        _filteredApplications = _applications.where((app) {
          return app.status?.toLowerCase() == status.toLowerCase();
        }).toList();
      }
    });
  }

  Map<String, int> _getStatusCounts() {
    return {
      'all': _applications.length,
      'pending': _applications.where((a) => a.status?.toLowerCase() == 'pending').length,
      'under-review': _applications.where((a) => a.status?.toLowerCase() == 'under-review' || a.status?.toLowerCase() == 'under_review').length,
      'accepted': _applications.where((a) => a.status?.toLowerCase() == 'accepted').length,
      'rejected': _applications.where((a) => a.status?.toLowerCase() == 'rejected').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    final statusCounts = _getStatusCounts();

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'applications_status.title'.tr(),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          '${_applications.length} ${'applications_status.total'.tr()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadApplications,
                    tooltip: 'common.refresh'.tr(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'applications_status.all'.tr(),
                      count: statusCounts['all'] ?? 0,
                      isSelected: _selectedStatus == null,
                      onSelected: () => _filterByStatus(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'applications_status.pending'.tr(),
                      count: statusCounts['pending'] ?? 0,
                      isSelected: _selectedStatus == 'pending',
                      onSelected: () => _filterByStatus('pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'applications_status.under_review'.tr(),
                      count: statusCounts['under-review'] ?? 0,
                      isSelected: _selectedStatus == 'under-review',
                      onSelected: () => _filterByStatus('under-review'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'applications_status.accepted'.tr(),
                      count: statusCounts['accepted'] ?? 0,
                      isSelected: _selectedStatus == 'accepted',
                      onSelected: () => _filterByStatus('accepted'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'applications_status.rejected'.tr(),
                      count: statusCounts['rejected'] ?? 0,
                      isSelected: _selectedStatus == 'rejected',
                      onSelected: () => _filterByStatus('rejected'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),

        // Applications List
        Expanded(
          child: _filteredApplications.isEmpty
              ? _EmptyState(
                  isFiltered: _selectedStatus != null,
                  onClearFilter: () => _filterByStatus(null),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredApplications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final application = _filteredApplications[index];
                      return _ApplicationCard(
                        application: application,
                        onViewDetails: () async {
                          await context.push('/application/${application.applicationId}');
                          // Refresh applications when returning
                          _loadApplications();
                        },
                        onEdit: () async {
                          await context.push(
                            '/application/edit/${application.applicationId}',
                            extra: application,
                          );
                          // Refresh applications when returning
                          _loadApplications();
                        },
                      ).animate()
                          .fadeIn(delay: Duration(milliseconds: 300 + (index * 50)))
                          .slideX(begin: -0.2, end: 0);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: isSelected
          ? AppColors.primaryLight.withValues(alpha: 0.1)
          : Colors.transparent,
      selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryLight : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;

  const _ApplicationCard({
    required this.application,
    required this.onViewDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(application.status ?? 'pending');
    final theme = Theme.of(context);
    final isPending = application.status?.toLowerCase() == 'pending';
    final isAccepted = application.status?.toLowerCase() == 'accepted';
    
    // Background color based on status (matching the image)
    Color cardBackgroundColor;
    if (isAccepted) {
      cardBackgroundColor = const Color(0xFFE6F7F0); // Light green
    } else if (isPending) {
      cardBackgroundColor = const Color(0xFFFFF9E6); // Light yellow/cream
    } else {
      cardBackgroundColor = theme.cardColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusInfo['color'].withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Status Badge on left
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusInfo['label'],
                      style: TextStyle(
                        color: statusInfo['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status Icon on right
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusInfo['icon'],
                      color: statusInfo['color'],
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // University Name
              Text(
                application.universityName ?? 'applications_status.unknown_university'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Major Name
              Text(
                application.majorName ?? 'applications_status.unknown_major'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),
              
              // Application Details (Student Name and Date)
              Row(
                children: [
                  if (application.studentName != null) ...[
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      application.studentName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (application.appliedAt != null) ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(application.appliedAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),

              // Notes
              if (application.notes != null && application.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          application.notes!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Status Progress (for under-review)
              if (application.status?.toLowerCase() == 'under-review' ||
                  application.status?.toLowerCase() == 'under_review') ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        'applications_status.application_reviewed'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusInfo['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('applications_status.edit'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                      label: Text(
                        'applications_status.view_details'.tr(),
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'label': 'applications_status.pending'.tr(),
          'icon': Icons.access_time_rounded,
          'color': const Color(0xFFFF9800), // Orange for pending
        };
      case 'under-review':
      case 'under_review':
        return {
          'label': 'applications_status.under_review'.tr(),
          'icon': Icons.hourglass_empty_rounded,
          'color': AppColors.accentLight,
        };
      case 'accepted':
        return {
          'label': 'applications_status.accepted'.tr(),
          'icon': Icons.check_circle_rounded,
          'color': const Color(0xFF10B981), // Green for accepted
        };
      case 'rejected':
        return {
          'label': 'applications_status.rejected'.tr(),
          'icon': Icons.cancel_rounded,
          'color': AppColors.errorLight,
        };
      default:
        return {
          'label': 'applications_status.pending'.tr(),
          'icon': Icons.access_time_rounded,
          'color': const Color(0xFFFF9800),
        };
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'application.today'.tr();
    } else if (difference.inDays == 1) {
      return 'application.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'applications_status.days_ago'.tr()}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClearFilter;

  const _EmptyState({
    required this.isFiltered,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.filter_alt_off_outlined : Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'applications_status.no_applications_with_status'.tr()
                  : 'applications_status.no_applications'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isFiltered
                  ? 'applications_status.try_different_filter'.tr()
                  : 'applications_status.start_applying'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onClearFilter,
                child: Text('applications_status.clear_filter'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
