import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/level_progress_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _chartMode7 = true; // 7 days vs 30 days
  List<String> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final insights = await ApiService.getInsights();
      if (mounted) setState(() => _insights = insights);
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    final auth = context.read<AuthProvider>();
    final newAchievements = await auth.syncGitHub();
    if (newAchievements.isNotEmpty && mounted) {
      _showAchievementDialog(newAchievements);
    }
  }

  void _showAchievementDialog(List<dynamic> achievements) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🏆 New Achievement!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((a) {
            final ach = a as Map<String, dynamic>;
            return ListTile(
              leading: Text(ach['icon'] ?? '🏆', style: const TextStyle(fontSize: 28)),
              title: Text(ach['name'] ?? ''),
              subtitle: Text(ach['description'] ?? ''),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildChartData(User user) {
    final days = _chartMode7 ? 7 : 30;
    final stats = user.dailyStats.length > days
        ? user.dailyStats.sublist(user.dailyStats.length - days)
        : user.dailyStats;

    if (stats.isEmpty) return [const FlSpot(0, 0)];

    return stats.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.commits.toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
    }

    final spots = _buildChartData(user);
    final maxY = spots.isEmpty ? 10.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.brand,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                  backgroundColor: AppTheme.brand,
                  child: user.avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, ${user.displayName.split(' ').first} 👋',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '@${user.githubUsername}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (auth.isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.brand,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sync, color: AppTheme.brand),
                    onPressed: _onRefresh,
                    tooltip: 'Sync GitHub',
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Level Progress
            LevelProgressBar(user: user),

            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total Points',
                    value: '${user.totalPoints}',
                    icon: '⭐',
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Streak',
                    value: '${user.streak} days',
                    icon: '🔥',
                    color: AppTheme.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'This Week',
                    value: '${user.commitsThisWeek} commits',
                    icon: '📝',
                    color: AppTheme.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Repos',
                    value: '${user.publicRepos}',
                    icon: '📁',
                    color: AppTheme.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Commit Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commit Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      _ChartToggleButton(
                        label: '7D',
                        selected: _chartMode7,
                        onTap: () => setState(() => _chartMode7 = true),
                      ),
                      _ChartToggleButton(
                        label: '30D',
                        selected: !_chartMode7,
                        onTap: () => setState(() => _chartMode7 = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              height: 180,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                        'No commit data yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: isDark
                                ? AppTheme.darkBorder.withOpacity(0.5)
                                : AppTheme.lightBorder.withOpacity(0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.brand,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: AppTheme.brand,
                                strokeWidth: 0,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.brand.withOpacity(0.3),
                                  AppTheme.brand.withOpacity(0.01),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Insights
            if (_insights.isNotEmpty) ...[
              Text(
                'Insights ✨',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._insights.map(
                (insight) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.brand.withOpacity(0.2)),
                  ),
                  child: Text(
                    insight,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Achievements preview
            if (user.achievements.isNotEmpty) ...[
              Text(
                'Recent Achievements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: user.achievements.length.clamp(0, 8),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final a = user.achievements[user.achievements.length - 1 - i];
                    return _AchievementChip(achievement: a);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChartToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.darkBg : AppTheme.darkSubtext,
          ),
        ),
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final Achievement achievement;

  const _AchievementChip({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: '${achievement.name}: ${achievement.description}',
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
