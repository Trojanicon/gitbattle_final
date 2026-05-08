import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'friends_screen.dart';
import 'challenges_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    LeaderboardScreen(),
    FriendsScreen(),
    ChallengesScreen(),
    ProfileScreen(),
  ];

  final _labels = ['Home', 'Rank', 'Friends', 'Battles', 'Profile'];
  final _icons = [
    Icons.home_outlined,
    Icons.leaderboard_outlined,
    Icons.people_outline,
    Icons.sports_esports_outlined,
    Icons.person_outline,
  ];
  final _activeIcons = [
    Icons.home,
    Icons.leaderboard,
    Icons.people,
    Icons.sports_esports,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              '⚔️',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Git',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: GoogleFonts.syne().fontFamily,
                      color: AppTheme.brand,
                    ),
                  ),
                  TextSpan(
                    text: 'Battle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: GoogleFonts.syne().fontFamily,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
            ),
            onPressed: () {
              // ThemeMode toggle handled in main.dart via provider
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: List.generate(
            5,
            (i) => BottomNavigationBarItem(
              icon: Icon(_icons[i]),
              activeIcon: Icon(_activeIcons[i]),
              label: _labels[i],
            ),
          ),
        ),
      ),
    );
  }
}
