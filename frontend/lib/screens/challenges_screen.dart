import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/challenge_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  List<Challenge> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _loading = true);
    try {
      final challenges = await ApiService.getChallenges();
      if (mounted) setState(() {
        _challenges = challenges;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateChallengeSheet(
        onCreated: (c) {
          setState(() => _challenges.insert(0, c));
        },
      ),
    );
  }

  void _showJoinByCodeDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join by Invite Code'),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter 6-character code',
            prefixIcon: Icon(Icons.vpn_key),
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.joinChallengeByCode(codeCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadChallenges();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joined challenge!'),
                      backgroundColor: AppTheme.brand,
                    ),
                  );
                }
              } on ApiException catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _challenges.where((c) => c.isActive).toList();
    final upcoming = _challenges.where((c) => c.isUpcoming).toList();
    final completed = _challenges.where((c) => c.isCompleted).toList();

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join_code',
            onPressed: _showJoinByCodeDialog,
            backgroundColor: AppTheme.darkCard,
            child: const Icon(Icons.vpn_key, color: AppTheme.brand),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _showCreateDialog,
            backgroundColor: AppTheme.brand,
            child: const Icon(Icons.add, color: AppTheme.darkBg),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : RefreshIndicator(
              onRefresh: _loadChallenges,
              color: AppTheme.brand,
              child: CustomScrollView(
                slivers: [
                  if (active.isNotEmpty) ...[
                    _SectionHeader(title: '⚡ Active (${active.length})'),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ChallengeTile(
                          challenge: active[i],
                          onJoin: _loadChallenges,
                          onLeave: _loadChallenges,
                        ),
                        childCount: active.length,
                      ),
                    ),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(title: '🕐 Upcoming (${upcoming.length})'),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ChallengeTile(
                          challenge: upcoming[i],
                          onJoin: _loadChallenges,
                          onLeave: _loadChallenges,
                        ),
                        childCount: upcoming.length,
                      ),
                    ),
                  ],
                  if (completed.isNotEmpty) ...[
                    _SectionHeader(title: '✅ Completed (${completed.length})'),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ChallengeTile(
                          challenge: completed[i],
                          onJoin: _loadChallenges,
                          onLeave: _loadChallenges,
                        ),
                        childCount: completed.length,
                      ),
                    ),
                  ],
                  if (_challenges.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('⚔️', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            const Text(
                              'No challenges yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create one or join with an invite code',
                              style: TextStyle(color: AppTheme.darkSubtext),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _ChallengeTile({
    required this.challenge,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topParticipant =
        challenge.participants.isNotEmpty ? challenge.participants.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: challenge.isParticipant
              ? AppTheme.brand.withOpacity(0.4)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                challenge.typeIcon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'by @${challenge.creatorUsername} · ${challenge.participants.length} participants',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: challenge.status),
            ],
          ),

          const SizedBox(height: 12),

          // Goal info
          Row(
            children: [
              _InfoChip(label: 'Goal', value: '${challenge.goal} ${challenge.typeLabel}'),
              const SizedBox(width: 8),
              _InfoChip(label: 'Duration', value: '${challenge.duration}d'),
              const SizedBox(width: 8),
              if (challenge.isActive)
                _InfoChip(
                  label: 'Ends',
                  value: _formatDuration(challenge.remaining),
                  color: AppTheme.accent,
                ),
            ],
          ),

          if (challenge.isParticipant && topParticipant != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('🥇', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${topParticipant.displayName.isNotEmpty ? topParticipant.displayName : topParticipant.githubUsername} · ${topParticipant.progress} ${challenge.typeLabel}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              if (challenge.inviteCode != null && challenge.isParticipant)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: challenge.inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 12, color: AppTheme.brand),
                        const SizedBox(width: 4),
                        Text(
                          challenge.inviteCode!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brand,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (!challenge.isParticipant && !challenge.isCompleted)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.joinChallenge(challenge.id);
                      onJoin();
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Join', style: TextStyle(fontSize: 13)),
                )
              else if (challenge.isParticipant && !challenge.isCompleted)
                TextButton(
                  onPressed: () async {
                    await ApiService.leaveChallenge(challenge.id);
                    onLeave();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Leave', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Ended';
    if (d.inDays > 0) return '${d.inDays}d left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = AppTheme.brand;
        label = 'LIVE';
        break;
      case 'upcoming':
        color = AppTheme.accent;
        label = 'SOON';
        break;
      default:
        color = AppTheme.darkSubtext;
        label = 'ENDED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1117)
            : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppTheme.darkSubtext)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateChallengeSheet extends StatefulWidget {
  final void Function(Challenge) onCreated;

  const _CreateChallengeSheet({required this.onCreated});

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'commit_count';
  int _goal = 50;
  int _duration = 7;
  bool _isPublic = true;
  bool _creating = false;

  final _types = [
    ('commit_count', '📝 Commit Count'),
    ('streak', '🔥 Streak'),
    ('points', '⭐ Points'),
    ('repo_count', '📁 Repos'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Challenge ⚔️',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Challenge Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                return ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  onSelected: (_) => setState(() => _type = t.$1),
                  selectedColor: AppTheme.brand.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _type == t.$1 ? AppTheme.brand : null,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goal: $_goal',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _goal.toDouble(),
                        min: 1,
                        max: 500,
                        divisions: 49,
                        activeColor: AppTheme.brand,
                        onChanged: (v) => setState(() => _goal = v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration: ${_duration}d',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _duration.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: AppTheme.brand,
                        onChanged: (v) => setState(() => _duration = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Public Challenge'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              activeColor: AppTheme.brand,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating
                    ? null
                    : () async {
                        if (_nameCtrl.text.trim().isEmpty) return;
                        setState(() => _creating = true);
                        try {
                          final c = await ApiService.createChallenge(
                            name: _nameCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            type: _type,
                            goal: _goal,
                            duration: _duration,
                            isPublic: _isPublic,
                          );
                          widget.onCreated(c);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to create challenge'),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _creating = false);
                        }
                      },
                child: _creating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
