import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_models.dart';
import '../services/cloud/firebase_cloud_storage.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCloudStorage _cloudStorage = FirebaseCloudStorage();

  Future<List<QuizQuestion>> generateQuiz(String subjectNameOrId) async {
    try {
      String actualSubjectId;
      
      // Find subject by name or ID
      final subjectQuery = await _firestore
          .collection('subjects')
          .where('name', isEqualTo: subjectNameOrId)
          .limit(1)
          .get();
      
      if (subjectQuery.docs.isNotEmpty) {
        actualSubjectId = subjectQuery.docs.first.id;
      } else {
        final subjectDoc = await _firestore
            .collection('subjects')
            .doc(subjectNameOrId)
            .get();
        
        if (subjectDoc.exists) {
          actualSubjectId = subjectNameOrId;
        } else {
          throw Exception('Subject not found: $subjectNameOrId');
        }
      }

      // Get random topic from subject
      final topicsQuery = await _firestore
          .collection('topics')
          .where('subjectId', isEqualTo: actualSubjectId)
          .get();

      if (topicsQuery.docs.isEmpty) {
        throw Exception('No topics found for subject: $actualSubjectId');
      }

      final randomTopic = topicsQuery.docs[Random().nextInt(topicsQuery.docs.length)];
      final topicId = randomTopic.id;

      // Get concepts from this topic
      final conceptsQuery = await _firestore
          .collection('concepts')
          .where('topicId', isEqualTo: topicId)
          .get();

      if (conceptsQuery.docs.isEmpty) {
        throw Exception('No concepts found for topic: $topicId');
      }

      // Select up to 10 random concepts
      final concepts = conceptsQuery.docs;
      concepts.shuffle();
      final selectedConcepts = concepts.take(10).toList();

      // Get questions using the FirebaseCloudStorage method
      final List<QuizQuestion> quizQuestions = [];
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        for (final concept in selectedConcepts) {
          try {
            final cloudQuestion = await _cloudStorage.pickAndMarkNextQuestionForUserConcept(
              uid: userId,
              conceptId: concept.id,
            );

            if (cloudQuestion != null) {
              quizQuestions.add(
                QuizQuestion.fromCloudQuestion(cloudQuestion),
              );
            }
          } catch (e) {
            print('Error getting question for concept ${concept.id}: $e');
            // Continue with other concepts
          }
        }
      }

      if (quizQuestions.length < 3) {
        throw Exception('Not enough questions found. Found: ${quizQuestions.length}');
      }

      return quizQuestions.take(10).toList();
    } catch (e) {
      print('Error in generateQuiz: $e');
      throw Exception('Failed to generate quiz: $e');
    }
  }

  Future<Map<String, dynamic>> completeQuiz({
    required String userId,
    required int totalQuestions,
    required int correctAnswers,
    required int xpEarned,
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      
      Map<String, dynamic> result = {};
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);
        
        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        final data = userDoc.data()!;
        final Timestamp? lastQuizTimestamp = data['lastQuizDate'];
        DateTime? lastQuizDate;
        if (lastQuizTimestamp != null) {
          lastQuizDate = lastQuizTimestamp.toDate();
        }

        final DateTime now = DateTime.now();
        bool isFirstQuizToday = true;
        if (lastQuizDate != null) {
          isFirstQuizToday = !(lastQuizDate.year == now.year &&
              lastQuizDate.month == now.month &&
              lastQuizDate.day == now.day);
        }

        int currentXp = data['xp'] ?? 0;
        int currentQuizzes = data['quizzesTaken'] ?? 0;
        int currentStreak = data['streak'] ?? 0;

        int newXp = currentXp + xpEarned;
        int newQuizzes = currentQuizzes + 1;
        int newStreak = isFirstQuizToday ? currentStreak + 1 : currentStreak;
        
        // Store result for UI display
        result = {
          'xpEarned': xpEarned,
          'newXp': newXp,
          'newStreak': newStreak,
          'streakIncreased': isFirstQuizToday,
          'newQuizzesTaken': newQuizzes,
        };

        transaction.update(userDocRef, {
          'xp': newXp,
          'quizzesTaken': newQuizzes,
          'streak': newStreak,
          'lastQuizDate': Timestamp.now(),
        });
      });
      
      return result;
    } catch (e) {
      throw Exception('Failed to complete quiz: $e');
    }
  }

  Future<void> updateUserProgress({
    required String userId,
    required int xpGained,
    required String topicId,
    required bool isCorrect,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          final currentXp = userDoc.data()?['xp'] as int? ?? 0;
          
          transaction.update(userRef, {
            'xp': currentXp + xpGained,
          });

          // Update topic strength
          final topicProgressRef = _firestore
              .collection('user_progress')
              .doc('${userId}_$topicId');
          
          final topicProgressDoc = await transaction.get(topicProgressRef);
          final bool docExists = topicProgressDoc.exists;
          final int currentStrength = docExists
              ? (topicProgressDoc.data()?['strength'] as int? ?? 0)
              : 0;
          
          transaction.set(topicProgressRef, {
            'userId': userId,
            'topicId': topicId,
            'strength': currentStrength + (isCorrect ? 5 : -2),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      throw Exception('Failed to update user progress: $e');
    }
  }
}
