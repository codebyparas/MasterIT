import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudTopic {
  final String documentId;
  final String name;
  final String subject;
  final bool isUnlockedByDefault;
  final int difficulty;
  final List<String> prerequisites;

  const CloudTopic({
    required this.documentId,
    required this.name,
    required this.subject,
    required this.isUnlockedByDefault,
    required this.difficulty,
    required this.prerequisites,
  });

  CloudTopic.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        name = snapshot.data()?[topicNameFieldName] ?? '',
        subject = snapshot.data()?[topicSubjectFieldName] ?? '',
        isUnlockedByDefault = snapshot.data()?[topicIsUnlockedFieldName] ?? false,
        difficulty = snapshot.data()?[topicDifficultyFieldName] ?? 1,
        prerequisites = List<String>.from(snapshot.data()?[topicPrerequisitesFieldName] ?? []);
}
