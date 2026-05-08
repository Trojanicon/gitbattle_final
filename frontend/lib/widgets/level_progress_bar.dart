import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class LevelProgressBar extends StatelessWidget {
  final User user;

  const LevelProgressBar({super.key, required this.user});

  String _levelTitle(int level) {
    const titles = [
      'Newbie', 'Apprentice', 'Developer', 'Coder', 'Hacker',
      'Engineer', 'Architect', 'Wizard', 'Grandmaster', 'Legend',
    ];
    if (level <= 0 || level > titles.length) return 'Legend';
    return titles[level - 1];
  }

  @override
  Widget build(BuildContext context) {
    final progress = user.levelProgress;
    final nextPoints = user.nextLevelPoints;
    final currentPoints = user.totalPoints;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.purple.withOpacity(0.12),
            AppTheme.brand.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Level ${user.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _levelTitle(user.level),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.purple,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentPoints / $nextPoints pts',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.purple),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${((1 - progress) * (nextPoints - user.currentLevelMin)).round()} pts to next level',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
