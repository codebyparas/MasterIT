// ------------------------ USERS ------------------------
const userIdFieldName = 'id';
const userNameFieldName = 'name';
const userEmailFieldName = 'email';
const userInitialSetupDoneFieldName = 'initialSetupDone';
const userLastActiveFieldName = 'lastActive';
const userQuizzesTakenFieldName = 'quizzesTaken';
const userStreakFieldName = 'streak';
const userXPFieldNAme = 'xp';
const userStrengthFieldName = 'strength'; // Map<String, dynamic>
const userSubjectsIntroducedFieldName = 'subjectsIntroduced'; // List<String>
const userTopicsInProgressFieldName = 'topicsInProgress'; // Map<String, String> {topicId: status}

// ------------------------ SUBJECTS ------------------------
const subjectIdFieldName = 'id';
const subjectNameFieldName = 'name';
const subjectDescriptionFieldName = 'description';

// ------------------------ TOPICS ------------------------
const topicIdFieldName = 'id';
const topicNameFieldName = 'name';
const topicSubjectIdFieldName = 'subjectId';
const topicPrerequisitesFieldName = 'prerequisites'; // List<String>
const topicOrderFieldName = 'order';

// ------------------------ CONCEPTS ------------------------
const conceptIdFieldName = 'id';
const conceptNameFieldName = 'name';
const conceptSubjectIdFieldName = 'subjectId';
const conceptTopicIdFieldName = 'topicId';
const conceptLastSeenFieldName = 'lastSeen';

// ------------------------ QUESTIONS ------------------------
const questionIdField = 'id';
const questionTypeField = 'type';
const questionSubjectIdField = 'subjectId';
const questionTopicIdField = 'topicId';
const questionConceptIdField = 'conceptId';
const questionTextField = 'questionText';
const questionHintTextField = 'hintText';
const questionCorrectAnswerField = 'correctAnswer'; // dynamic
const questionOptionsField = 'options'; // List<String>
const questionImageField = 'images'; // List<String> or single URL
const questionMatchPairField = 'matchPair'; // List<Map<String,String>>
const questionCorrectCoordinatesField = 'correctCoordinates'; // {x: int, y: int}
const questionVersionNumberField = 'versionNumber';
const questionCreatedAtField = 'createdAt';
