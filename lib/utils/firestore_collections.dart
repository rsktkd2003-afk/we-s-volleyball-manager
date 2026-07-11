/// Firestore collection names, centralized to avoid typos and duplication
/// across repositories, services, and screens.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String players = 'players';
  static const String playerLinkRequests = 'player_link_requests';
  static const String announcements = 'announcements';
  static const String goals = 'goals';
  static const String matchPolls = 'match_polls';
  static const String schedules = 'schedules';
  static const String scheduleTemplates = 'schedule_templates';
  static const String fcmTokens = 'fcmTokens';

  // Subcollection names.
  static const String votes = 'votes';
  static const String responses = 'responses';
  static const String issues = 'issues';
  static const String comments = 'comments';
}
