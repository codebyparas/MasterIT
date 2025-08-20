import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_models.dart';
import '../services/cloud/firebase_cloud_storage.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCloudStorage _cloudStorage = FirebaseCloudStorage();
  
  // In-memory caching for repeated queries
  static final Map<String, List<DocumentSnapshot>> _topicsCache = {};
  static final Map<String, List<DocumentSnapshot>> _conceptsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  Future<List<QuizQuestion>> generateQuiz(String subjectNameOrId) async {
    try {
      // FIXED: Use robust subject lookup
      String actualSubjectId = await _getSubjectIdRobust(subjectNameOrId);
      print('✅ Found subject ID: $actualSubjectId');

      // Cached topics query
      final topics = await _getTopicsWithCache(actualSubjectId);
      if (topics.isEmpty) {
        throw Exception('No topics found for subject: $actualSubjectId');
      }

      // Keep your original random topic selection
      final randomTopic = topics[Random().nextInt(topics.length)];
      final topicId = randomTopic.id;
      print('🎯 Selected topic: $topicId');

      // Cached concepts query  
      final concepts = await _getConceptsWithCache(topicId);
      if (concepts.isEmpty) {
        throw Exception('No concepts found for topic: $topicId');
      }

      // Keep your original concept selection logic
      concepts.shuffle();
      final selectedConcepts = concepts.take(10).toList();
      print('💡 Selected ${selectedConcepts.length} concepts');

      // Enhanced parallel fetching with proper timeout
      final List<QuizQuestion> quizQuestions = [];
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        // Create futures with timeout for each concept
        final futures = selectedConcepts.map((concept) async {
          try {
            final cloudQuestion = await _cloudStorage
                .pickAndMarkNextQuestionForUserConcept(
                  uid: userId,
                  conceptId: concept.id,
                )
                .timeout(
                  const Duration(seconds: 8),
                  onTimeout: () {
                    print('⏱️ Timeout for concept ${concept.id}');
                    return null;
                  },
                );

            if (cloudQuestion != null) {
              return QuizQuestion.fromCloudQuestion(cloudQuestion);
            }
            return null;
          } catch (e) {
            print('Error getting question for concept ${concept.id}: $e');
            return null;
          }
        }).toList();

        // Wait for all with overall timeout
        final results = await Future.wait(futures).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⏱️ Overall timeout reached');
            return List.filled(futures.length, null);
          },
        );
        
        // Filter out null results
        for (final question in results) {
          if (question != null) {
            quizQuestions.add(question);
          }
        }
      }

      if (quizQuestions.length < 3) {
        throw Exception('Not enough questions found. Found: ${quizQuestions.length}');
      }

      print('🎉 Generated ${quizQuestions.length} questions successfully');
      return quizQuestions.take(10).toList();
    } catch (e) {
      print('❌ Error in generateQuiz: $e');
      throw Exception('Failed to generate quiz: $e');
    }
  }

  // FIXED: More robust subject lookup with proper error handling
  Future<String> _getSubjectIdRobust(String subjectNameOrId) async {
    try {
      print('🔍 Looking up subject: "$subjectNameOrId"');
      
      // Method 1: Try direct ID lookup first
      try {
        final directDoc = await _firestore
            .collection('subjects')
            .doc(subjectNameOrId)
            .get();
        
        if (directDoc.exists) {
          print('✅ Found subject by ID: $subjectNameOrId');
          return subjectNameOrId;
        } else {
          print('❌ No subject found with ID: $subjectNameOrId');
        }
      } catch (e) {
        print('⚠️ Error in direct ID lookup: $e');
      }

      // Method 2: Try name search if ID lookup failed
      try {
        final nameQuery = await _firestore
            .collection('subjects')
            .where('name', isEqualTo: subjectNameOrId)
            .limit(1)
            .get();
        
        if (nameQuery.docs.isNotEmpty) {
          final foundId = nameQuery.docs.first.id;
          print('✅ Found subject by name: $subjectNameOrId -> ID: $foundId');
          return foundId;
        } else {
          print('❌ No subject found with name: $subjectNameOrId');
        }
      } catch (e) {
        print('⚠️ Error in name lookup: $e');
      }

      // Method 3: Case-insensitive search as last resort
      try {
        print('🔍 Trying case-insensitive search...');
        final allSubjects = await _firestore.collection('subjects').get();
        
        for (final doc in allSubjects.docs) {
          final data = doc.data();
          final name = data['name']?.toString() ?? '';
          
          if (name.toLowerCase().trim() == subjectNameOrId.toLowerCase().trim()) {
            print('✅ Found subject by case-insensitive name: $name -> ID: ${doc.id}');
            return doc.id;
          }
        }
        
        // Debug: Show available subjects
        print('📋 Available subjects:');
        for (final doc in allSubjects.docs) {
          final data = doc.data();
          print('  - ID: ${doc.id}, Name: ${data['name']}');
        }
      } catch (e) {
        print('⚠️ Error in case-insensitive search: $e');
      }

      // If all methods fail
      throw Exception('Subject not found: "$subjectNameOrId"');
    } catch (e) {
      print('❌ Error in _getSubjectIdRobust: $e');
      rethrow;
    }
  }

  // FIXED: Safer topics caching with fallback
  Future<List<DocumentSnapshot>> _getTopicsWithCache(String subjectId) async {
    final cacheKey = 'topics_$subjectId';
    final now = DateTime.now();
    
    // Check cache validity
    if (_topicsCache.containsKey(cacheKey) && 
        _cacheTimestamps.containsKey(cacheKey) &&
        now.difference(_cacheTimestamps[cacheKey]!) < _cacheExpiry) {
      print('📋 Using cached topics for $subjectId');
      return _topicsCache[cacheKey]!;
    }

    // Fetch with fallback approach
    QuerySnapshot query;
    try {
      // Try cache first
      query = await _firestore
          .collection('topics')
          .where('subjectId', isEqualTo: subjectId)
          .get(const GetOptions(source: Source.cache));
      
      if (query.docs.isEmpty) {
        // Fallback to server if cache is empty
        query = await _firestore
            .collection('topics')
            .where('subjectId', isEqualTo: subjectId)
            .get();
      }
    } catch (e) {
      // If cache fails, get from server
      query = await _firestore
          .collection('topics')
          .where('subjectId', isEqualTo: subjectId)
          .get();
    }

    // Update cache
    _topicsCache[cacheKey] = query.docs;
    _cacheTimestamps[cacheKey] = now;
    
    print('💾 Cached ${query.docs.length} topics for $subjectId');
    return query.docs;
  }

  // FIXED: Safer concepts caching with fallback
  Future<List<DocumentSnapshot>> _getConceptsWithCache(String topicId) async {
    final cacheKey = 'concepts_$topicId';
    final now = DateTime.now();
    
    // Check cache validity
    if (_conceptsCache.containsKey(cacheKey) && 
        _cacheTimestamps.containsKey(cacheKey) &&
        now.difference(_cacheTimestamps[cacheKey]!) < _cacheExpiry) {
      print('💡 Using cached concepts for $topicId');
      return _conceptsCache[cacheKey]!;
    }

    // Fetch with fallback approach
    QuerySnapshot query;
    try {
      // Try cache first
      query = await _firestore
          .collection('concepts')
          .where('topicId', isEqualTo: topicId)
          .get(const GetOptions(source: Source.cache));
      
      if (query.docs.isEmpty) {
        // Fallback to server if cache is empty
        query = await _firestore
            .collection('concepts')
            .where('topicId', isEqualTo: topicId)
            .get();
      }
    } catch (e) {
      // If cache fails, get from server
      query = await _firestore
          .collection('concepts')
          .where('topicId', isEqualTo: topicId)
          .get();
    }

    // Update cache
    _conceptsCache[cacheKey] = query.docs;
    _cacheTimestamps[cacheKey] = now;
    
    print('💾 Cached ${query.docs.length} concepts for $topicId');
    return query.docs;
  }

  // Cache management methods
  static void clearCache() {
    _topicsCache.clear();
    _conceptsCache.clear();
    _cacheTimestamps.clear();
    print('🧹 Cleared QuizService cache');
  }

  static void warmUpCache(String subjectId) async {
    try {
      final service = QuizService();
      await service._getTopicsWithCache(subjectId);
      print('🔥 Warmed up cache for subject: $subjectId');
    } catch (e) {
      print('⚠️ Cache warm-up failed: $e');
    }
  }

  // Keep all your existing methods unchanged
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
