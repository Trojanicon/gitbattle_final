import 'dart:convert';

class DailyStat {
  final DateTime date;
  final int commits;
  final int pointsEarned;

  DailyStat({required this.date, required this.commits, required this.pointsEarned});

  factory DailyStat.fromJson(Map<String, dynamic> j) => DailyStat(
        date: DateTime.parse(j['date']),
        commits: j['commits'] ?? 0,
        pointsEarned: j['pointsEarned'] ?? 0,
      );
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        icon: j['icon'] ?? '🏆',
        unlockedAt: DateTime.tryParse(j['unlockedAt'] ?? '') ?? DateTime.now(),
      );
}

class LevelInfo {
  final int level;
  final String title;
  final int minPoints;

  LevelInfo({required this.level, required this.title, required this.minPoints});

  factory LevelInfo.fromJson(Map<String, dynamic> j) => LevelInfo(
        level: j['level'] ?? 1,
        title: j['title'] ?? 'Newbie',
        minPoints: j['minPoints'] ?? 0,
      );
}

class User {
  final String id;
  final String githubUsername;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String location;
  final int points;
  final int totalPoints;
  final int level;
  final int streak;
  final int longestStreak;
  final int totalCommits;
  final int commitsThisWeek;
  final int commitsThisMonth;
  final int publicRepos;
  final int followers;
  final int weeklyPoints;
  final List<DailyStat> dailyStats;
  final List<Achievement> achievements;
  final LevelInfo? levelInfo;
  final DateTime? lastSyncedAt;
  final bool isCurrentUser;

  User({
    required this.id,
    required this.githubUsername,
    required this.displayName,
    required this.avatarUrl,
    this.bio = '',
    this.location = '',
    required this.points,
    required this.totalPoints,
    required this.level,
    required this.streak,
    this.longestStreak = 0,
    this.totalCommits = 0,
    this.commitsThisWeek = 0,
    this.commitsThisMonth = 0,
    this.publicRepos = 0,
    this.followers = 0,
    this.weeklyPoints = 0,
    this.dailyStats = const [],
    this.achievements = const [],
    this.levelInfo,
    this.lastSyncedAt,
    this.isCurrentUser = false,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] ?? j['_id'] ?? '',
        githubUsername: j['githubUsername'] ?? '',
        displayName: j['displayName'] ?? j['githubUsername'] ?? '',
        avatarUrl: j['avatarUrl'] ?? '',
        bio: j['bio'] ?? '',
        location: j['location'] ?? '',
        points: j['points'] ?? 0,
        totalPoints: j['totalPoints'] ?? 0,
        level: j['level'] ?? 1,
        streak: j['streak'] ?? 0,
        longestStreak: j['longestStreak'] ?? 0,
        totalCommits: j['totalCommits'] ?? 0,
        commitsThisWeek: j['commitsThisWeek'] ?? 0,
        commitsThisMonth: j['commitsThisMonth'] ?? 0,
        publicRepos: j['publicRepos'] ?? 0,
        followers: j['followers'] ?? 0,
        weeklyPoints: j['weeklyPoints'] ?? 0,
        dailyStats: (j['dailyStats'] as List<dynamic>? ?? [])
            .map((s) => DailyStat.fromJson(s))
            .toList(),
        achievements: (j['achievements'] as List<dynamic>? ?? [])
            .map((a) => Achievement.fromJson(a))
            .toList(),
        levelInfo: j['levelInfo'] != null ? LevelInfo.fromJson(j['levelInfo']) : null,
        lastSyncedAt: j['lastSyncedAt'] != null
            ? DateTime.tryParse(j['lastSyncedAt'])
            : null,
        isCurrentUser: j['isCurrentUser'] ?? false,
      );

  // Next level points (approximate)
  int get nextLevelPoints {
    final thresholds = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000];
    if (level >= thresholds.length) return thresholds.last;
    return thresholds[level];
  }

  int get currentLevelMin {
    final thresholds = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000];
    if (level - 1 >= thresholds.length) return 0;
    return thresholds[level - 1];
  }

  double get levelProgress {
    final min = currentLevelMin;
    final max = nextLevelPoints;
    if (max == min) return 1.0;
    return ((totalPoints - min) / (max - min)).clamp(0.0, 1.0);
  }
}

class LeaderboardEntry {
  final String id;
  final String githubUsername;
  final String displayName;
  final String avatarUrl;
  final int points;
  final int totalPoints;
  final int weeklyPoints;
  final int level;
  final int streak;
  final int rank;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.id,
    required this.githubUsername,
    required this.displayName,
    required this.avatarUrl,
    required this.points,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.level,
    required this.streak,
    required this.rank,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        id: j['id'] ?? j['_id'] ?? '',
        githubUsername: j['githubUsername'] ?? '',
        displayName: j['displayName'] ?? '',
        avatarUrl: j['avatarUrl'] ?? '',
        points: j['points'] ?? 0,
        totalPoints: j['totalPoints'] ?? 0,
        weeklyPoints: j['weeklyPoints'] ?? 0,
        level: j['level'] ?? 1,
        streak: j['streak'] ?? 0,
        rank: j['rank'] ?? 0,
        isCurrentUser: j['isCurrentUser'] ?? false,
      );
}
