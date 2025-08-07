import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudQuestion {
  final String documentId;
  final String type; // 'mcq', 'fill', 'tap', etc.
  final String text;
  final String? imageUrl;
  final String? hint;
  final String topic;
  final String subject;

  final List<String>? options; // MCQ
  final dynamic correctAnswer; // string, list, etc.
  final Map<String, dynamic>? correctTapPosition; // {'x': 120, 'y': 340}
  final List<Map<String, String>>? matchPairs;
  final List<String>? boxes;
  final List<String>? draggables;

  const CloudQuestion({
    required this.documentId,
    required this.type,
    required this.text,
    required this.topic,
    required this.subject,
    this.imageUrl,
    this.hint,
    this.options,
    this.correctAnswer,
    this.correctTapPosition,
    this.matchPairs,
    this.boxes,
    this.draggables,
  });

  CloudQuestion.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        type = snapshot.data()?[questionTypeField] ?? '',
        text = snapshot.data()?[questionTextField] ?? '',
        imageUrl = snapshot.data()?[questionImageField],
        hint = snapshot.data()?[questionHintTextField],
        topic = snapshot.data()?[questionTopicField] ?? '',
        subject = snapshot.data()?[questionSubjectField] ?? '',
        options = (snapshot.data()?[questionOptionsField] as List?)?.cast<String>(),
        correctAnswer = snapshot.data()?[questionCorrectAnswerField],
        correctTapPosition = snapshot.data()?[questionCorrectTapPositionField],
        matchPairs = (snapshot.data()?[questionMatchPairsField] as List?)
            ?.map((e) => Map<String, String>.from(e))
            .toList(),
        boxes = (snapshot.data()?[questionBoxesField] as List?)?.cast<String>(),
        draggables = (snapshot.data()?[questionDraggablesField] as List?)?.cast<String>();
}
