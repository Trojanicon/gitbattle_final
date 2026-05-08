import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const GitBattleApp(),
    ),
  );
}

class GitBattleApp extends StatefulWidget {
  const GitBattleApp({super.key});

  @override
  State<GitBattleApp> createState() => _GitBattleAppState();
}

class _GitBattleAppState extends State<GitBattleApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep link that opened the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Listen for deep links while app is open
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) => debugPrint('Deep link error: $err'),
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link: $uri');

    // gitbattle://auth/callback?token=...&username=...
    if (uri.path == '/auth/callback') {
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        debugPrint('OAuth error: $error');
        return;
      }

      if (token != null) {
        // Token-based auth (server-side OAuth flow)
        _handleTokenCallback(token);
      }

      // code-based auth (mobile OAuth flow)
      final code = uri.queryParameters['code'];
      if (code != null) {
        context.read<AuthProvider>().loginWithCode(code);
      }
    }
  }

  Future<void> _handleTokenCallback(String token) async {
    // Save token and re-fetch user
    final auth = context.read<AuthProvider>();
    // Manually set token then reload user
    await _saveTokenAndLoad(token);
  }

  Future<void> _saveTokenAndLoad(String token) async {
    // This would be called after server-side OAuth
    // The token is saved and user profile fetched
    debugPrint('Token received: ${token.substring(0, 10)}...');
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitBattle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⚔️', style: TextStyle(fontSize: 56)),
                SizedBox(height: 16),
                Text(
                  'GitBattle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brand,
                    fontFamily: GoogleFonts.syne().fontFamily,
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(color: AppTheme.brand),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
