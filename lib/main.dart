import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'pages/cv_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/sign-in',
      routes: {
        '/': (context) => const HomePage(),
        '/sign-up': (context) => const SignUpPage(),
        '/sign-in': (context) => const SignInPage(),
        '/cv-screen': (context) => const CvScreenPage(),
      },
    );
  }
}