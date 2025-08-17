import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudTopic {
  final String documentId;
  final String subjectId;
  final String name;
  final List<String> prerequisites;
  final int order;

  const CloudTopic({
    required this.documentId,
    required this.subjectId,
    required this.name,
    required this.prerequisites,
    required this.order,
  });

  CloudTopic.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        subjectId = snapshot.data()?[topicSubjectIdFieldName] ?? '',
        name = snapshot.data()?[topicNameFieldName] ?? '',
        prerequisites = List<String>.from(snapshot.data()?[topicPrerequisitesFieldName] ?? []),
        order = snapshot.data()?[topicOrderFieldName] ?? 0;
}
