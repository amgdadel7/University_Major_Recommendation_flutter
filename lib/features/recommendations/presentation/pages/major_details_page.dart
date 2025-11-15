import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/models/major_model.dart';
import '../../../../data/models/recommendation_model.dart';
import '../../../../data/models/university_model.dart';

class MajorDetailsPage extends StatefulWidget {
  final String majorId;

  const MajorDetailsPage({super.key, required this.majorId});

  @override
  State<MajorDetailsPage> createState() => _MajorDetailsPageState();
}

class _MajorDetailsPageState extends State<MajorDetailsPage> {
  final ApiService _apiService = ApiService();
  MajorModel? _major;
  int _matchPercentage = 85;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadMajorDetails();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMajors = prefs.getStringList('saved_majors') ?? [];
      setState(() {
        _isSaved = savedMajors.contains(widget.majorId);
      });
    } catch (e) {
      Logger.warning('Error checking saved status', 'MajorDetailsPage', e);
    }
  }

  Future<void> _loadMajorDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final majorId = int.tryParse(widget.majorId);
      if (majorId == null) {
        throw Exception('Invalid major ID');
      }

      // Load major and recommendations in parallel
      final results = await Future.wait([
        _apiService.getMajor(majorId),
        _apiService.getRecommendations().catchError((e) => <RecommendationModel>[]),
      ]);

      final major = results[0] as MajorModel;
      final recommendations = results[1] as List<RecommendationModel>;
      
      // Find matching recommendation
      int matchPercentage = 85;
      try {
        final matchingRec = recommendations.firstWhere(
          (rec) => rec.majorId == major.majorId,
        );
        if (matchingRec.confidenceScore != null) {
          matchPercentage = (matchingRec.confidenceScore! * 100).toInt();
        }
      } catch (e) {
        // No matching recommendation found, use default
      }

      setState(() {
        _major = major;
        _matchPercentage = matchPercentage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _major == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Major not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMajorDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final icon = _getIconForMajor(_major!.name);
    final color = _getColorForMajor(_major!.name);

    // Map MajorModel to MajorDetails for UI
    // Use API data if available, otherwise use fallback data
    final major = MajorDetails(
      id: widget.majorId,
      name: _major!.name,
      description: _major!.description ?? 'No description available',
      matchPercentage: _matchPercentage,
      icon: icon,
      color: color,
      skills: _major!.skills ?? _extractSkills(_major!.description ?? ''), // Use API data or fallback
      admissionRequirements: _major!.admissionRequirements ?? _generateAdmissionRequirements(_major!.name), // Use API data or fallback
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Hero Animation
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              // Save/Bookmark Button
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _toggleSave,
                  tooltip: _isSaved ? 'Remove from saved' : 'Save major',
                ),
              ),
              // Share Button
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 24),
                  onPressed: _shareMajor,
                  tooltip: 'Share major',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      major.color,
                      major.color.withOpacity(0.8),
                      major.color.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // Modern Icon Container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              major.icon,
                              size: 48,
                              color: Colors.white,
                            ),
                          ).animate().scale(delay: 100.ms, duration: 600.ms),
                          const SizedBox(height: 20),
                          Text(
                            major.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
                          const SizedBox(height: 12),
                          // Modern Match Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${major.matchPercentage}% ${'recommendations.match_percentage'.tr()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Description with Modern Design
                _ModernSectionTitle(
                  title: 'major_details.description'.tr(),
                  icon: Icons.description_rounded,
                  color: major.color,
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        major.color.withOpacity(0.08),
                        major.color.withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: major.color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    major.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      fontSize: 15,
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95)),
                
                const SizedBox(height: 30),
                
                // Skills with Modern Design
                _ModernSectionTitle(
                  title: 'major_details.skills'.tr(),
                  icon: Icons.psychology_rounded,
                  color: major.color,
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 12),
                
                major.skills.isEmpty
                    ? Text(
                        'No skills information available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ).animate().fadeIn(delay: 300.ms)
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: major.skills
                            .map((skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: major.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: major.color.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: TextStyle(
                                      color: major.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                      )
                        .animate()
                        .fadeIn(delay: 300.ms),
                
                const SizedBox(height: 30),
                
                // Admission Requirements with Modern Design
                _ModernSectionTitle(
                  title: 'major_details.admission_requirements'.tr(),
                  icon: Icons.school_rounded,
                  color: major.color,
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        major.color.withOpacity(0.08),
                        major.color.withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: major.color.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: major.color.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: major.admissionRequirements.isEmpty
                      ? Text(
                          'No admission requirements information available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: major.admissionRequirements
                              .map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.successLight.withOpacity(0.2),
                                          AppColors.successLight.withOpacity(0.1),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.successLight.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.successLight,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      req,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        height: 1.6,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                          .toList(),
                    ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms),
                
                const SizedBox(height: 30),
                
                // Modern Apply Button with Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        major.color,
                        major.color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: major.color.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _major != null
                        ? () {
                            Logger.info('Apply button pressed for major ${_major!.majorId}', 'MajorDetailsPage');
                            _showUniversitySelectionDialog();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'major_details.apply_now'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
                
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMajor(String majorName) {
    final lower = majorName.toLowerCase();
    if (lower.contains('computer') || lower.contains('programming') || lower.contains('software')) {
      return Icons.computer_rounded;
    } else if (lower.contains('electrical') || lower.contains('electronics')) {
      return Icons.electrical_services_rounded;
    } else if (lower.contains('data') || lower.contains('analytics')) {
      return Icons.analytics_rounded;
    } else if (lower.contains('mechanical') || lower.contains('engineering')) {
      return Icons.precision_manufacturing_rounded;
    } else if (lower.contains('business') || lower.contains('management')) {
      return Icons.business_rounded;
    } else if (lower.contains('medical') || lower.contains('medicine')) {
      return Icons.medical_services_rounded;
    }
    return Icons.school_rounded;
  }

  Color _getColorForMajor(String majorName) {
    final lower = majorName.toLowerCase();
    if (lower.contains('computer') || lower.contains('programming') || lower.contains('software')) {
      return AppColors.primaryLight;
    } else if (lower.contains('electrical') || lower.contains('electronics')) {
      return AppColors.accentLight;
    } else if (lower.contains('data') || lower.contains('analytics')) {
      return AppColors.secondaryLight;
    } else if (lower.contains('mechanical') || lower.contains('engineering')) {
      return Colors.orange;
    } else if (lower.contains('business') || lower.contains('management')) {
      return Colors.green;
    } else if (lower.contains('medical') || lower.contains('medicine')) {
      return Colors.red;
    }
    return AppColors.primaryLight;
  }

  List<String> _extractSkills(String description) {
    // Extract skills from description or return common skills based on major name
    final lower = _major!.name.toLowerCase();
    if (lower.contains('computer') || lower.contains('programming') || lower.contains('software')) {
      return ['Programming', 'Problem Solving', 'Data Structures', 'Algorithms', 'Software Development'];
    } else if (lower.contains('electrical') || lower.contains('electronics')) {
      return ['Circuit Design', 'Electronics', 'Signal Processing', 'Power Systems'];
    } else if (lower.contains('business') || lower.contains('management')) {
      return ['Leadership', 'Communication', 'Strategic Planning', 'Financial Analysis'];
    } else if (lower.contains('medical') || lower.contains('medicine')) {
      return ['Patient Care', 'Medical Knowledge', 'Diagnosis', 'Treatment Planning'];
    }
    return ['Critical Thinking', 'Research', 'Analysis', 'Communication'];
  }

  Future<void> _toggleSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMajors = prefs.getStringList('saved_majors') ?? [];
      
      setState(() {
        if (_isSaved) {
          savedMajors.remove(widget.majorId);
          _isSaved = false;
        } else {
          savedMajors.add(widget.majorId);
          _isSaved = true;
        }
      });
      
      await prefs.setStringList('saved_majors', savedMajors);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved 
                  ? 'Major saved successfully' 
                  : 'Major removed from saved',
            ),
            backgroundColor: _isSaved 
                ? AppColors.successLight 
                : AppColors.textSecondaryLight,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error toggling save', 'MajorDetailsPage', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving major'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _shareMajor() async {
    if (_major == null) return;
    
    try {
      final shareText = '''
🎓 ${_major!.name}

${_major!.description ?? 'No description available'}

Match Percentage: ${_matchPercentage}%

📚 Check out this major in University Major Recommendation App!
''';

      await Clipboard.setData(ClipboardData(text: shareText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Major information copied to clipboard!'),
            backgroundColor: AppColors.successLight,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      Logger.info('Major shared: ${_major!.name}', 'MajorDetailsPage');
    } catch (e) {
      Logger.error('Error sharing major', 'MajorDetailsPage', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sharing major'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  List<String> _generateAdmissionRequirements(String majorName) {
    final lower = majorName.toLowerCase();
    if (lower.contains('medical') || lower.contains('medicine')) {
      return [
        'High school diploma with excellent grades',
        'Biology, Chemistry, Physics courses',
        'Entrance exam (MCAT equivalent)',
        'Interview and recommendation letters',
      ];
    } else if (lower.contains('engineering')) {
      return [
        'High school diploma',
        'Mathematics and Physics courses',
        'Minimum GPA requirement',
        'Entrance exam scores',
      ];
    }
    return [
      'High school diploma',
      'Minimum GPA requirement',
      'Entrance exam scores',
      'Application form and documents',
    ];
  }


  // Show university selection dialog
  Future<void> _showUniversitySelectionDialog() async {
    if (_major == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Major information not available'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      Logger.info('Loading universities for major ${_major!.majorId}', 'MajorDetailsPage');
      
      // Get all universities (first batch only - will load progressively in dialog)
      final universities = await _apiService.getUniversities();
      
      if (!mounted) return;
      // Close loading dialog immediately when dialog appears
      Navigator.of(context, rootNavigator: true).pop();

      if (universities.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No universities available'),
            backgroundColor: AppColors.errorLight,
          ),
        );
        return;
      }

      // Show university selection dialog immediately with progressive loading
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => _UniversitySelectionDialog(
          allUniversities: universities,
          majorId: _major!.majorId,
          majorName: _major!.name,
          apiService: _apiService,
          onUniversitySelected: (university) {
            Navigator.of(dialogContext).pop(); // Close selection dialog
            _submitApplicationDirectly(university.universityId);
          },
        ),
      );
    } catch (e, stackTrace) {
      Logger.error('Error in _showUniversitySelectionDialog', 'MajorDetailsPage', e, stackTrace);
      
      if (!mounted) return;
      
      // Try to close loading dialog if still open
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {
        // Dialog might already be closed
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading universities: ${e.toString()}'),
          backgroundColor: AppColors.errorLight,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Submit application directly via API
  Future<void> _submitApplicationDirectly(int universityId) async {
    if (_major == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Major information not available'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      Logger.info('Submitting application for university $universityId, major ${_major!.majorId}', 'MajorDetailsPage');
      
      // Submit application via API
      await _apiService.submitApplication(universityId, _major!.majorId);
      
      Logger.success('Application submitted successfully', 'MajorDetailsPage');
      
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

      // Show success dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.successLight,
                ),
              ).animate().scale(),
              const SizedBox(height: 20),
              Text(
                'Application Submitted Successfully!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Your application has been submitted successfully. We will review it and get back to you soon.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close success dialog
                  if (mounted) {
                    Navigator.of(context).pop(); // Close major details page
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.primaryLight,
                ),
                child: const Text('Done'),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      Logger.error('Error submitting application', 'MajorDetailsPage', e, stackTrace);
      
      if (!mounted) return;
      
      // Try to close loading dialog
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {
        // Dialog might already be closed
      }

      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            e.toString().contains('already exists') || e.toString().contains('Application already exists')
                ? 'You have already submitted an application for this major at this university.'
                : 'Failed to submit application: ${e.toString()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class MajorDetails {
  final String id;
  final String name;
  final String description;
  final int matchPercentage;
  final IconData icon;
  final Color color;
  final List<String> skills;
  final List<String> admissionRequirements;

  MajorDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.matchPercentage,
    required this.icon,
    required this.color,
    required this.skills,
    required this.admissionRequirements,
  });
}

class _ModernSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _ModernSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _UniversitySelectionDialog extends StatefulWidget {
  final List<UniversityModel> allUniversities;
  final int majorId;
  final String majorName;
  final ApiService apiService;
  final Function(UniversityModel) onUniversitySelected;

  const _UniversitySelectionDialog({
    required this.allUniversities,
    required this.majorId,
    required this.majorName,
    required this.apiService,
    required this.onUniversitySelected,
  });

  @override
  State<_UniversitySelectionDialog> createState() => _UniversitySelectionDialogState();
}

class _UniversitySelectionDialogState extends State<_UniversitySelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<UniversityModel> _filteredUniversities = [];
  List<UniversityModel> _displayedUniversities = [];
  Set<int> _checkedUniversities = {}; // Track which universities have been checked for major
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUniversities();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    // Initialize filtered universities
    _filteredUniversities = List.from(widget.allUniversities);
    
    // Start with first batch (will set loading state)
    _currentPage = 0;
    await _loadBatch(0);
  }

  Future<void> _loadBatch(int page) async {
    if (_isLoading) return; // Prevent duplicate loading

    try {
      setState(() {
        _isLoading = true;
      });
      final startIndex = page * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredUniversities.length);
      
      if (startIndex >= _filteredUniversities.length) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      // Get batch to check
      final batchToCheck = _filteredUniversities.sublist(
        startIndex,
        endIndex.clamp(0, _filteredUniversities.length),
      );

      // Check which universities offer this major (in parallel)
      final futures = batchToCheck.map((university) async {
        if (_checkedUniversities.contains(university.universityId)) {
          return university;
        }
        
        try {
          final majors = await widget.apiService.getUniversityMajors(university.universityId);
          _checkedUniversities.add(university.universityId);
          
          if (majors.any((m) => m.majorId == widget.majorId)) {
            return university;
          }
        } catch (e) {
          Logger.warning(
            'Error checking majors for university ${university.universityId}',
            'UniversitySelectionDialog',
            e,
          );
        }
        return null;
      });

      final results = await Future.wait(futures);
      final validUniversities = results.whereType<UniversityModel>().toList();

      setState(() {
        if (page == 0) {
          _displayedUniversities = validUniversities;
        } else {
          _displayedUniversities.addAll(validUniversities);
        }
        _currentPage = page;
        _hasMore = endIndex < _filteredUniversities.length;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading university batch', 'UniversitySelectionDialog', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    
    await _loadBatch(_currentPage + 1);
  }

  void _filterUniversities() {
    if (_searchQuery.isEmpty) {
      _filteredUniversities = List.from(widget.allUniversities);
    } else {
      _filteredUniversities = widget.allUniversities.where((uni) {
        final name = uni.name.toLowerCase();
        final location = (uni.location ?? '').toLowerCase();
        final englishName = (uni.englishName ?? '').toLowerCase();
        
        return name.contains(_searchQuery) ||
               location.contains(_searchQuery) ||
               englishName.contains(_searchQuery);
      }).toList();
    }

    // Reset displayed universities when search changes
    _displayedUniversities = [];
    _checkedUniversities.clear();
    _currentPage = 0;
    _hasMore = true;
    
    // Load first batch
    _loadBatch(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Header with Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primaryLight.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select University',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a university for ${widget.majorName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            
            // Professional Search Field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.surfaceDark.withOpacity(0.5)
                    : AppColors.backgroundLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search universities by name or location...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryLight,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark 
                      ? AppColors.surfaceDark
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            // Universities List with Progressive Loading
            Expanded(
              child: _displayedUniversities.isEmpty && _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight,
                        ),
                      ),
                    )
                  : _displayedUniversities.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No universities available'
                                    : 'No universities found',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _displayedUniversities.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _displayedUniversities.length) {
                              // Loading indicator at the bottom
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final university = _displayedUniversities[index];
                            return _UniversityListItem(
                              university: university,
                              onTap: () => widget.onUniversitySelected(university),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UniversityListItem extends StatelessWidget {
  final UniversityModel university;
  final VoidCallback onTap;

  const _UniversityListItem({
    required this.university,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.borderDark
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // University Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryLight,
                        AppColors.secondaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // University Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        university.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (university.location != null && 
                          university.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              university.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

