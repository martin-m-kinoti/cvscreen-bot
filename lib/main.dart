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
import 'pages/admin/jobs_page.dart';

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
  // auth stream rather than by the pages that started the flow.
  void _handleAuthChange(AuthState state) {
    if (state.event == AuthChangeEvent.signedIn) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    }
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
        '/admin-jobs': (context) => const _RequireAuth(child: JobsPage()),
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
