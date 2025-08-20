import 'package:flutter/material.dart';
// import 'package:learningdart/models/quiz_models.dart';
import 'package:learningdart/services/quiz_service.dart';
import 'package:learningdart/views/quiz_view.dart';

class QuizLoadingView extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const QuizLoadingView({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<QuizLoadingView> createState() => _QuizLoadingViewState();
}

class _QuizLoadingViewState extends State<QuizLoadingView>
    with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<String> _loadingMessages = [
    "Selecting random topics...",
    "Finding concepts to test...",
    "Picking challenging questions...",
    "Shuffling question formats...",
    "Almost ready...",
    "Let's begin!",
  ];

  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.repeat(reverse: true);
    _startLoadingMessages();
    _generateQuiz();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startLoadingMessages() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _messageIndex < _loadingMessages.length - 1) {
        setState(() {
          _messageIndex++;
        });
        _startLoadingMessages();
      }
    });
  }

  Future<void> _generateQuiz() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      final questions = await _quizService.generateQuiz(widget.subjectId);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizView(
              questions: questions,
              subjectName: widget.subjectName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.subjectName} Quiz',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.quiz,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _loadingMessages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
