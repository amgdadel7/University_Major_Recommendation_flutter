import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/recommendation_model.dart';
import '../../../../data/models/application_model.dart';
import 'main_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  List<RecommendationModel> _recommendations = [];
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    Logger.info('Starting to load home data', 'HomePage');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getMe(),
        _apiService.getRecommendations().catchError((e) {
          Logger.warning('Error loading recommendations', 'HomePage', e);
          return <RecommendationModel>[];
        }),
        _apiService.getApplications().catchError((e) {
          Logger.warning('Error loading applications', 'HomePage', e);
          return <ApplicationModel>[];
        }),
      ]);

      final user = results[0] as UserModel;
      final recommendations = results[1] as List<RecommendationModel>;
      final applications = results[2] as List<ApplicationModel>;

      // Remove duplicate recommendations based on majorId or majorName
      final uniqueRecommendations = <RecommendationModel>[];
      final seenMajorIds = <int>{};
      final seenMajorNames = <String>{};

      for (final rec in recommendations) {
        // Check by majorId first (more reliable)
        if (rec.majorId != null) {
          if (!seenMajorIds.contains(rec.majorId)) {
            seenMajorIds.add(rec.majorId!);
            uniqueRecommendations.add(rec);
          }
        } 
        // If no majorId, check by majorName
        else if (rec.majorName != null && rec.majorName!.isNotEmpty) {
          final normalizedName = rec.majorName!.trim().toLowerCase();
          if (!seenMajorNames.contains(normalizedName)) {
            seenMajorNames.add(normalizedName);
            uniqueRecommendations.add(rec);
          }
        }
        // If neither exists, add it (shouldn't happen, but just in case)
        else if (uniqueRecommendations.isEmpty || 
                 uniqueRecommendations.last.recommendationId != rec.recommendationId) {
          uniqueRecommendations.add(rec);
        }
      }

      Logger.success('Home data loaded successfully - User: ${user.fullName}, Recommendations: ${uniqueRecommendations.length} (${recommendations.length} before deduplication), Applications: ${applications.length}', 'HomePage');

      setState(() {
        _user = user;
        _recommendations = uniqueRecommendations;
        _applications = applications;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('Error loading home data', 'HomePage', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHomeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final user = _user ?? UserModel(
      id: 0,
      fullName: 'User',
      email: 'user@email.com',
      role: 'student',
    );

    final stats = _calculateStats();

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Welcome Header Card
            _WelcomeCard(
              user: user,
              isDark: isDark,
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

            const SizedBox(height: 24),

            // Statistics Cards
            _StatsSection(
              stats: stats,
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'home.quick_actions'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            _QuickActionsGrid(
              onGradeTap: () => context.push('/grades'),
              onSurveyTap: () => context.push('/survey/interests'),
              onUniversitiesTap: () {
                // Navigate to universities tab (index 2)
                MainPage.of(context)?.changeTab(2);
              },
              onApplicationsTap: () {
                // Navigate to applications tab (index 3)
                MainPage.of(context)?.changeTab(3);
              },
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Recent Recommendations
            if (_recommendations.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home.recent_recommendations'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to recommendations tab (index 1)
                      MainPage.of(context)?.changeTab(1);
                    },
                    child: Text('home.view_all'.tr()),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 12),

              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendations.length > 3 ? 3 : _recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final rec = _recommendations[index];
                    return _RecommendationCard(
                      recommendation: rec,
                      width: 280,
                    ).animate().fadeIn(delay: Duration(milliseconds: 600 + (index * 100))).slideX(begin: 0.2, end: 0);
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Recent Applications
            if (_applications.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home.recent_applications'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to applications tab (index 3)
                      MainPage.of(context)?.changeTab(3);
                    },
                    child: Text('home.view_all'.tr()),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 12),

              ..._applications.take(3).map((app) {
                final index = _applications.indexOf(app);
                return _ApplicationCard(
                  application: app,
                ).animate().fadeIn(delay: Duration(milliseconds: 800 + (index * 100))).slideX(begin: -0.2, end: 0);
              }).toList(),
            ],

            // Empty State
            if (_recommendations.isEmpty && _applications.isEmpty)
              _EmptyState(
                onStartTap: () => context.push('/grades'),
              ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    return {
      'recommendations': _recommendations.length,
      'applications': _applications.length,
      'accepted': _applications.where((a) => a.status?.toLowerCase() == 'accepted').length,
      'pending': _applications.where((a) => a.status?.toLowerCase() == 'pending').length,
    };
  }
}

class _WelcomeCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const _WelcomeCard({
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'home.good_morning'.tr()
        : hour < 18
            ? 'home.good_afternoon'.tr()
            : 'home.good_evening'.tr();

    return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? AppColors.primaryGradientDark
                    : AppColors.primaryGradientLight,
              ),
        borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
            greeting,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.fullName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  user.role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.stars_rounded,
            value: stats['recommendations'].toString(),
            label: 'home.recommendations'.tr(),
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.description_rounded,
            value: stats['applications'].toString(),
            label: 'home.applications'.tr(),
            color: AppColors.accentLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: stats['accepted'].toString(),
            label: 'home.accepted'.tr(),
            color: AppColors.successLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onGradeTap;
  final VoidCallback onSurveyTap;
  final VoidCallback onUniversitiesTap;
  final VoidCallback onApplicationsTap;

  const _QuickActionsGrid({
    required this.onGradeTap,
    required this.onSurveyTap,
    required this.onUniversitiesTap,
    required this.onApplicationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
            children: [
              _QuickActionCard(
                icon: Icons.edit_note_rounded,
                title: 'grades.title'.tr(),
                color: AppColors.accentLight,
          onTap: onGradeTap,
        ),
              _QuickActionCard(
          icon: Icons.quiz_rounded,
          title: 'home.start_survey'.tr(),
                color: AppColors.successLight,
          onTap: onSurveyTap,
        ),
              _QuickActionCard(
                icon: Icons.school_rounded,
                title: 'universities.title'.tr(),
                color: AppColors.secondaryLight,
          onTap: onUniversitiesTap,
        ),
              _QuickActionCard(
                icon: Icons.description_rounded,
                title: 'applications_status.title'.tr(),
                color: AppColors.warningLight,
          onTap: onApplicationsTap,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendationModel recommendation;
  final double width;

  const _RecommendationCard({
    required this.recommendation,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = ((recommendation.confidenceScore ?? 0.0) * 100).toInt();
    final matchColor = _getMatchColor(confidence);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matchColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: matchColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: matchColor,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: matchColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$confidence%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.majorName ?? 'Unknown Major',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 90) return AppColors.successLight;
    if (percentage >= 75) return AppColors.primaryLight;
    if (percentage >= 60) return AppColors.warningLight;
    return AppColors.errorLight;
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(application.status ?? 'pending');
    final timeAgo = _formatTimeAgo(application.appliedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              statusInfo['icon'],
              color: statusInfo['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(
                  application.universityName ?? 'Unknown University',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            const SizedBox(height: 4),
                Text(
                  application.majorName ?? 'Unknown Major',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            const SizedBox(height: 4),
            Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusInfo['label'],
              style: TextStyle(
                color: statusInfo['color'],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            ),
          ],
        ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'label': 'applications_status.pending'.tr(),
          'icon': Icons.schedule_rounded,
          'color': AppColors.warningLight,
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
          'color': AppColors.successLight,
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
          'icon': Icons.schedule_rounded,
          'color': AppColors.warningLight,
        };
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'home.recently'.tr();

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${'home.days_ago'.tr()}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${'home.hours_ago'.tr()}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${'home.minutes_ago'.tr()}';
    }
    return 'home.recently'.tr();
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStartTap;

  const _EmptyState({required this.onStartTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'home.no_data_yet'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'home.get_started_message'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onStartTap,
            icon: const Icon(Icons.arrow_forward),
            label: Text('home.start_assessment'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
