import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloud_storage_constants.dart';

@immutable
class CloudUser {
  final String documentId;
  final String name;
  final String email;
  final bool initialSetupDone;
  final int streak;
  final int quizzesTaken;
  final DateTime? lastActive;
  final Map<String, dynamic> strength; // topicId -> strength value
  final List<String> subjectsIntroduced;
  final Map<String, String> topicsInProgress; // topicId -> status

  const CloudUser({
    required this.documentId,
    required this.name,
    required this.email,
    required this.initialSetupDone,
    required this.streak,
    required this.quizzesTaken,
    required this.lastActive,
    required this.strength,
    required this.subjectsIntroduced,
    required this.topicsInProgress,
  });

  CloudUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        name = snapshot.data()?[userNameFieldName] ?? '',
        email = snapshot.data()?[userEmailFieldName] ?? '',
        initialSetupDone = snapshot.data()?[userInitialSetupDoneFieldName] ?? false,
        streak = snapshot.data()?[userStreakFieldName] ?? 0,
        quizzesTaken = snapshot.data()?[userQuizzesTakenFieldName] ?? 0,
        lastActive = (snapshot.data()?[userLastActiveFieldName] as Timestamp?)?.toDate(),
        strength = Map<String, dynamic>.from(snapshot.data()?[userStrengthFieldName] ?? {}),
        subjectsIntroduced = List<String>.from(snapshot.data()?[userSubjectsIntroducedFieldName] ?? []),
        topicsInProgress = Map<String, String>.from(snapshot.data()?[userTopicsInProgressFieldName] ?? {});
}
