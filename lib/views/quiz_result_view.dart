import 'package:flutter/material.dart';
import 'package:learningdart/models/quiz_models.dart';
import 'package:learningdart/views/user_home_view.dart';

class QuizResultView extends StatelessWidget {
  final QuizState quizState;
  final String subjectName;
  final Map<String, dynamic> completionData;

  const QuizResultView({
    super.key,
    required this.quizState,
    required this.subjectName,
    required this.completionData,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuestions = quizState.questions.length;
    final correctAnswers = quizState.score;
    final accuracy = ((correctAnswers / totalQuestions) * 100).round();
    
    final xpEarned = completionData['xpEarned'] ?? 0;
    final newXp = completionData['newXp'] ?? 0;
    final newStreak = completionData['newStreak'] ?? 0;
    final streakIncreased = completionData['streakIncreased'] ?? false;
    
    String performanceText = _getPerformanceText(accuracy);
    Color performanceColor = _getPerformanceColor(accuracy);

    return Scaffold(
      backgroundColor: const Color(0xff1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1a2e),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          '$subjectName Quiz Results',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getPerformanceIcon(accuracy),
                    size: 80,
                    color: performanceColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    performanceText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: performanceColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        'Score',
                        '$correctAnswers/$totalQuestions',
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Accuracy',
                        '$accuracy%',
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Total XP',
                        '$newXp',
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // XP and Streak Rewards Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rewards Earned!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '+$xpEarned',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'XP Earned',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white30,
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$newStreak',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (streakIncreased) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            streakIncreased ? 'Day Streak!' : 'Day Streak',
                            style: TextStyle(
                              fontSize: 14,
                              color: streakIncreased ? Colors.white : Colors.white70,
                              fontWeight: streakIncreased ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (streakIncreased) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Great job! Keep the streak going! 🔥',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Question Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quizState.questions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final question = quizState.questions[index];
                      final userAnswer = quizState.userAnswers[index];
                      final isCorrect = _isAnswerCorrect(question, userAnswer);
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCorrect ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCorrect ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Question ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.questionText,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            if (userAnswer != null) ...[
                              Text(
                                'Your Answer: ${_formatAnswer(userAnswer)}',
                                style: TextStyle(
                                  color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!isCorrect)
                                Text(
                                  'Correct Answer: ${_formatAnswer(question.correctAnswer)}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const UserHomeView()),
                      (route) => route.isFirst, // Keep only the first route (AuthWrapper)
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getPerformanceText(int accuracy) {
    if (accuracy >= 90) return 'Excellent!';
    if (accuracy >= 80) return 'Great Job!';
    if (accuracy >= 70) return 'Good Work!';
    if (accuracy >= 60) return 'Keep Trying!';
    return 'Practice More!';
  }

  Color _getPerformanceColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon(int accuracy) {
    if (accuracy >= 90) return Icons.emoji_events;
    if (accuracy >= 80) return Icons.thumb_up;
    if (accuracy >= 60) return Icons.trending_up;
    return Icons.refresh;
  }

  bool _isAnswerCorrect(QuizQuestion question, dynamic userAnswer) {
    if (userAnswer == null) return false;
    
    switch (question.type) {
      case 'mcq':
        return question.correctAnswer == userAnswer;
      case 'fillup':
        final correctAnswers = List<String>.from(question.correctAnswer);
        return correctAnswers.any((correct) => 
            correct.toLowerCase() == userAnswer.toString().toLowerCase());
      case 'ordering':
        final correctOrder = List<String>.from(question.correctAnswer);
        final userOrder = List<String>.from(userAnswer);
        return correctOrder.toString() == userOrder.toString();
      case 'drag_drop':
        final correctAnswer = question.correctAnswer as Map<String, dynamic>;
        return correctAnswer['correctTarget'] == userAnswer;
      case 'tap_image':
        if (userAnswer is Map && userAnswer.containsKey('correct')) {
          return userAnswer['correct'] == true;
        }
        return false;
      default:
        return false;
    }
  }

  String _formatAnswer(dynamic answer) {
    if (answer is List) {
      return answer.join(' → ');
    }
    if (answer is Map) {
      return answer.toString();
    }
    return answer.toString();
  }
}
