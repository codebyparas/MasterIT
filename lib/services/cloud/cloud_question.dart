import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudQuestion {
  final String documentId;
  final String type; // mcq, fillup, match_pairs, etc.
  final String text;
  final String? hint;
  final String topic;
  final String subject;
  final List<String>? options;       // mcq
  final dynamic correctAnswer;       // mcq: String, fillup: String/List
  final List<Map<String, String>>? matchPairs;
  final Map<String, dynamic>? tapAreas; // x,y,radius/box
  final List<String>? orderingPhrases;
  final Map<String, String>? dragMapping; // {draggable: target}

  const CloudQuestion({
    required this.documentId,
    required this.type,
    required this.text,
    required this.topic,
    required this.subject,
    this.hint,
    this.options,
    this.correctAnswer,
    this.matchPairs,
    this.tapAreas,
    this.orderingPhrases,
    this.dragMapping,
  });

  CloudQuestion.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        type = snapshot.data()?[questionTypeField] ?? '',
        text = snapshot.data()?[questionTextField] ?? '',
        hint = snapshot.data()?[questionHintTextField],
        topic = snapshot.data()?['topicId'] ?? '',
        subject = snapshot.data()?['subjectId'] ?? '',
        options = (snapshot.data()?['options'] as List?)?.cast<String>(),
        correctAnswer = snapshot.data()?[questionCorrectAnswerField],
        matchPairs = (snapshot.data()?['pairs'] as List?)
            ?.map((e) => Map<String, String>.from(e))
            .toList(),
        tapAreas = snapshot.data()?['correctAreas'],
        orderingPhrases = (snapshot.data()?['phrases'] as List?)?.cast<String>(),
        dragMapping = snapshot.data()?['correctMapping'] != null
            ? Map<String, String>.from(snapshot.data()?['correctMapping'])
            : null;
}
