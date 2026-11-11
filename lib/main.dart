import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'pages/user/home_page.dart';
import 'pages/user/listed_jobs.dart';
import 'pages/user/sign_in.dart';
import 'pages/user/sign_up.dart';
import 'pages/user/upload_cv.dart';
import 'pages/admin/home_page.dart';
import 'pages/admin/jobs_page.dart';
import 'pages/admin/applications_page.dart';
import 'pages/admin/user_management_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _auth = AuthService();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authChanges.listen(
      _handleAuthChange,
      onError: _handleAuthError,
    );
  }

  // Google OAuth returns through a deep link, so navigation is driven by the
  // auth stream rather than by the pages that started the flow. The signed-in
  // user's role decides which journey they land on.
  void _handleAuthChange(AuthState state) async {
    final signedInNow = state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.initialSession;
    if (!signedInNow) return;
    final role = await _auth.fetchRole();
    final destination = role == 'recruiter' ? '/admin' : '/';
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(destination, (route) => false);
  }

  void _handleAuthError(Object error) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AuthService.describeError(error)),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/jobs': (context) => const _RequireAuth(child: ListedJobs()),
        '/admin': (context) =>
            const _RequireRole(role: 'recruiter', child: AdminHome()),
        '/admin-jobs': (context) =>
            const _RequireRole(role: 'recruiter', child: JobsPage()),
        '/admin-applications': (context) => const _RequireRole(
            role: 'recruiter', child: AdminApplications()),
        '/admin-users': (context) =>
            const _RequireRole(role: 'recruiter', child: UserManagement()),
        '/sign-up': (context) => const SignUpPage(),
        '/sign-in': (context) => const SignInPage(),
        '/upload-cv': (context) => const _RequireAuth(child: CvUpload()),
        '/applications': (context) => const _RequireAuth(child: MyApplications()),
      },
    );
  }
}

/// Gate for the institute-protected pages: candidates can browse the home page
/// signed out, but every other section requires an active session.
class _RequireAuth extends StatefulWidget {
  const _RequireAuth({required this.child});

  final Widget child;

  @override
  State<_RequireAuth> createState() => _RequireAuthState();
}

class _RequireAuthState extends State<_RequireAuth> {
  @override
  void initState() {
    super.initState();
    if (!AuthService().isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      AuthService().isSignedIn ? widget.child : const SizedBox.shrink();
}

/// Gate for the recruiter-only pages: requires an active session whose
/// `profiles.role` matches [role]. Signed-out users are sent to sign-in and
/// wrong-role users to the candidate home, so deep links cannot bypass it.
class _RequireRole extends StatefulWidget {
  const _RequireRole({required this.role, required this.child});

  final String role;
  final Widget child;

  @override
  State<_RequireRole> createState() => _RequireRoleState();
}

class _RequireRoleState extends State<_RequireRole> {
  bool _authorized = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final auth = AuthService();
    if (!auth.isSignedIn) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
      return;
    }
    final role = await auth.fetchRole();
    if (!mounted) return;
    if (role == widget.role) {
      setState(() {
        _authorized = true;
        _loading = false;
      });
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D9488)),
        ),
      );
    }
    return _authorized ? widget.child : const SizedBox.shrink();
  }
}
