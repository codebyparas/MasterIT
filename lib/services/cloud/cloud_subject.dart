import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudSubject {
  final String documentId;
  final String name;
  final List<String> topics;

  const CloudSubject({
    required this.documentId,
    required this.name,
    required this.topics,
  });

  CloudSubject.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        name = snapshot.data()?[subjectNameFieldName] ?? '',
        topics = List<String>.from(snapshot.data()?[subjectTopicsFieldName] ?? []);
}
