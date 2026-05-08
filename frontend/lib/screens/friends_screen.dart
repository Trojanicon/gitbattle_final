import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getFriends(),
        ApiService.getFriendRequests(),
      ]);
      if (mounted) {
        setState(() {
          _friends = results[0] as List<User>;
          _requests = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    setState(() => _searching = true);
    try {
      await ApiService.sendFriendRequest(username);
      _searchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to @$username!'),
            backgroundColor: AppTheme.brand,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _handleRequest(String requestId, String action) async {
    try {
      await ApiService.handleFriendRequest(requestId, action);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process request')),
        );
      }
    }
  }

  Future<void> _removeFriend(String friendId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove @$username from your friends?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.removeFriend(friendId);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search / Add friend bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Add friend by GitHub username',
                    prefixIcon: Icon(Icons.person_search, color: AppTheme.brand),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendRequest(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searching ? null : _sendRequest,
                child: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.brand,
            unselectedLabelColor:
                isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
            indicatorColor: AppTheme.brand,
            labelStyle: const TextStyle(
              fontFamily: GoogleFonts.syne().fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'FRIENDS (${_friends.length})'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('REQUESTS'),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_requests.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.brand))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Friends list
                    RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.brand,
                      child: _friends.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                const Center(
                                  child: Column(
                                    children: [
                                      Text('👥', style: TextStyle(fontSize: 48)),
                                      SizedBox(height: 12),
                                      Text(
                                        'No friends yet\nSearch above to add some!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _friends.length,
                              itemBuilder: (_, i) {
                                final friend = _friends[i];
                                return _FriendTile(
                                  user: friend,
                                  onRemove: () =>
                                      _removeFriend(friend.id, friend.githubUsername),
                                );
                              },
                            ),
                    ),

                    // Requests list
                    RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.brand,
                      child: _requests.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Column(
                                    children: [
                                      Text('📭', style: TextStyle(fontSize: 48)),
                                      SizedBox(height: 12),
                                      Text(
                                        'No pending requests',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _requests.length,
                              itemBuilder: (_, i) {
                                final req = _requests[i];
                                final sender =
                                    req['sender'] as Map<String, dynamic>? ?? {};
                                return _RequestTile(
                                  requestId: req['_id'] ?? '',
                                  username: sender['githubUsername'] ?? '',
                                  avatarUrl: sender['avatarUrl'] ?? '',
                                  displayName: sender['displayName'] ?? '',
                                  points: sender['points'] ?? 0,
                                  level: sender['level'] ?? 1,
                                  onAccept: () =>
                                      _handleRequest(req['_id'] ?? '', 'accept'),
                                  onDecline: () =>
                                      _handleRequest(req['_id'] ?? '', 'decline'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final User user;
  final VoidCallback onRemove;

  const _FriendTile({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage:
                user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            backgroundColor: AppTheme.brand,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isNotEmpty
                      ? user.displayName
                      : user.githubUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '@${user.githubUsername} · Lvl ${user.level}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.streak}🔥',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${user.weeklyPoints}pts/wk',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_remove, size: 18),
            color: AppTheme.danger,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String requestId;
  final String username;
  final String avatarUrl;
  final String displayName;
  final int points;
  final int level;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({
    required this.requestId,
    required this.username,
    required this.avatarUrl,
    required this.displayName,
    required this.points,
    required this.level,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                backgroundColor: AppTheme.brand,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text('@$username · Lvl $level · ${points}pts'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
