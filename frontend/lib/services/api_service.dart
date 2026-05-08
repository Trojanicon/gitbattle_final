import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000';

  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // ── Token Management ─────────────────────────────────────────────────────

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Generic HTTP helpers ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> _patch(String path, Map body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(body['error'] ?? 'Unknown error', res.statusCode);
    }
    return body;
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Exchange GitHub OAuth code for JWT
  static Future<({String token, User user})> loginWithCode(String code) async {
    final data = await _post('/auth/mobile', {'code': code});
    final token = data['token'] as String;
    await saveToken(token);
    return (token: token, user: User.fromJson(data['user']));
  }

  static Future<User> getMe() async {
    final data = await _get('/auth/me');
    return User.fromJson(data['user']);
  }

  static Future<({User user, List<dynamic> newAchievements})> syncGitHub() async {
    final data = await _post('/auth/sync', {});
    return (
      user: User.fromJson(data['user']),
      newAchievements: data['newAchievements'] ?? [],
    );
  }

  static Future<void> logout() async {
    try {
      await _delete('/auth/logout');
    } catch (_) {}
    await deleteToken();
  }

  // ── User ─────────────────────────────────────────────────────────────────

  static Future<User> getUserProfile(String username) async {
    final data = await _get('/user/$username');
    return User.fromJson(data['user']);
  }

  static Future<List<String>> getInsights() async {
    final data = await _get('/user/insights/personal');
    return List<String>.from(data['insights'] ?? []);
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  static Future<({List<LeaderboardEntry> users, int myRank})>
      getGlobalLeaderboard({int page = 1}) async {
    final data = await _get('/leaderboard/global?page=$page&limit=50');
    final users = (data['leaderboard'] as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
    return (users: users, myRank: data['myRank'] ?? 0);
  }

  static Future<({List<LeaderboardEntry> users, int myRank, DateTime? nextReset})>
      getWeeklyLeaderboard() async {
    final data = await _get('/leaderboard/weekly');
    final users = (data['leaderboard'] as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
    final nextReset = data['nextResetAt'] != null
        ? DateTime.tryParse(data['nextResetAt'])
        : null;
    return (users: users, myRank: data['myRank'] ?? 0, nextReset: nextReset);
  }

  static Future<List<LeaderboardEntry>> getStreakLeaderboard() async {
    final data = await _get('/leaderboard/streak');
    return (data['leaderboard'] as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  static Future<List<User>> getFriends() async {
    final data = await _get('/friends');
    return (data['friends'] as List).map((f) => User.fromJson(f)).toList();
  }

  static Future<void> sendFriendRequest(String githubUsername) async {
    await _post('/friends/request', {'githubUsername': githubUsername});
  }

  static Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final data = await _get('/friends/requests');
    return List<Map<String, dynamic>>.from(data['requests'] ?? []);
  }

  static Future<void> handleFriendRequest(String requestId, String action) async {
    await _patch('/friends/request/$requestId', {'action': action});
  }

  static Future<void> removeFriend(String friendId) async {
    await _delete('/friends/$friendId');
  }

  static Future<List<LeaderboardEntry>> getFriendsLeaderboard() async {
    final data = await _get('/friends/leaderboard');
    return (data['leaderboard'] as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  // ── Challenges ────────────────────────────────────────────────────────────

  static Future<List<Challenge>> getChallenges() async {
    final data = await _get('/challenges');
    return (data['challenges'] as List)
        .map((c) => Challenge.fromJson(c))
        .toList();
  }

  static Future<Challenge> getChallenge(String id) async {
    final data = await _get('/challenges/$id');
    return Challenge.fromJson(data['challenge']);
  }

  static Future<Challenge> createChallenge({
    required String name,
    required String description,
    required String type,
    required int goal,
    required int duration,
    required bool isPublic,
  }) async {
    final data = await _post('/challenges', {
      'name': name,
      'description': description,
      'type': type,
      'goal': goal,
      'duration': duration,
      'isPublic': isPublic,
    });
    return Challenge.fromJson(data['challenge']);
  }

  static Future<void> joinChallenge(String id) async {
    await _post('/challenges/$id/join', {});
  }

  static Future<void> joinChallengeByCode(String code) async {
    await _post('/challenges/join-code/$code', {});
  }

  static Future<void> leaveChallenge(String id) async {
    await _delete('/challenges/$id/leave');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
