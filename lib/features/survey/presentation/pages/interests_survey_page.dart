import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class InterestsSurveyPage extends StatefulWidget {
  const InterestsSurveyPage({super.key});

  @override
  State<InterestsSurveyPage> createState() => _InterestsSurveyPageState();
}

class _InterestsSurveyPageState extends State<InterestsSurveyPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _answers = {}; // Store answers: questionId -> answer
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load questions and saved answers in parallel
      final results = await Future.wait([
        _apiService.getSurveyQuestions(type: 'interests'),
        _apiService.getMySurveyAnswers(),
      ]);

      final questions = results[0] as List<Map<String, dynamic>>;
      final savedAnswers = results[1] as List<Map<String, dynamic>>;
      
      if (questions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لا توجد أسئلة متاحة من نوع الاهتمامات. يرجى التحقق من الاتصال أو الاتصال بالدعم الفني.';
        });
        return;
      }

      // Load saved answers for this survey type (interests)
      // First, get all question IDs for this survey type
      final questionIds = questions.map((q) => _getQuestionId(q)).toSet();
      
      final Map<int, String> loadedAnswers = {};
      for (var answerData in savedAnswers) {
        final questionId = answerData['QuestionID'] ?? answerData['questionId'] ?? 0;
        final answer = answerData['Answer'] ?? answerData['answer'] ?? '';
        final answerType = answerData['Type'] ?? answerData['type'] ?? '';
        
        // Only load answers if:
        // 1. Question ID matches a question in this survey
        // 2. Answer is not empty
        // 3. Type matches 'interests' (or is empty as fallback)
        if (questionId != 0 && 
            answer.isNotEmpty && 
            questionIds.contains(questionId) &&
            (answerType == 'interests' || answerType.isEmpty)) {
          loadedAnswers[questionId] = answer;
        }
      }

      setState(() {
        _questions = questions;
        _answers = loadedAnswers;
        _isLoading = false;
        // Load saved answer for current question if exists
        final currentQuestionId = _getQuestionId(_questions[_currentQuestionIndex]);
        _selectedAnswer = _answers[currentQuestionId];
      });
      
      print('Loaded ${loadedAnswers.length} saved answers for interests survey');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getQuestionId(Map<String, dynamic> question) {
    return question['id'] ?? question['QuestionID'] ?? question['questionId'] ?? 0;
  }

  String _getQuestionText(Map<String, dynamic> question) {
    return question['question'] ?? question['Question'] ?? question['Text'] ?? '';
  }

  void _saveAnswer(String answer) {
    if (_currentQuestionIndex >= _questions.length) return;
    
    final questionId = _getQuestionId(_questions[_currentQuestionIndex]);
    
    // Validate questionId
    if (questionId == 0) {
      print('Warning: Invalid questionId (0) for question at index $_currentQuestionIndex');
      print('Question data: ${_questions[_currentQuestionIndex]}');
      return;
    }
    
    setState(() {
      _answers[questionId] = answer;
      _selectedAnswer = answer;
    });
    
    print('Saved answer for question $questionId: $answer');
    print('Total answers saved: ${_answers.length}');
    
    // Save answer to API immediately for progress tracking
    _apiService.saveSurveyAnswer(questionId, answer).catchError((error) {
      print('Error saving answer to API: $error');
      // Don't show error to user for background saves, just log it
    });
  }

  void _goToNextQuestion() {
    // Save current answer before moving to next question
    if (_selectedAnswer != null && _currentQuestionIndex < _questions.length) {
      final questionId = _getQuestionId(_questions[_currentQuestionIndex]);
      if (!_answers.containsKey(questionId)) {
        _answers[questionId] = _selectedAnswer!;
        print('Auto-saved answer for question $questionId before navigation');
      }
    }
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        final questionId = _getQuestionId(_questions[_currentQuestionIndex]);
        _selectedAnswer = _answers[questionId];
      });
    } else {
      // All questions answered, navigate to next survey
      _completeSurvey();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        final questionId = _getQuestionId(_questions[_currentQuestionIndex]);
        _selectedAnswer = _answers[questionId];
      });
    }
  }

  Future<void> _completeSurvey() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Check if we have answers
      if (_answers.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'لا توجد إجابات لإرسالها. يرجى الإجابة على الأسئلة أولاً.';
        });
        return;
      }

      // Prepare answers for submission
      final answersList = _answers.entries.map((entry) => {
        'questionId': entry.key,
        'answer': entry.value,
      }).toList();

      print('Sending ${answersList.length} answers to API');
      print('Answers: $answersList');

      // Submit answers to API
      final result = await _apiService.submitSurveyAnswers(answersList);
      
      print('Submission result: $result');

      // Navigate to next survey (goals)
      if (mounted) {
        context.push('/survey/goals');
      }
    } catch (e, stackTrace) {
      print('Error submitting answers: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'فشل إرسال الإجابات: ${e.toString()}';
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الإجابات: ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('survey.interests_title'.tr()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('survey.interests_title'.tr()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('survey.interests_title'.tr()),
        ),
        body: const Center(
          child: Text('No questions available'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final questionText = _getQuestionText(currentQuestion);
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('survey.interests_title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentQuestionIndex + 1} / ${_questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
          LinearProgressIndicator(
                  value: progress,
            backgroundColor: Colors.grey[200],
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),

          // Question Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'survey.question'.tr() + ' ${_currentQuestionIndex + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  
                  const SizedBox(height: 24),

                  // Question Text
                              Text(
                    questionText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 32),

                  // Answer Options
                  _buildAnswerOptions().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: Text('survey.previous'.tr()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Next/Submit Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedAnswer != null && !_isSubmitting
                        ? _goToNextQuestion
                        : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _currentQuestionIndex == _questions.length - 1
                                ? Icons.check_circle
                                : Icons.arrow_forward_ios,
                            size: 16,
                          ),
                    label: Text(
                      _isSubmitting
                          ? 'survey.submitting'.tr()
                          : _currentQuestionIndex == _questions.length - 1
                              ? 'survey.finish'.tr()
                              : 'survey.next'.tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 1, end: 0),

          // Error Message
          if (_errorMessage != null && _questions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorLight, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.errorLight, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAnswerOptionsForQuestion(Map<String, dynamic> question) {
    final questionText = _getQuestionText(question).toLowerCase();
    final category = question['Category'] ?? question['category'] ?? '';
    
    // أسئلة تبدأ بـ "أي" أو "ما" - اختيار من متعدد
    if (questionText.contains('أي العبارات') || questionText.contains('أي مجال')) {
      // المجال الذي يثير الفضول
      return [
        {'value': 'التقنية والبرمجة', 'icon': Icons.computer_rounded, 'color': AppColors.primaryLight},
        {'value': 'العلوم الطبيعية', 'icon': Icons.science_rounded, 'color': AppColors.accentLight},
        {'value': 'الهندسة والتصميم', 'icon': Icons.engineering_rounded, 'color': AppColors.secondaryLight},
        {'value': 'الأعمال والاقتصاد', 'icon': Icons.business_rounded, 'color': AppColors.warningLight},
        {'value': 'الطب والرعاية الصحية', 'icon': Icons.medical_services_rounded, 'color': Colors.red},
        {'value': 'الآداب والعلوم الإنسانية', 'icon': Icons.menu_book_rounded, 'color': Colors.purple},
      ];
    } else if (questionText.contains('ما المادة') || questionText.contains('المجال الدراسي')) {
      // المواد الدراسية
      return [
        {'value': 'الرياضيات', 'icon': Icons.calculate_rounded, 'color': AppColors.primaryLight},
        {'value': 'العلوم', 'icon': Icons.science_rounded, 'color': AppColors.accentLight},
        {'value': 'اللغة والأدب', 'icon': Icons.menu_book_rounded, 'color': Colors.purple},
        {'value': 'التاريخ والجغرافيا', 'icon': Icons.public_rounded, 'color': Colors.green},
        {'value': 'الفنون والتصميم', 'icon': Icons.palette_rounded, 'color': Colors.pink},
        {'value': 'الموسيقى', 'icon': Icons.music_note_rounded, 'color': Colors.indigo},
      ];
    } else if (questionText.contains('أسلوب تفكير') || questionText.contains('تحدي')) {
      // أساليب حل المشاكل
      return [
        {'value': 'التحليل المنطقي', 'icon': Icons.analytics_rounded, 'color': AppColors.primaryLight},
        {'value': 'الإبداع والابتكار', 'icon': Icons.lightbulb_rounded, 'color': Colors.orange},
        {'value': 'التجربة والمحاولة', 'icon': Icons.science_rounded, 'color': AppColors.accentLight},
        {'value': 'الاستشارة والتعاون', 'icon': Icons.groups_rounded, 'color': Colors.green},
      ];
    } else if (questionText.contains('إلى أي مدى') || questionText.contains('ما مدى') || questionText.contains('مستوى اهتمامك') || questionText.contains('مدى أهمية')) {
      // أسئلة المقياس (إلى أي مدى)
      return [
        {'value': 'كثير جداً', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': AppColors.successLight},
        {'value': 'كثير', 'icon': Icons.sentiment_satisfied_rounded, 'color': Colors.green},
        {'value': 'متوسط', 'icon': Icons.sentiment_neutral_rounded, 'color': AppColors.warningLight},
        {'value': 'قليل', 'icon': Icons.sentiment_dissatisfied_rounded, 'color': Colors.orange},
        {'value': 'قليل جداً', 'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': AppColors.errorLight},
      ];
    } else if (questionText.contains('أي دور') || questionText.contains('دور تميل')) {
      // أدوار في الفريق
      return [
        {'value': 'منسق', 'icon': Icons.groups_rounded, 'color': AppColors.primaryLight},
        {'value': 'محلل', 'icon': Icons.analytics_rounded, 'color': AppColors.accentLight},
        {'value': 'مبتكر', 'icon': Icons.lightbulb_rounded, 'color': Colors.orange},
        {'value': 'منفذ', 'icon': Icons.build_rounded, 'color': AppColors.secondaryLight},
      ];
    } else if (questionText.contains('هل ترى') || questionText.contains('هل')) {
      // أسئلة نعم/لا
      return [
        {'value': 'نعم', 'icon': Icons.check_circle_outline, 'color': AppColors.successLight},
        {'value': 'لا', 'icon': Icons.cancel_outlined, 'color': AppColors.errorLight},
      ];
    } else if (questionText.contains('المهارة') || questionText.contains('المهارات')) {
      // المهارات
      return [
        {'value': 'المهارات التقنية', 'icon': Icons.computer_rounded, 'color': AppColors.primaryLight},
        {'value': 'المهارات الإدارية', 'icon': Icons.business_rounded, 'color': AppColors.warningLight},
        {'value': 'المهارات الإبداعية', 'icon': Icons.auto_awesome_rounded, 'color': Colors.purple},
        {'value': 'المهارات الاجتماعية', 'icon': Icons.people_rounded, 'color': Colors.green},
        {'value': 'المهارات التحليلية', 'icon': Icons.analytics_rounded, 'color': AppColors.accentLight},
      ];
    } else if (questionText.contains('بيئة عمل') || questionText.contains('أي بيئة')) {
      // بيئات العمل
      return [
        {'value': 'مكاتب', 'icon': Icons.business_center_rounded, 'color': AppColors.primaryLight},
        {'value': 'مختبرات', 'icon': Icons.science_rounded, 'color': AppColors.accentLight},
        {'value': 'ميدان', 'icon': Icons.public_rounded, 'color': Colors.green},
        {'value': 'عن بُعد', 'icon': Icons.home_work_rounded, 'color': Colors.purple},
        {'value': 'مزيج مرن', 'icon': Icons.swap_horiz_rounded, 'color': AppColors.warningLight},
      ];
    } else if (questionText.contains('الهدف المهني') || questionText.contains('تطمح')) {
      // الأهداف المهنية
      return [
        {'value': 'زيادة الدخل', 'icon': Icons.attach_money_rounded, 'color': AppColors.successLight},
        {'value': 'الرضا الوظيفي', 'icon': Icons.favorite_rounded, 'color': Colors.pink},
        {'value': 'التوازن بين العمل والحياة', 'icon': Icons.balance_rounded, 'color': Colors.purple},
        {'value': 'التأثير الاجتماعي', 'icon': Icons.volunteer_activism_rounded, 'color': Colors.blue},
        {'value': 'القيادة والإدارة', 'icon': Icons.groups_rounded, 'color': Colors.indigo},
        {'value': 'الابتكار والتميز', 'icon': Icons.lightbulb_rounded, 'color': Colors.orange},
      ];
    } else {
      // خيارات افتراضية
      return [
        {'value': 'نعم', 'icon': Icons.check_circle_outline, 'color': AppColors.successLight},
        {'value': 'لا', 'icon': Icons.cancel_outlined, 'color': AppColors.errorLight},
        {'value': 'محايد', 'icon': Icons.remove_circle_outline, 'color': AppColors.warningLight},
      ];
    }
  }

  Widget _buildAnswerOptions() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const SizedBox.shrink();
    }
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final options = _getAnswerOptionsForQuestion(currentQuestion);

    return Column(
      children: options.map((option) {
        final isSelected = _selectedAnswer == option['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
            onTap: () => _saveAnswer(option['value'] as String),
        borderRadius: BorderRadius.circular(16),
        child: Container(
              padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
                color: isSelected
                    ? (option['color'] as Color).withOpacity(0.1)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                  color: isSelected ? (option['color'] as Color) : Colors.transparent,
              width: 2,
            ),
          ),
              child: Row(
            children: [
              Container(
                    width: 48,
                    height: 48,
                decoration: BoxDecoration(
                      color: isSelected
                          ? (option['color'] as Color).withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                      option['icon'] as IconData,
                      color: isSelected ? (option['color'] as Color) : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option['value'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? (option['color'] as Color) : null,
                      ),
                ),
              ),
                  if (isSelected)
                Icon(
                      Icons.check_circle,
                      color: option['color'] as Color,
                      size: 24,
                    ),
            ],
          ),
        ),
      ),
        );
      }).toList(),
    );
  }
}
