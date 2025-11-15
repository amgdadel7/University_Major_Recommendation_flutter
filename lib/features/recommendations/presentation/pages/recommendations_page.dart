import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/models/recommendation_model.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final ApiService _apiService = ApiService();
  List<RecommendationModel> _recommendations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _sortBy = 'confidence'; // confidence, date, name

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    Logger.info('Starting to load recommendations', 'RecommendationsPage');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recommendations = await _apiService.getRecommendations();
      Logger.success('Received ${recommendations.length} recommendations from API', 'RecommendationsPage');
      
      // Group recommendations by majorId
      final groupedRecommendations = _groupRecommendationsByMajor(recommendations);
      
      setState(() {
        _recommendations = _sortRecommendations(groupedRecommendations);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      Logger.error('Error loading recommendations', 'RecommendationsPage', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Group recommendations by majorName to prevent duplicates - combine all recommendations for the same major
  List<RecommendationModel> _groupRecommendationsByMajor(List<RecommendationModel> recommendations) {
    // Use majorName as key to prevent duplicates even if IDs differ
    final Map<String, List<RecommendationModel>> groupedByMajor = {};
    
    // Group recommendations by majorName (normalize to handle null/empty cases)
    for (final recommendation in recommendations) {
      final majorName = recommendation.majorName?.trim() ?? '';
      if (majorName.isEmpty) {
        // If no major name, use majorId as fallback
        final fallbackKey = 'major_${recommendation.majorId}';
        if (!groupedByMajor.containsKey(fallbackKey)) {
          groupedByMajor[fallbackKey] = [];
        }
        groupedByMajor[fallbackKey]!.add(recommendation);
      } else {
        if (!groupedByMajor.containsKey(majorName)) {
          groupedByMajor[majorName] = [];
        }
        groupedByMajor[majorName]!.add(recommendation);
      }
    }
    
    // Create merged recommendations - take the best one for each major
    final List<RecommendationModel> mergedRecommendations = [];
    
    for (final entry in groupedByMajor.entries) {
      final majorRecommendations = entry.value;
      
      // Find the recommendation with the highest confidence score
      majorRecommendations.sort((a, b) {
        final aScore = a.confidenceScore ?? 0.0;
        final bScore = b.confidenceScore ?? 0.0;
        return bScore.compareTo(aScore);
      });
      
      // Calculate average confidence score from all recommendations for this major
      double? averageConfidence;
      if (majorRecommendations.isNotEmpty) {
        final totalConfidence = majorRecommendations
            .where((r) => r.confidenceScore != null)
            .map((r) => r.confidenceScore!)
            .fold(0.0, (sum, score) => sum + score);
        final count = majorRecommendations.where((r) => r.confidenceScore != null).length;
        if (count > 0) {
          averageConfidence = totalConfidence / count;
        }
      }
      
      // Use the best recommendation as the base
      final bestRecommendation = majorRecommendations.first;
      
      // Create a merged recommendation (without university name)
      // Use average confidence if available, otherwise use best recommendation's score
      final mergedRecommendation = RecommendationModel(
        recommendationId: bestRecommendation.recommendationId,
        studentId: bestRecommendation.studentId,
        majorId: bestRecommendation.majorId,
        recommendationText: bestRecommendation.recommendationText,
        confidenceScore: averageConfidence ?? bestRecommendation.confidenceScore,
        biasDetected: bestRecommendation.biasDetected,
        modelVersion: bestRecommendation.modelVersion,
        majorName: bestRecommendation.majorName,
        majorDescription: bestRecommendation.majorDescription,
        universityName: null, // Hide university name - available in multiple universities
        universityId: null, // Hide university ID
        studentName: bestRecommendation.studentName,
        feedback: bestRecommendation.feedback,
        createdAt: bestRecommendation.createdAt,
      );
      
      mergedRecommendations.add(mergedRecommendation);
      
      // Log grouping info
      if (majorRecommendations.length > 1) {
        Logger.info(
          'Grouped ${majorRecommendations.length} recommendations for major "${bestRecommendation.majorName}" (ID: ${bestRecommendation.majorId})',
          'RecommendationsPage',
        );
      }
    }
    
    Logger.info(
      'Grouped ${recommendations.length} recommendations into ${mergedRecommendations.length} unique majors',
      'RecommendationsPage',
    );
    
    return mergedRecommendations;
  }

  List<RecommendationModel> _sortRecommendations(List<RecommendationModel> recommendations) {
    switch (_sortBy) {
      case 'confidence':
        recommendations.sort((a, b) {
          final aScore = a.confidenceScore ?? 0.0;
          final bScore = b.confidenceScore ?? 0.0;
          return bScore.compareTo(aScore);
        });
        break;
      case 'date':
        recommendations.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case 'name':
        recommendations.sort((a, b) {
          final aName = a.majorName ?? '';
          final bName = b.majorName ?? '';
          return aName.compareTo(bName);
        });
        break;
    }
    return recommendations;
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
              'Error loading recommendations',
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
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Professional Header Section with Premium Design
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row with Refresh Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Title - Premium Typography
                        Text(
                          'recommendations.title'.tr(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            letterSpacing: -0.3,
                            height: 1.25,
                            color: isDark 
                                ? AppColors.textPrimaryDark 
                                : const Color(0xFF1E293B),
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15, end: 0),
                        const SizedBox(height: 10),
                        // Count Badge - Minimalist Design
                        Text(
                          '${_recommendations.length} ${'recommendations.total'.tr()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            letterSpacing: 0.1,
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Premium Refresh Button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: _loadRecommendations,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withOpacity(0.08)
                              : AppColors.backgroundLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark.withOpacity(0.3)
                                : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.refresh_rounded,
                          color: isDark 
                              ? AppColors.textSecondaryDark 
                              : AppColors.textSecondaryLight,
                          size: 22,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms).scale(
                    begin: const Offset(0.85, 0.85),
                  ),
                ],
              ),
              
              const SizedBox(height: 22),
              
              // Premium Sort Options Section
              Row(
                children: [
                  // Sort Label - Clean Design
                  Text(
                    'recommendations.sort_by'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark 
                          ? AppColors.textSecondaryDark 
                          : AppColors.textSecondaryLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Sort Pills - Premium Design
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _SortChip(
                            label: 'recommendations.confidence'.tr(),
                            value: 'confidence',
                            selectedValue: _sortBy,
                            onSelected: (value) {
                              setState(() {
                                _sortBy = value;
                                _recommendations = _sortRecommendations(_recommendations);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _SortChip(
                            label: 'recommendations.date'.tr(),
                            value: 'date',
                            selectedValue: _sortBy,
                            onSelected: (value) {
                              setState(() {
                                _sortBy = value;
                                _recommendations = _sortRecommendations(_recommendations);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _SortChip(
                            label: 'recommendations.name'.tr(),
                            value: 'name',
                            selectedValue: _sortBy,
                            onSelected: (value) {
                              setState(() {
                                _sortBy = value;
                                _recommendations = _sortRecommendations(_recommendations);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(
                begin: -0.08,
                end: 0,
              ),
            ],
          ),
        ),
          
          // Recommendations List
        Expanded(
          child: _recommendations.isEmpty
              ? _EmptyState(
                  onStartTap: () => context.push('/grades'),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  color: AppColors.primaryLight,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _recommendations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final recommendation = _recommendations[index];
                      return _RecommendationCard(
                        recommendation: recommendation,
                        onTap: () {
                          context.push('/major/${recommendation.majorId}');
                        },
                      ).animate()
                          .fadeIn(delay: Duration(milliseconds: 250 + (index * 40)))
                          .slideY(begin: 0.1, end: 0, duration: 300.ms);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.secondaryLight.withOpacity(0.25)
                    : AppColors.secondaryLight.withOpacity(0.15))
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? AppColors.secondaryLight.withOpacity(0.4)
                      : AppColors.secondaryLight.withOpacity(0.3))
                  : (isDark
                      ? AppColors.borderDark.withOpacity(0.4)
                      : AppColors.borderLight),
              width: isSelected ? 1 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondaryLight.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (isDark
                          ? AppColors.secondaryLight
                          : AppColors.textPrimaryLight)
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.15,
                  height: 1.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.secondaryLight
                      : AppColors.textPrimaryLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendationModel recommendation;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = ((recommendation.confidenceScore ?? 0.0) * 100).toInt();
    final matchColor = _getMatchColor(confidence);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: matchColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: matchColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - Title and Confidence Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Match Badge Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Match Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: matchColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: matchColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: matchColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'recommendations.match'.tr(),
                                  style: TextStyle(
                                    color: matchColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Major Title
                          Text(
                            recommendation.majorName ?? 'recommendations.no_data'.tr(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              height: 1.3,
                              color: isDark 
                                  ? AppColors.textPrimaryDark 
                                  : const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // University Name (if available)
                          if (recommendation.universityName != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 16,
                                  color: isDark 
                                      ? AppColors.textSecondaryDark 
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${'recommendations.university_name'.tr()}: ${recommendation.universityName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      color: isDark 
                                          ? AppColors.textSecondaryDark 
                                          : AppColors.textSecondaryLight,
                                      height: 1.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Student Name (for teachers/admins)
                          if (recommendation.studentName != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: isDark 
                                      ? AppColors.textSecondaryDark 
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    recommendation.studentName!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: isDark 
                                          ? AppColors.textSecondaryDark 
                                          : AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confidence Badge - Top Right
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: matchColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: matchColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$confidence%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Recommendation Text Section
                if (recommendation.recommendationText != null &&
                    recommendation.recommendationText!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: matchColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: matchColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 18,
                              color: matchColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'recommendations.recommendation_text'.tr(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: matchColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recommendation.recommendationText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            fontSize: 14,
                            color: isDark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Major Description Section
                if (recommendation.majorDescription != null &&
                    recommendation.majorDescription!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: matchColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          size: 18,
                          color: matchColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'recommendations.major_description'.tr(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: matchColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                recommendation.majorDescription!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.5,
                                  fontSize: 13,
                                  color: isDark 
                                      ? AppColors.textSecondaryDark 
                                      : AppColors.textPrimaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Model Version and Creation Date
                if (recommendation.modelVersion != null ||
                    recommendation.createdAt != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (recommendation.modelVersion != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark.withOpacity(0.3)
                                  : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.code_rounded,
                                size: 14,
                                color: isDark 
                                    ? AppColors.textSecondaryDark 
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${'recommendations.model_version'.tr()}: v${recommendation.modelVersion}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? AppColors.textSecondaryDark 
                                      : AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (recommendation.createdAt != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark.withOpacity(0.3)
                                  : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: isDark 
                                    ? AppColors.textSecondaryDark 
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${'recommendations.created_at'.tr()}: ${_formatDate(recommendation.createdAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? AppColors.textSecondaryDark 
                                      : AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],

                // Bias Detected Warning
                if (recommendation.biasDetected == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warningLight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: AppColors.warningLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'recommendations.bias_detected'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warningLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: matchColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: matchColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'recommendations.view_details'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 90) return AppColors.successLight;
    if (percentage >= 75) return AppColors.primaryLight;
    if (percentage >= 60) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'common.today'.tr();
    } else if (difference.inDays == 1) {
      return 'common.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'home.days_ago'.tr()}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStartTap;

  const _EmptyState({required this.onStartTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.stars_rounded,
                size: 64,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'recommendations.no_recommendations'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark 
                    ? AppColors.textPrimaryDark 
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'recommendations.start_assessment_msg'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: isDark 
                    ? AppColors.textSecondaryDark 
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight,
                    AppColors.secondaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onStartTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  'home.start_assessment'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
