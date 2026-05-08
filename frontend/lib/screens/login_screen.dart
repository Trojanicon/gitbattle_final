import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  static const String _githubClientId = 'YOUR_GITHUB_CLIENT_ID';
  static const String _redirectUri = 'gitbattle://auth/callback';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGitHub() async {
    setState(() => _isLoading = true);

    final params = Uri(
      scheme: 'https',
      host: 'github.com',
      path: '/login/oauth/authorize',
      queryParameters: {
        'client_id': _githubClientId,
        'redirect_uri': _redirectUri,
        'scope': 'read:user user:email repo',
        'state': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      await launchUrl(params, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open GitHub: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0D1117),
                        const Color(0xFF0D2137),
                        const Color(0xFF0D1117),
                      ]
                    : [
                        const Color(0xFFF0FDF4),
                        const Color(0xFFECFDF5),
                        const Color(0xFFF0FDF4),
                      ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.brand.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purple.withOpacity(0.06),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo / Hero
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    ),
                    child: Column(
                      children: [
                        // App icon
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.brand, AppTheme.brandDark],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brand.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '⚔️',
                              style: TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'GitBattle',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: AppTheme.brand,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commit Clash',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Tagline cards
                  _FeatureRow(
                    icon: '🔥',
                    text: 'Track your commit streaks',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: '🏆',
                    text: 'Compete on leaderboards',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: '⚡',
                    text: 'Earn XP for every commit',
                    isDark: isDark,
                  ),

                  const Spacer(flex: 2),

                  // GitHub login button
                  _isLoading
                      ? const CircularProgressIndicator(color: AppTheme.brand)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loginWithGitHub,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  isDark ? const Color(0xFF21262D) : const Color(0xFF24292F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '',
                                  style: TextStyle(fontSize: 22),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Login with GitHub',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: GoogleFonts.syne().fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                  const SizedBox(height: 16),

                  Text(
                    'By signing in you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String text;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCard.withOpacity(0.6)
            : AppTheme.lightCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
