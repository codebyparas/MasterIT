import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learningdart/models/quiz_models.dart';
import 'package:learningdart/services/quiz_service.dart';
import 'package:learningdart/widgets/question_widget.dart';
import 'package:learningdart/views/quiz_result_view.dart';

class QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String subjectName;

  const QuizView({
    super.key,
    required this.questions,
    required this.subjectName,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  final QuizService _quizService = QuizService();
  late QuizState _quizState;
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isProcessing = false; // Added to prevent multiple submissions

  @override
  void initState() {
    super.initState();
    _quizState = QuizState(
      questions: widget.questions,
      userAnswers: {},
    );
  }

  Future<void> _submitAnswer(dynamic answer) async {
    if (_isAnswered || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isAnswered = true;
    });

    final currentQuestion = _quizState.questions[_quizState.currentIndex];
    final isCorrect = _validateAnswer(currentQuestion, answer);

    setState(() {
      _isCorrect = isCorrect;
    });

    // Update user answers
    final updatedAnswers = Map<int, dynamic>.from(_quizState.userAnswers);
    updatedAnswers[_quizState.currentIndex] = answer;

    // Calculate XP
    final xpGained = isCorrect ? 10 : 0; // Changed: no negative XP

    // Update user progress
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _quizService.updateUserProgress(
          userId: userId,
          xpGained: xpGained,
          topicId: currentQuestion.topicId,
          isCorrect: isCorrect,
        );
      }
    } catch (e) {
      debugPrint('Failed to update progress: $e');
    }

    // Update quiz state
    setState(() {
      _quizState = _quizState.copyWith(
        userAnswers: updatedAnswers,
        score: _quizState.score + (isCorrect ? 1 : 0),
        xp: _quizState.xp + xpGained,
      );
      _isProcessing = false;
    });

    // Show feedback briefly before allowing next question
    await Future.delayed(const Duration(seconds: 1));
  }

  bool _validateAnswer(QuizQuestion question, dynamic answer) {
    try {
      switch (question.type) {
        case 'mcq':
          return question.correctAnswer == answer;
          
        case 'fillup':
          if (question.correctAnswer is List) {
            final correctAnswers = List<String>.from(question.correctAnswer);
            return correctAnswers.any((correct) => 
                correct.toLowerCase().trim() == answer.toString().toLowerCase().trim());
          } else {
            return question.correctAnswer.toString().toLowerCase().trim() == 
                   answer.toString().toLowerCase().trim();
          }
          
        case 'ordering':
          if (answer is List && question.correctAnswer is List) {
            final correctOrder = List<String>.from(question.correctAnswer);
            final userOrder = List<String>.from(answer);
            if (correctOrder.length != userOrder.length) return false;
            for (int i = 0; i < correctOrder.length; i++) {
              if (correctOrder[i] != userOrder[i]) return false;
            }
            return true;
          }
          return false;
          
        case 'drag_drop':
          if (question.correctAnswer is Map) {
            final correctAnswer = question.correctAnswer as Map<String, dynamic>;
            return correctAnswer['correctTarget'] == answer;
          }
          return false;
          
        case 'tap_image':
          // FIXED: Updated validation for tap image with double coordinates
          if (answer is Map && answer.containsKey('correct')) {
            return answer['correct'] == true;
          }
          // Fallback to coordinate validation with proper type conversion
          if (answer is Map && answer.containsKey('x') && answer.containsKey('y')) {
            return _isPointInRectangle(
              {'x': (answer['x'] as num).toDouble(), 'y': (answer['y'] as num).toDouble()},
              question.correctCoordinates ?? {},
            );
          }
          return false;
          
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error validating answer: $e');
      return false;
    }
  }

  bool _isPointInRectangle(Map<String, double> point, Map<String, double> rect) {
      if (rect.isEmpty) return false;
      
      final x = point['x']!;
      final y = point['y']!;
      final rectX = rect['x']!;
      final rectY = rect['y']!;
      final rectW = rect['w']!;
      final rectH = rect['h']!;
  
      return x >= rectX && 
             x <= rectX + rectW && 
             y >= rectY && 
             y <= rectY + rectH;
    }

  Future<void> _nextQuestion() async {
    if (_isProcessing) return;

    if (_quizState.currentIndex < _quizState.questions.length - 1) {
      setState(() {
        _quizState = _quizState.copyWith(
          currentIndex: _quizState.currentIndex + 1,
        );
        // CRITICAL: Reset all answer states for new question
        _isAnswered = false;
        _isCorrect = false;
        _isProcessing = false;
      });
    } else {
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final result = await _quizService.completeQuiz(
          userId: userId,
          totalQuestions: _quizState.questions.length,
          correctAnswers: _quizState.score,
          xpEarned: _quizState.xp,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => QuizResultView(
                quizState: _quizState,
                subjectName: widget.subjectName,
                completionData: result,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to complete quiz: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _cancelQuiz() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Quiz?'),
          content: const Text('Are you sure you want to cancel this quiz? Your progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue Quiz'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Cancel Quiz',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _quizState.questions[_quizState.currentIndex];
    final progress = (_quizState.currentIndex + 1) / _quizState.questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _isProcessing ? null : _cancelQuiz,
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: Column(
          children: [
            Text(
              '${_quizState.currentIndex + 1} of ${_quizState.questions.length}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'XP: ${_quizState.xp}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: QuestionWidget(
              // CRITICAL: Key forces complete widget rebuild on question change
              key: ValueKey('question_${currentQuestion.id}_${_quizState.currentIndex}'),
              question: currentQuestion,
              onAnswer: _submitAnswer,
              isAnswered: _isAnswered,
              isCorrect: _isCorrect,
              showCorrectAnswer: _isAnswered && !_isCorrect,
            ),
          ),
          if (_isAnswered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Feedback message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isCorrect 
                                ? 'Correct! You earned ${_isCorrect ? 10 : 0} XP' 
                                : 'Incorrect. Better luck next time!',
                            style: TextStyle(
                              color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Next/Results button
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Processing...'),
                            ],
                          )
                        : Text(
                            _quizState.currentIndex < _quizState.questions.length - 1
                                ? 'Next Question'
                                : 'View Results',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
