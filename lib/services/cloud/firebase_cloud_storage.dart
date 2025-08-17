import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_user.dart';
import 'cloud_storage_constants.dart';
import 'cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final _db = FirebaseFirestore.instance;

  final users = FirebaseFirestore.instance.collection('users');
  final subjects = FirebaseFirestore.instance.collection('subjects');
  final topics = FirebaseFirestore.instance.collection('topics');
  final questions = FirebaseFirestore.instance.collection('questions');

  // ------------------------ USERS ------------------------

  Future<CloudUser> getUser(String uid) async {
    try {
      final doc = await users.doc(uid).get();
      return CloudUser.fromSnapshot(doc);
    } catch (e) {
      throw CouldNotGetUserException();
    }
  }

  Future<void> createUser({required String uid, required String email}) async {
    try {
      await users.doc(uid).set({
        userNameFieldName: '',
        userEmailFieldName: email,
        userInitialSetupDoneFieldName: false,
        userStreakFieldName: 0,
        userStrengthFieldName: {},
        userQuizzesTakenFieldName: 0,
        userLastActiveFieldName: Timestamp.now(),
        userTopicsIntroducedFieldName: [],
      });
    } catch (e) {
      throw CouldNotCreateUserException();
    }
  }

  Future<void> completeInitialSetup({
    required String uid,
    required String name,
    required List<String> topicsIntroduced,
  }) async {
    try {
      await users.doc(uid).update({
        userNameFieldName: name,
        userInitialSetupDoneFieldName: true,
        userTopicsIntroducedFieldName: topicsIntroduced,
        userLastActiveFieldName: Timestamp.now(),
      });
    } catch (e) {
      throw CouldNotUpdateUserException();
    }
  }

  Future<void> updateUserAfterQuiz({
    required String uid,
    required int newStreak,
    required int newQuizzesTaken,
    required Map<String, dynamic> newStrength,
  }) async {
    try {
      await users.doc(uid).update({
        userStreakFieldName: newStreak,
        userQuizzesTakenFieldName: newQuizzesTaken,
        userStrengthFieldName: newStrength,
        userLastActiveFieldName: Timestamp.now(),
      });
    } catch (e) {
      throw CouldNotUpdateUserException();
    }
  }

  // ------------------------ SUBJECTS ------------------------

  Future<void> addSubject(String name) async {
    await subjects.add({'name': name});
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final snapshot = await subjects.get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name']})
        .toList();
  }

  // ------------------------ TOPICS ------------------------

  Future<String> addTopic({
    required String name,
    required String subjectId,
    bool isUnlockedByDefault = false,
    int difficulty = 1,
    List<String> prerequisites = const [],
  }) async {
    final doc = await _db.collection('topics').add({
      'name': name,
      'subjectId': subjectId,
      'isUnlockedByDefault': isUnlockedByDefault,
      'difficulty': difficulty,
      'prerequisites': prerequisites,
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getTopics(String subjectId) async {
    final snapshot = await _db
        .collection('topics')
        .where('subjectId', isEqualTo: subjectId)
        .get();
    return snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'],
        }).toList();
  }

  Future<void> addTopicReferenceToSubject(String subjectId, String topicId) async {
    final doc = subjects.doc(subjectId);

    await _db.runTransaction((txn) async {
      final snapshot = await txn.get(doc);
      final existingTopics = List<String>.from(snapshot.data()?['topics'] ?? []);
      if (!existingTopics.contains(topicId)) {
        existingTopics.add(topicId);
        txn.update(doc, {'topics': existingTopics});
      }
    });
  }

  // ------------------------ QUESTIONS ------------------------
  // Helper to apply common fields and add to Firestore
  Future<void> _addQuestion(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await questions.add(data);
  }

  /// MCQ: options + correctAnswer (e.g., 'A' | 'B' | 'C' | 'D')
  Future<void> addMCQQuestion({
    required String subjectId,
    required String topicId,
    required String questionText,
    String? hintText,
    required List<String> options,
    required String correctAnswer,
  }) async {
    await _addQuestion({
      'type': 'mcq',
      'subjectId': subjectId,
      'topicId': topicId,
      'questionText': questionText,
      'hint': hintText ?? '',
      'options': options,
      'correctAnswer': correctAnswer, // stored as letter or value
    });
  }

  /// Fill-up: one or more acceptable answers (case-normalize in app if needed)
  Future<void> addFillupQuestion({
    required String subjectId,
    required String topicId,
    required String questionText,
    String? hintText,
    required List<String> correctAnswers,
  }) async {
    await _addQuestion({
      'type': 'fillup',
      'subjectId': subjectId,
      'topicId': topicId,
      'questionText': questionText,
      'hint': hintText ?? '',
      // CloudQuestion.correctAnswer is dynamic, so a List<String> is fine
      'correctAnswer': correctAnswers,
    });
  }

  /// Ordering: store phrases + the correct order (same as phrases initially)
  Future<void> addOrderingQuestion({
    required String subjectId,
    required String topicId,
    required String questionText,
    String? hintText,
    required List<String> phrases,
  }) async {
    await _addQuestion({
      'type': 'ordering',
      'subjectId': subjectId,
      'topicId': topicId,
      'questionText': questionText,
      'hint': hintText ?? '',
      'phrases': phrases,
      'correctAnswer': phrases, // use dynamic field for the target order
    });
  }

  /// Match Pairs: list of {left, right}
  Future<void> addMatchPairsQuestion({
    required String subjectId,
    required String topicId,
    required String questionText,
    String? hintText,
    required List<Map<String, String>> pairs,
  }) async {
    await _addQuestion({
      'type': 'match_pairs',
      'subjectId': subjectId,
      'topicId': topicId,
      'questionText': questionText,
      'hint': hintText ?? '',
      // Match CloudQuestion field name:
      'matchPairs': pairs,
    });
  }

  /// Drag & Drop: mapping from draggable -> target
  /// We also store the list of draggables and boxes for quick rendering.
  Future<void> addDragDropQuestion({
    required String subjectId,
    required String topicId,
    required String questionText,
    String? hintText,
    required Map<String, String> mapping,
  }) async {
    final draggables = mapping.keys.toList();
    final boxes = mapping.values.toSet().toList(); // unique targets

    await _addQuestion({
      'type': 'drag_drop',
      'subjectId': subjectId,
      'topicId': topicId,
      'questionText': questionText,
      'hint': hintText ?? '',
      'draggables': draggables,
      'boxes': boxes,
      // Put the ground truth mapping in the dynamic slot:
      'correctAnswer': mapping,
    });
  }

  /// Tap on Image: single correct point (x,y); extend to multiple later
  Future<void> addTapImageQuestion({
    required String subjectId,
    required String topicId,
    required String questionText,
    String? hintText,
    String? imageUrl,
    required int x,
    required int y,
  }) async {
    await _addQuestion({
      'type': 'tap_image',
      'subjectId': subjectId,
      'topicId': topicId,
      'questionText': questionText,
      'hint': hintText ?? '',
      if (imageUrl != null) 'imageUrl': imageUrl,
      // Match CloudQuestion field name:
      'correctTapPosition': {'x': x, 'y': y},
    });
  }

  // ------------------------ Singleton ------------------------
  static final FirebaseCloudStorage _shared = FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
