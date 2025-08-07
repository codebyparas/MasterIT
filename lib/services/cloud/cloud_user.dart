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
  final Map<String, dynamic> strength;
  final int quizzesTaken;
  final Timestamp lastActive;
  final List<dynamic> topicsIntroduced;

  const CloudUser({
    required this.documentId,
    required this.name,
    required this.email,
    required this.initialSetupDone,
    required this.streak,
    required this.strength,
    required this.quizzesTaken,
    required this.lastActive,
    required this.topicsIntroduced,
  });

  CloudUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        name = snapshot.data()?[userNameFieldName] ?? '',
        email = snapshot.data()?[userEmailFieldName] ?? '',
        initialSetupDone = snapshot.data()?[userInitialSetupDoneFieldName] ?? false,
        streak = snapshot.data()?[userStreakFieldName] ?? 0,
        strength = snapshot.data()?[userStrengthFieldName] ?? {},
        quizzesTaken = snapshot.data()?[userQuizzesTakenFieldName] ?? 0,
        lastActive = snapshot.data()?[userLastActiveFieldName] ?? Timestamp.now(),
        topicsIntroduced = snapshot.data()?[userTopicsIntroducedFieldName] ?? [];
}
