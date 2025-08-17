import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudQuestion {
  final String documentId;
  final String subjectId;
  final String topicId;
  final String conceptId;
  final String questionText;
  final String hintText;
  final String type;
  final String correctAnswer;
  final List<String> options;
  final List<String> images;
  final Map<String, String>? matchPair;
  final Map<String, dynamic>? correctCoordinates;
  final int versionNumber;
  final DateTime createdAt;

  const CloudQuestion({
    required this.documentId,
    required this.subjectId,
    required this.topicId,
    required this.conceptId,
    required this.questionText,
    required this.hintText,
    required this.type,
    required this.correctAnswer,
    required this.options,
    required this.images,
    required this.matchPair,
    required this.correctCoordinates,
    required this.versionNumber,
    required this.createdAt,
  });

  CloudQuestion.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        subjectId = snapshot.data()?[questionSubjectIdField] ?? '',
        topicId = snapshot.data()?[questionTopicIdField] ?? '',
        conceptId = snapshot.data()?[questionConceptIdField] ?? '',
        questionText = snapshot.data()?[questionTextField] ?? '',
        hintText = snapshot.data()?[questionHintTextField] ?? '',
        type = snapshot.data()?[questionTypeField] ?? 'mcq',
        correctAnswer = snapshot.data()?[questionCorrectAnswerField] ?? '',
        options = List<String>.from(snapshot.data()?[questionOptionsField] ?? []),
        images = List<String>.from(snapshot.data()?[questionImageField] ?? []),
        matchPair = snapshot.data()?[questionMatchPairField] != null
            ? Map<String, String>.from(snapshot.data()?[questionMatchPairField])
            : null,
        correctCoordinates = snapshot.data()?[questionCorrectCoordinatesField],
        versionNumber = snapshot.data()?[questionVersionNumberField] ?? 1,
        createdAt = (snapshot.data()?[questionCreatedAtField] as Timestamp?)?.toDate() ?? DateTime.now();
}
