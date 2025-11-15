import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  // Grades list is now user-editable, no static data
  final List<SubjectGrade> _grades = [];
  final ApiService _apiService = ApiService();
  bool _isSaving = false;
  bool _isLoading = true;
  String? _errorMessage;

  double get _average {
    if (_grades.isEmpty) return 0;
    final total = _grades.fold<double>(0, (sum, item) => sum + item.grade);
    return total / _grades.length;
  }

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gradesData = await _apiService.getStudentGrades();
      
      setState(() {
        _grades.clear();
        _grades.addAll(
          gradesData.map((grade) => SubjectGrade(
            subject: grade['subject']?.toString() ?? '',
            grade: (grade['grade'] is num) ? (grade['grade'] as num).toDouble() : 0.0,
          )).toList(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      // Show error message but don't block the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('grades.load_error'.tr() + ': ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveGrades() async {
    if (_grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('grades.no_grades'.tr()),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare grades for API
      final gradesList = _grades.map((grade) => {
        'subject': grade.subject,
        'grade': grade.grade,
      }).toList();

      // Save grades to API
      await _apiService.saveStudentGrades(gradesList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('grades.saved_successfully'.tr()),
            backgroundColor: AppColors.successLight,
            duration: const Duration(seconds: 2),
          ),
        );

        // Don't auto-navigate, let user decide
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('grades.save_error'.tr() + ': ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('grades.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_grades.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadGrades,
              tooltip: 'grades.refresh'.tr(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'grades.subtitle'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Average Card
            Container(
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
                borderRadius: BorderRadius.circular(20),
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
                children: [
                  Text(
                    'grades.total_average'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _average.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/ 100',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
            
            const SizedBox(height: 30),
            
            // Grades List
            Text(
              'grades.subjects'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _grades.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final grade = _grades[index];
                return _GradeCard(
                  subject: grade.subject,
                  grade: grade.grade,
                  onChanged: (value) {
                    setState(() {
                      _grades[index].grade = value;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _grades.removeAt(index);
                    });
                  },
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 400 + (index * 100)))
                    .slideX(begin: -0.2, end: 0);
              },
            ),
            
            const SizedBox(height: 20),
            
            // Add Subject Button
            OutlinedButton.icon(
              onPressed: () {
                _showAddSubjectDialog();
              },
              icon: const Icon(Icons.add),
              label: Text('grades.add_subject'.tr()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
            
            const SizedBox(height: 30),
            
            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveGrades,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('grades.save_grades'.tr()),
            ).animate().fadeIn(delay: 900.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    final subjectController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('grades.add_subject'.tr()),
        content: TextField(
          controller: subjectController,
          decoration: InputDecoration(
            labelText: 'grades.subject'.tr(),
            hintText: 'grades.enter_subject_name'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.isNotEmpty) {
                setState(() {
                  _grades.add(SubjectGrade(
                    subject: subjectController.text,
                    grade: 0,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
}

class SubjectGrade {
  final String subject;
  double grade;

  SubjectGrade({
    required this.subject,
    required this.grade,
  });
}

class _GradeCard extends StatelessWidget {
  final String subject;
  final double grade;
  final ValueChanged<double> onChanged;
  final VoidCallback? onDelete;

  const _GradeCard({
    required this.subject,
    required this.grade,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                subject,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: grade == 0 ? '' : grade.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'grades.grade_range'.tr(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  final numValue = double.tryParse(value) ?? 0;
                  if (numValue >= 0 && numValue <= 100) {
                    onChanged(numValue);
                  }
                },
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.errorLight,
                onPressed: onDelete,
                tooltip: 'grades.delete_subject'.tr(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

