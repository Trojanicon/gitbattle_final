class ChallengeParticipant {
  final String userId;
  final String githubUsername;
  final String displayName;
  final String avatarUrl;
  final int progress;
  final double progressPercentage;
  final bool completed;

  ChallengeParticipant({
    required this.userId,
    required this.githubUsername,
    required this.displayName,
    required this.avatarUrl,
    required this.progress,
    required this.progressPercentage,
    required this.completed,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> j) {
    final user = j['user'];
    return ChallengeParticipant(
      userId: user is Map ? (user['_id'] ?? user['id'] ?? '') : '',
      githubUsername: user is Map ? (user['githubUsername'] ?? '') : '',
      displayName: user is Map ? (user['displayName'] ?? '') : '',
      avatarUrl: user is Map ? (user['avatarUrl'] ?? '') : '',
      progress: j['progress'] ?? 0,
      progressPercentage: (j['progressPercentage'] ?? 0).toDouble(),
      completed: j['completed'] ?? false,
    );
  }
}

class Challenge {
  final String id;
  final String name;
  final String description;
  final String type;
  final int goal;
  final int duration;
  final bool isPublic;
  final String? inviteCode;
  final String creatorUsername;
  final String creatorAvatar;
  final List<ChallengeParticipant> participants;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isParticipant;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.goal,
    required this.duration,
    required this.isPublic,
    this.inviteCode,
    required this.creatorUsername,
    required this.creatorAvatar,
    required this.participants,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isParticipant,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) {
    final creator = j['creator'];
    return Challenge(
      id: j['_id'] ?? j['id'] ?? '',
      name: j['name'] ?? '',
      description: j['description'] ?? '',
      type: j['type'] ?? 'commit_count',
      goal: j['goal'] ?? 0,
      duration: j['duration'] ?? 7,
      isPublic: j['isPublic'] ?? true,
      inviteCode: j['inviteCode'],
      creatorUsername: creator is Map ? (creator['githubUsername'] ?? '') : '',
      creatorAvatar: creator is Map ? (creator['avatarUrl'] ?? '') : '',
      participants: (j['participants'] as List<dynamic>? ?? [])
          .map((p) => ChallengeParticipant.fromJson(p))
          .toList(),
      startDate: DateTime.tryParse(j['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(j['endDate'] ?? '') ?? DateTime.now(),
      status: j['status'] ?? 'upcoming',
      isParticipant: j['isParticipant'] ?? false,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'commit_count':
        return 'Commits';
      case 'streak':
        return 'Streak Days';
      case 'points':
        return 'Points';
      case 'repo_count':
        return 'Repositories';
      default:
        return 'Progress';
    }
  }

  String get typeIcon {
    switch (type) {
      case 'commit_count':
        return '📝';
      case 'streak':
        return '🔥';
      case 'points':
        return '⭐';
      case 'repo_count':
        return '📁';
      default:
        return '🏆';
    }
  }

  Duration get remaining => endDate.difference(DateTime.now());

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isUpcoming => status == 'upcoming';
}
