import '../services/cloud/cloud_question.dart';

class QuizQuestion {
  final String id;
  final String type;
  final String subjectId;
  final String topicId;
  final String conceptId;
  final String questionText;
  final String? hintText;
  final dynamic correctAnswer;
  final List<String>? options;
  final List<String> images;
  final List<Map<String, String>>? matchPair;
  final Map<String, double>? correctCoordinates; // CHANGED: Now uses double

  QuizQuestion({
    required this.id,
    required this.type,
    required this.subjectId,
    required this.topicId,
    required this.conceptId,
    required this.questionText,
    this.hintText,
    required this.correctAnswer,
    this.options,
    required this.images,
    this.matchPair,
    this.correctCoordinates,
  });

  factory QuizQuestion.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return QuizQuestion(
        id: id,
        type: _safeString(data['type']),
        subjectId: _safeString(data['subjectId']),
        topicId: _safeString(data['topicId']),
        conceptId: _safeString(data['conceptId']),
        questionText: _safeString(data['questionText']),
        hintText: data['hintText'] != null ? _safeString(data['hintText']) : null,
        correctAnswer: data['correctAnswer'], // Keep as dynamic
        options: _safeStringList(data['options']),
        images: _safeStringList(data['images']) ?? [],
        matchPair: _parseMatchPair(data['matchPair']),
        correctCoordinates: _parseCoordinates(data['correctCoordinates']),
      );
    } catch (e) {
      print('Error parsing Firestore question $id: $e');
      rethrow;
    }
  }

  factory QuizQuestion.fromCloudQuestion(CloudQuestion cloudQuestion) {
    try {
      return QuizQuestion(
        id: cloudQuestion.documentId,
        type: cloudQuestion.type,
        subjectId: cloudQuestion.subjectId,
        topicId: cloudQuestion.topicId,
        conceptId: cloudQuestion.conceptId ?? '',
        questionText: cloudQuestion.questionText,
        hintText: cloudQuestion.hintText,
        correctAnswer: cloudQuestion.correctAnswer,
        options: _safeStringList(cloudQuestion.options),
        images: _safeStringList(cloudQuestion.images) ?? [],
        matchPair: _parseMatchPair(cloudQuestion.matchPair),
        correctCoordinates: cloudQuestion.correctCoordinates != null
            ? _convertCoordinatesToDouble(cloudQuestion.correctCoordinates!)
            : null,
      );
    } catch (e) {
      print('Error parsing CloudQuestion ${cloudQuestion.documentId}: $e');
      rethrow;
    }
  }

  // Safe string conversion
  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return value.toString();
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value.toString();
  }

  // Safe list conversion
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

  // UPDATED: Convert coordinates to double map
  static Map<String, double> _convertCoordinatesToDouble(Map<String, dynamic> coordsMap) {
    final Map<String, double> result = {};
    
    coordsMap.forEach((key, value) {
      if (value is double) {
        result[key] = value;
      } else if (value is int) {
        result[key] = value.toDouble();
      } else if (value is num) {
        result[key] = value.toDouble();
      } else if (value is String) {
        result[key] = double.tryParse(value) ?? 0.0;
      } else {
        result[key] = 0.0; // fallback for invalid values
      }
    });
    
    return result;
  }

  // Parse match pairs safely
  static List<Map<String, String>>? _parseMatchPair(dynamic matchPairData) {
    if (matchPairData == null) return null;
    
    try {
      if (matchPairData is List) {
        return matchPairData.map<Map<String, String>>((item) {
          if (item is Map) {
            final Map<String, String> stringMap = {};
            item.forEach((k, v) {
              stringMap[k.toString()] = v.toString();
            });
            return stringMap;
          }
          return <String, String>{};
        }).toList();
      }
      
      if (matchPairData is Map) {
        final Map<String, String> stringMap = {};
        matchPairData.forEach((k, v) {
          stringMap[k.toString()] = v.toString();
        });
        return [stringMap];
      }
    } catch (e) {
      print('Error parsing matchPair: $e');
    }
    
    return null;
  }

  // UPDATED: Parse coordinates as double
  static Map<String, double>? _parseCoordinates(dynamic coordData) {
    if (coordData == null) return null;
    
    try {
      if (coordData is Map) {
        final Map<String, dynamic> dynamicMap = Map<String, dynamic>.from(coordData);
        return _convertCoordinatesToDouble(dynamicMap);
      }
    } catch (e) {
      print('Error parsing coordinates: $e');
    }
    
    return null;
  }
}

// Rest of QuizState class remains the same...
class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, dynamic> userAnswers;
  final int score;
  final int xp;
  final bool isCompleted;

  QuizState({
    required this.questions,
    this.currentIndex = 0,
    required this.userAnswers,
    this.score = 0,
    this.xp = 0,
    this.isCompleted = false,
  });

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, dynamic>? userAnswers,
    int? score,
    int? xp,
    bool? isCompleted,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score ?? this.score,
      xp: xp ?? this.xp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
