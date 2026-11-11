import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/dashboard_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const _teal = Color(0xFF0D9488);
  static const _checkGreen = Color(0xFF0EBF00);

  static const _steps = [
    'Sign in',
    'Navigate to CV Screening page',
    'Upload CV',
    'CV analyzed',
    'Get status and feedback',
    'Review recent applications',
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = AuthService();
  late final StreamSubscription<AuthState> _authSubscription;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = _auth.session;
    _authSubscription = _auth.authChanges.listen(
      (state) {
        if (!mounted) return;
        setState(() => _session = state.session);
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _session = _auth.session);
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/jobs');
      case 2:
        Navigator.pushReplacementNamed(context, '/upload-cv');
      case 3:
        Navigator.pushReplacementNamed(context, '/applications');
      case 4:
        _signOutFromNav();
    }
  }

  Future<void> _signOutFromNav() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !mounted) return;
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.describeError(e)),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: DashboardNavBar(currentIndex: 0, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset('lib/assets/logo.png', height: 40),
                  const Spacer(),
                  if (_session == null)
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                      style: FilledButton.styleFrom(
                        backgroundColor: HomePage._teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Sign in'),
                    )
                  else
                    Tooltip(
                      message: _auth.displayName,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: HomePage._teal.withValues(alpha: 0.12),
                        child: Text(
                          _auth.displayName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HomePage._teal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'CV ',
                      style: TextStyle(color: Colors.black87),
                    ),
                    TextSpan(
                      text: 'Screen',
                      style: TextStyle(
                        color: HomePage._teal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              const Text(
                'Apply by uploading your CV, let AI analyze and rate it against '
                'the job requirements. Recognizes Kenyan educational institutions '
                'with smart matching.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 28),
              const Text(
                'Getting Started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (var i = 0; i < HomePage._steps.length; i++)
                      _StepTile(
                        label: HomePage._steps[i],
                        isLast: i == HomePage._steps.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.label, required this.isLast});

  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isLast ? 30 : 62,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 28,
                  color: HomePage._checkGreen,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
