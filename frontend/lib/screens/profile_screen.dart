import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/level_progress_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: Column(
              children: [
                // Avatar + info
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? NetworkImage(user.avatarUrl)
                              : null,
                          backgroundColor: AppTheme.brand,
                          child: user.avatarUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lv.${user.level}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName.isNotEmpty
                                ? user.displayName
                                : user.githubUsername,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('@${user.githubUsername}'),
                          if (user.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.bio,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                            ),
                          ],
                          if (user.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: AppTheme.darkSubtext),
                                const SizedBox(width: 2),
                                Text(
                                  user.location,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Level progress
                LevelProgressBar(user: user),

                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Followers', value: '${user.followers}'),
                    _Divider(),
                    _StatItem(label: 'Repos', value: '${user.publicRepos}'),
                    _Divider(),
                    _StatItem(label: 'Total Commits', value: '${user.totalCommits}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Points breakdown
          _SectionCard(
            title: '📊 Stats Breakdown',
            child: Column(
              children: [
                _StatRow(label: 'Total Points', value: '${user.totalPoints}'),
                _StatRow(label: 'Weekly Points', value: '${user.weeklyPoints}'),
                _StatRow(label: 'Current Streak', value: '${user.streak} days 🔥'),
                _StatRow(
                    label: 'Longest Streak', value: '${user.longestStreak} days'),
                _StatRow(
                    label: 'Commits This Month', value: '${user.commitsThisMonth}'),
                _StatRow(
                    label: 'Commits This Week', value: '${user.commitsThisWeek}'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Achievements
          _SectionCard(
            title: '🏆 Achievements (${user.achievements.length})',
            child: user.achievements.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No achievements yet. Keep coding!',
                        style: TextStyle(color: AppTheme.darkSubtext),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: user.achievements.length,
                    itemBuilder: (_, i) {
                      final a = user.achievements[i];
                      return _AchievementCard(achievement: a);
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Settings
          _SectionCard(
            title: '⚙️ Settings',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync, color: AppTheme.brand),
                  title: const Text('Sync GitHub Data'),
                  subtitle: user.lastSyncedAt != null
                      ? Text(
                          'Last synced: ${_formatTime(user.lastSyncedAt!)}',
                          style: const TextStyle(fontSize: 11),
                        )
                      : null,
                  trailing: auth.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.brand,
                          ),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    final newAchievements = await auth.syncGitHub();
                    if (newAchievements.isNotEmpty && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '🏆 ${newAchievements.length} new achievement(s) unlocked!'),
                          backgroundColor: AppTheme.brand,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.open_in_browser, color: AppTheme.brand),
                  title: const Text('View on GitHub'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppTheme.danger),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.danger),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text(
                        'You will be redirected to the login screen.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.danger),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 32,
      width: 1,
      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: achievement.description,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.brand.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
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
