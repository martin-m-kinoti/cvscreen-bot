import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'pages/home_page.dart';
import 'pages/jobs_page.dart';
import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'pages/cv_screen.dart';
import 'pages/jobs_page.dart';

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
        '/jobs': (context) => const JobsPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/sign-in': (context) => const SignInPage(),
        '/cv-screen': (context) => const CvScreenPage(),
        '/jobs': (context) => const JobsPage(),
      },
    );
  }
}
