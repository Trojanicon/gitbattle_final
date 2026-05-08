import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<LeaderboardEntry> _globalList = [];
  List<LeaderboardEntry> _weeklyList = [];
  List<LeaderboardEntry> _friendsList = [];
  List<LeaderboardEntry> _streakList = [];
  
  int _globalMyRank = 0;
  int _weeklyMyRank = 0;
  DateTime? _nextReset;
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getGlobalLeaderboard(),
        ApiService.getWeeklyLeaderboard(),
        ApiService.getFriendsLeaderboard(),
      ]);

      final global = results[0] as ({List<LeaderboardEntry> users, int myRank});
      final weekly = results[1] as ({List<LeaderboardEntry> users, int myRank, DateTime? nextReset});
      final friends = results[2] as List<LeaderboardEntry>;

      if (mounted) {
        setState(() {
          _globalList = global.users;
          _globalMyRank = global.myRank;
          _weeklyList = weekly.users;
          _weeklyMyRank = weekly.myRank;
          _nextReset = weekly.nextReset;
          _friendsList = friends;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab bar
        Container(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.brand,
            unselectedLabelColor: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
            indicatorColor: AppTheme.brand,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontFamily: GoogleFonts.syne().fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'GLOBAL'),
              Tab(text: 'WEEKLY'),
              Tab(text: 'FRIENDS'),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.brand),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _LeaderboardList(
                      entries: _globalList,
                      myRank: _globalMyRank,
                      label: 'All-time',
                      onRefresh: _loadAll,
                    ),
                    _LeaderboardList(
                      entries: _weeklyList,
                      myRank: _weeklyMyRank,
                      nextReset: _nextReset,
                      label: 'This week',
                      showPoints: 'weekly',
                      onRefresh: _loadAll,
                    ),
                    _LeaderboardList(
                      entries: _friendsList,
                      myRank: 0,
                      label: 'Friends',
                      onRefresh: _loadAll,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final int myRank;
  final DateTime? nextReset;
  final String label;
  final String showPoints;
  final VoidCallback onRefresh;

  const _LeaderboardList({
    required this.entries,
    required this.myRank,
    this.nextReset,
    required this.label,
    this.showPoints = 'total',
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.brand,
      child: CustomScrollView(
        slivers: [
          // My rank banner
          if (myRank > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brand.withOpacity(0.15),
                      AppTheme.purple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      'Your rank: #$myRank',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brand,
                      ),
                    ),
                    if (nextReset != null) ...[
                      const Spacer(),
                      Text(
                        'Resets ${_timeUntil(nextReset!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Top 3 podium
          if (entries.length >= 3)
            SliverToBoxAdapter(child: _Podium(entries: entries.take(3).toList())),

          if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'No data yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final entry = entries[i];
                  final isMe = entry.isCurrentUser;
                  return _LeaderboardTile(
                    entry: entry,
                    isMe: isMe,
                    showWeeklyPoints: showPoints == 'weekly',
                  );
                },
                childCount: entries.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  String _timeUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'soon';
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) Expanded(child: _PodiumSlot(entry: second, place: 2, height: 80)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumSlot(entry: first, place: 1, height: 100)),
          const SizedBox(width: 8),
          if (third != null) Expanded(child: _PodiumSlot(entry: third, place: 3, height: 60)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place;
  final double height;

  const _PodiumSlot({
    required this.entry,
    required this.place,
    required this.height,
  });

  Color get _color {
    switch (place) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.darkSubtext;
    }
  }

  String get _medal {
    switch (place) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$place';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_medal, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: place == 1 ? 26 : 20,
          backgroundImage:
              entry.avatarUrl.isNotEmpty ? NetworkImage(entry.avatarUrl) : null,
          backgroundColor: AppTheme.brand,
        ),
        const SizedBox(height: 4),
        Text(
          entry.githubUsername,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: _color.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              '${entry.totalPoints}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final bool showWeeklyPoints;

  const _LeaderboardTile({
    required this.entry,
    required this.isMe,
    required this.showWeeklyPoints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = showWeeklyPoints ? entry.weeklyPoints : entry.totalPoints;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.brand.withOpacity(0.08)
            : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppTheme.brand.withOpacity(0.3)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: entry.rank <= 3 ? AppTheme.accent : null,
              ),
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage:
                entry.avatarUrl.isNotEmpty ? NetworkImage(entry.avatarUrl) : null,
            backgroundColor: AppTheme.brand,
            child: entry.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),

          // Name & level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.displayName.isNotEmpty
                          ? entry.displayName
                          : entry.githubUsername,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isMe ? AppTheme.brand : null,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.brand.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brand,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Lvl ${entry.level} · ${entry.streak > 0 ? '🔥 ${entry.streak}d' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${points}pts',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
