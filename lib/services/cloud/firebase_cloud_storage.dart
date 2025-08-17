// firebase_cloud_storage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_user.dart';
import 'cloud_storage_constants.dart';
import 'cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final _db = FirebaseFirestore.instance;

  final users = FirebaseFirestore.instance.collection('users');
  final subjects = FirebaseFirestore.instance.collection('subjects');
  final topics = FirebaseFirestore.instance.collection('topics');
  final concepts = FirebaseFirestore.instance.collection('concepts');
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
        userSubjectsIntroducedFieldName: [],
        userTopicsInProgressFieldName: {},
      });
    } catch (e) {
      throw CouldNotCreateUserException();
    }
  }

  Future<void> completeInitialSetup({
    required String uid,
    required String name,
    required List<String> subjectsIntroduced,
  }) async {
    try {
      await users.doc(uid).update({
        userNameFieldName: name,
        userInitialSetupDoneFieldName: true,
        userSubjectsIntroducedFieldName: subjectsIntroduced,
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
    required Map<String, String> newTopicsInProgress, // {topicId: status}
  }) async {
    try {
      await users.doc(uid).update({
        userStreakFieldName: newStreak,
        userQuizzesTakenFieldName: newQuizzesTaken,
        userStrengthFieldName: newStrength,
        userTopicsInProgressFieldName: newTopicsInProgress,
        userLastActiveFieldName: Timestamp.now(),
      });
    } catch (e) {
      throw CouldNotUpdateUserException();
    }
  }

  // ------------------------ SUBJECTS ------------------------

  Future<void> addSubject(String name, {String description = ''}) async {
    try {
      await subjects.add({
        subjectNameFieldName: name,
        subjectDescriptionFieldName: description,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final snapshot = await subjects.get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()[subjectNameFieldName],
              'description': doc.data()[subjectDescriptionFieldName] ?? '',
            })
        .toList();
  }

  // ------------------------ TOPICS ------------------------

  Future<String> addTopic({
    required String name,
    required String subjectId,
    List<String> prerequisites = const [],
    int order = 0,
  }) async {
    final doc = await topics.add({
      topicNameFieldName: name,
      topicSubjectIdFieldName: subjectId,
      topicPrerequisitesFieldName: prerequisites,
      topicOrderFieldName: order,
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getTopics(String subjectId) async {
    final snapshot =
        await topics.where(topicSubjectIdFieldName, isEqualTo: subjectId).get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()[topicNameFieldName],
              'order': doc.data()[topicOrderFieldName] ?? 0,
            })
        .toList();
  }

  // ------------------------ CONCEPTS ------------------------

  Future<String> addConcept({
    required String name,
    required String subjectId,
    required String topicId,
  }) async {
    final doc = await concepts.add({
      conceptNameFieldName: name,
      conceptSubjectIdFieldName: subjectId,
      conceptTopicIdFieldName: topicId,
      conceptLastSeenFieldName: null,
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getConcepts(String topicId) async {
    final snapshot =
        await concepts.where(conceptTopicIdFieldName, isEqualTo: topicId).get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()[conceptNameFieldName],
            })
        .toList();
  }

  // ------------------------ QUESTIONS (core add helper) ------------------------

  Future<void> _addQuestion(Map<String, dynamic> data) async {
    data[questionCreatedAtField] = FieldValue.serverTimestamp();
    await questions.add(data);
  }

  Future<void> addQuestion({
    required String type,
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    dynamic correctAnswer,
    List<String>? options,
    List<String>? images,
    List<Map<String, String>>? matchPair,
    Map<String, int>? correctCoordinates,
    int versionNumber = 1,
  }) async {
    final Map<String, dynamic> payload = {
      questionTypeField: type,
      questionSubjectIdField: subjectId,
      questionTopicIdField: topicId,
      questionTextField: questionText,
      questionHintTextField: hintText ?? '',
      questionCorrectAnswerField: correctAnswer,
      questionVersionNumberField: versionNumber,
    };

    if (conceptId != null) payload[questionConceptIdField] = conceptId;
    if (options != null) payload[questionOptionsField] = options;
    if (images != null) payload[questionImageField] = images;
    if (matchPair != null) payload[questionMatchPairField] = matchPair;
    if (correctCoordinates != null) {
      payload[questionCorrectCoordinatesField] = correctCoordinates;
    }

    await _addQuestion(payload);
  }

  // ------------------------ QUESTIONS (admin wrappers) ------------------------

  Future<void> addMCQQuestion({
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    required List<String> options,
    required String correctAnswer,
    int versionNumber = 1,
  }) async {
    String normalizedCorrect;
    final letter = correctAnswer.trim().toUpperCase();
    if (letter.length == 1 &&
        letter.codeUnitAt(0) >= 65 &&
        letter.codeUnitAt(0) < 65 + options.length) {
      final idx = letter.codeUnitAt(0) - 65;
      normalizedCorrect = options[idx];
    } else {
      normalizedCorrect = correctAnswer;
    }

    await addQuestion(
      type: 'mcq',
      subjectId: subjectId,
      topicId: topicId,
      conceptId: conceptId,
      questionText: questionText,
      hintText: hintText,
      correctAnswer: normalizedCorrect,
      options: options,
      versionNumber: versionNumber,
    );
  }

  Future<void> addFillupQuestion({
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    required List<String> correctAnswers,
    int versionNumber = 1,
  }) async {
    await addQuestion(
      type: 'fillup',
      subjectId: subjectId,
      topicId: topicId,
      conceptId: conceptId,
      questionText: questionText,
      hintText: hintText,
      correctAnswer: correctAnswers,
      versionNumber: versionNumber,
    );
  }

  Future<void> addOrderingQuestion({
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    required List<String> phrases,
    int versionNumber = 1,
  }) async {
    await addQuestion(
      type: 'ordering',
      subjectId: subjectId,
      topicId: topicId,
      conceptId: conceptId,
      questionText: questionText,
      hintText: hintText,
      correctAnswer: phrases,
      versionNumber: versionNumber,
      options: phrases,
    );
  }

  Future<void> addMatchPairsQuestion({
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    required List<Map<String, String>> pairs,
    int versionNumber = 1,
  }) async {
    await addQuestion(
      type: 'match_pairs',
      subjectId: subjectId,
      topicId: topicId,
      conceptId: conceptId,
      questionText: questionText,
      hintText: hintText,
      matchPair: pairs,
      versionNumber: versionNumber,
    );
  }

  Future<void> addDragDropQuestion({
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    required Map<String, String> mapping,
    int versionNumber = 1,
  }) async {
    final draggables = mapping.keys.toList();
    final boxes = mapping.values.toSet().toList();

    final payload = {
      questionTypeField: 'drag_drop',
      questionSubjectIdField: subjectId,
      questionTopicIdField: topicId,
      if (conceptId != null) questionConceptIdField: conceptId,
      questionTextField: questionText,
      questionHintTextField: hintText ?? '',
      questionCorrectAnswerField: mapping,
      'draggables': draggables,
      'boxes': boxes,
      questionVersionNumberField: versionNumber,
    };
    await _addQuestion(payload);
  }

  Future<void> addTapImageQuestion({
    required String subjectId,
    required String topicId,
    String? conceptId,
    required String questionText,
    String? hintText,
    String? imageUrl,
    required int x,
    required int y,
    int versionNumber = 1,
  }) async {
    final payload = {
      questionTypeField: 'tap_image',
      questionSubjectIdField: subjectId,
      questionTopicIdField: topicId,
      if (conceptId != null) questionConceptIdField: conceptId,
      questionTextField: questionText,
      questionHintTextField: hintText ?? '',
      if (imageUrl != null) questionImageField: [imageUrl],
      questionCorrectCoordinatesField: {'x': x, 'y': y},
      questionVersionNumberField: versionNumber,
    };
    await _addQuestion(payload);
  }

  // ------------------------ Singleton ------------------------
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
