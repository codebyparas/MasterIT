import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudConcept {
  final String documentId;
  final String topicId;
  final String subjectId;
  final String name;
  final DateTime? lastSeen;

  const CloudConcept({
    required this.documentId,
    required this.topicId,
    required this.subjectId,
    required this.name,
    required this.lastSeen,
  });

  CloudConcept.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        topicId = snapshot.data()?[conceptTopicIdFieldName] ?? '',
        subjectId = snapshot.data()?[conceptSubjectIdFieldName] ?? '',
        name = snapshot.data()?[conceptNameFieldName] ?? '',
        lastSeen = (snapshot.data()?[conceptLastSeenFieldName] as Timestamp?)?.toDate();
}
