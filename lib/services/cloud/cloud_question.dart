import 'package:cloud_firestore/cloud_firestore.dart';

class CloudQuestion {
  final String documentId;
  final String type;
  final String subjectId;
  final String topicId;
  final String? conceptId;
  final String questionText;
  final String? hintText;
  final dynamic correctAnswer;
  final List<String>? options;
  final List<String> images;
  final dynamic matchPair;
  final Map<String, dynamic>? correctCoordinates; // Keep as dynamic for flexibility

  CloudQuestion({
    required this.documentId,
    required this.type,
    required this.subjectId,
    required this.topicId,
    this.conceptId,
    required this.questionText,
    this.hintText,
    required this.correctAnswer,
    this.options,
    required this.images,
    this.matchPair,
    this.correctCoordinates,
  });

  factory CloudQuestion.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    
    try {
      return CloudQuestion(
        documentId: snapshot.id,
        type: _safeString(data['type']),
        subjectId: _safeString(data['subjectId']),
        topicId: _safeString(data['topicId']),
        conceptId: data['conceptId'] != null ? _safeString(data['conceptId']) : null,
        questionText: _safeString(data['questionText']),
        hintText: data['hintText'] != null ? _safeString(data['hintText']) : null,
        correctAnswer: data['correctAnswer'],
        options: _safeStringList(data['options']),
        images: _safeStringList(data['images']) ?? [],
        matchPair: data['matchPair'],
        correctCoordinates: data['correctCoordinates'] is Map 
            ? Map<String, dynamic>.from(data['correctCoordinates']) 
            : null,
      );
    } catch (e) {
      print('Error parsing CloudQuestion ${snapshot.id}: $e');
      print('Data: $data');
      rethrow;
    }
  }

  // Helper methods remain the same...
  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return value.toString();
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value.toString();
  }

  static List<String>? _safeStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return [value];
    }
    return null;
  }
}
