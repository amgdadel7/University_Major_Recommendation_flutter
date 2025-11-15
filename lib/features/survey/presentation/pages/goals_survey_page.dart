import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class GoalsSurveyPage extends StatefulWidget {
  const GoalsSurveyPage({super.key});

  @override
  State<GoalsSurveyPage> createState() => _GoalsSurveyPageState();
}

class _GoalsSurveyPageState extends State<GoalsSurveyPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _answers = {};
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
        _apiService.getSurveyQuestions(type: 'goals'),
        _apiService.getMySurveyAnswers(),
      ]);

      final questions = results[0] as List<Map<String, dynamic>>;
      final savedAnswers = results[1] as List<Map<String, dynamic>>;
      
      if (questions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لا توجد أسئلة متاحة من نوع الأهداف. يرجى التحقق من الاتصال أو الاتصال بالدعم الفني.';
        });
        return;
      }

      // Load saved answers for this survey type (goals)
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
        // 3. Type matches 'goals' (or is empty as fallback)
        if (questionId != 0 && 
            answer.isNotEmpty && 
            questionIds.contains(questionId) &&
            (answerType == 'goals' || answerType.isEmpty)) {
          loadedAnswers[questionId] = answer;
        }
      }

      setState(() {
        _questions = questions;
        _answers = loadedAnswers;
        _isLoading = false;
        final currentQuestionId = _getQuestionId(_questions[_currentQuestionIndex]);
        _selectedAnswer = _answers[currentQuestionId];
      });
      
      print('Loaded ${loadedAnswers.length} saved answers for goals survey');
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

      if (mounted) {
        context.push('/survey/learning-style');
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
          title: Text('survey.goals_title'.tr()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('survey.goals_title'.tr()),
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
          title: Text('survey.goals_title'.tr()),
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
        title: Text('survey.goals_title'.tr()),
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
    
    // أسئلة المقياس (إلى أي مدى، ما مدى)
    if (questionText.contains('إلى أي مدى') || questionText.contains('ما مدى')) {
      return [
        {'value': 'كثير جداً', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': AppColors.successLight},
        {'value': 'كثير', 'icon': Icons.sentiment_satisfied_rounded, 'color': Colors.green},
        {'value': 'متوسط', 'icon': Icons.sentiment_neutral_rounded, 'color': AppColors.warningLight},
        {'value': 'قليل', 'icon': Icons.sentiment_dissatisfied_rounded, 'color': Colors.orange},
        {'value': 'قليل جداً', 'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': AppColors.errorLight},
      ];
    }
    
    // سؤال: ما هو هدفك الرئيسي من الدراسة الجامعية؟
    if (questionText.contains('هدفك الرئيسي') && questionText.contains('الدراسة الجامعية')) {
      return [
        {'value': 'الحصول على شهادة جامعية', 'icon': Icons.school_rounded, 'color': Colors.blue},
        {'value': 'تطوير المهارات والمعرفة', 'icon': Icons.lightbulb_rounded, 'color': Colors.orange},
        {'value': 'تحسين فرص العمل', 'icon': Icons.work_rounded, 'color': AppColors.successLight},
        {'value': 'تحقيق الشغف والاهتمام', 'icon': Icons.favorite_rounded, 'color': Colors.pink},
        {'value': 'الاستعداد للمستقبل المهني', 'icon': Icons.trending_up_rounded, 'color': Colors.purple},
        {'value': 'التطور الشخصي والفكري', 'icon': Icons.person_outline_rounded, 'color': Colors.indigo},
      ];
    }
    
    // سؤال: ما الذي تطمح لتحقيقه في حياتك المهنية بعد التخرج؟
    if (questionText.contains('تطمح') && (questionText.contains('المهنية') || questionText.contains('بعد التخرج'))) {
      return [
        {'value': 'الوصول إلى منصب قيادي', 'icon': Icons.groups_rounded, 'color': Colors.indigo},
        {'value': 'إطلاق مشروع خاص', 'icon': Icons.business_rounded, 'color': Colors.green},
        {'value': 'التميز في مجال التخصص', 'icon': Icons.star_rounded, 'color': Colors.amber},
        {'value': 'المساهمة في البحث والتطوير', 'icon': Icons.science_rounded, 'color': Colors.blue},
        {'value': 'خدمة المجتمع والتأثير الإيجابي', 'icon': Icons.volunteer_activism_rounded, 'color': Colors.teal},
        {'value': 'تحقيق التوازن بين العمل والحياة', 'icon': Icons.balance_rounded, 'color': Colors.purple},
      ];
    }
    
    // سؤال: ما هي أولوياتك في اختيار التخصص الجامعي؟
    if (questionText.contains('أولوياتك') && questionText.contains('التخصص')) {
      return [
        {'value': 'الاهتمام والشغف', 'icon': Icons.favorite_rounded, 'color': Colors.pink},
        {'value': 'فرص العمل المتاحة', 'icon': Icons.work_rounded, 'color': AppColors.successLight},
        {'value': 'المستوى الأكاديمي المطلوب', 'icon': Icons.school_rounded, 'color': Colors.blue},
        {'value': 'الراتب المتوقع', 'icon': Icons.attach_money_rounded, 'color': Colors.green},
        {'value': 'التوافق مع المهارات', 'icon': Icons.psychology_rounded, 'color': Colors.orange},
        {'value': 'التأثير الاجتماعي', 'icon': Icons.people_rounded, 'color': Colors.teal},
      ];
    }
    
    // سؤال: ما الذي تريد أن تكون عليه بعد 10 سنوات من الآن؟
    if (questionText.contains('10 سنوات') || (questionText.contains('تريد أن تكون') && questionText.contains('بعد'))) {
      return [
        {'value': 'خبير في مجال التخصص', 'icon': Icons.star_rounded, 'color': Colors.blue},
        {'value': 'رائد أعمال ناجح', 'icon': Icons.business_center_rounded, 'color': Colors.green},
        {'value': 'باحث أو أكاديمي', 'icon': Icons.science_rounded, 'color': Colors.purple},
        {'value': 'قائد في المؤسسة', 'icon': Icons.groups_rounded, 'color': Colors.indigo},
        {'value': 'مستشار أو خبير', 'icon': Icons.support_agent_rounded, 'color': Colors.orange},
        {'value': 'مؤثر اجتماعي', 'icon': Icons.volunteer_activism_rounded, 'color': Colors.teal},
      ];
    }
    
    // سؤال: ما هي التحديات التي تتوقع مواجهتها في مسيرتك الأكاديمية؟
    if (questionText.contains('التحديات') && questionText.contains('المسيرة الأكاديمية')) {
      return [
        {'value': 'صعوبة المواد الدراسية', 'icon': Icons.book_rounded, 'color': Colors.red},
        {'value': 'إدارة الوقت', 'icon': Icons.access_time_rounded, 'color': Colors.orange},
        {'value': 'الضغط النفسي', 'icon': Icons.psychology_rounded, 'color': Colors.purple},
        {'value': 'التوازن بين الدراسة والحياة', 'icon': Icons.balance_rounded, 'color': Colors.blue},
        {'value': 'الموارد المالية', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.green},
        {'value': 'عدم وضوح المسار', 'icon': Icons.help_outline_rounded, 'color': Colors.grey},
      ];
    }
    
    // سؤال: ما الذي يدفعك للتفوق في دراستك؟
    if (questionText.contains('يدفعك') && questionText.contains('التفوق')) {
      return [
        {'value': 'الشغف بالتعلم', 'icon': Icons.favorite_rounded, 'color': Colors.pink},
        {'value': 'الطموح والرغبة في التميز', 'icon': Icons.trending_up_rounded, 'color': Colors.blue},
        {'value': 'الضغط الأسري', 'icon': Icons.family_restroom, 'color': Colors.purple},
        {'value': 'المنافسة مع الأقران', 'icon': Icons.emoji_events_rounded, 'color': Colors.amber},
        {'value': 'الرغبة في تحقيق الأهداف', 'icon': Icons.flag_rounded, 'color': Colors.green},
        {'value': 'الخوف من الفشل', 'icon': Icons.warning_rounded, 'color': Colors.orange},
      ];
    }
    
    // سؤال: ما هي المهارات التي تريد تطويرها خلال دراستك الجامعية؟
    if (questionText.contains('المهارات') && questionText.contains('تطويرها')) {
      return [
        {'value': 'المهارات التقنية', 'icon': Icons.computer_rounded, 'color': Colors.blue},
        {'value': 'مهارات التواصل', 'icon': Icons.chat_rounded, 'color': Colors.green},
        {'value': 'مهارات القيادة', 'icon': Icons.groups_rounded, 'color': Colors.indigo},
        {'value': 'مهارات البحث', 'icon': Icons.search_rounded, 'color': Colors.purple},
        {'value': 'مهارات التفكير النقدي', 'icon': Icons.lightbulb_rounded, 'color': Colors.orange},
        {'value': 'مهارات ريادة الأعمال', 'icon': Icons.business_rounded, 'color': Colors.teal},
      ];
    }
    
    // أسئلة نعم/لا
    if (questionText.contains('هل')) {
      return [
        {'value': 'نعم', 'icon': Icons.check_circle_outline, 'color': AppColors.successLight},
        {'value': 'لا', 'icon': Icons.cancel_outlined, 'color': AppColors.errorLight},
      ];
    }
    
    // خيارات افتراضية للأسئلة العامة
    return [
      {'value': 'تحقيق الأهداف الأكاديمية', 'icon': Icons.school_rounded, 'color': Colors.blue},
      {'value': 'تطوير المهارات', 'icon': Icons.lightbulb_rounded, 'color': Colors.orange},
      {'value': 'تحسين فرص العمل', 'icon': Icons.work_rounded, 'color': AppColors.successLight},
      {'value': 'تحقيق الشغف', 'icon': Icons.favorite_rounded, 'color': Colors.pink},
      {'value': 'التأثير الإيجابي', 'icon': Icons.volunteer_activism_rounded, 'color': Colors.teal},
    ];
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