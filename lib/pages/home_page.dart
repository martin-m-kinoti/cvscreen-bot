import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _teal = Color(0xFF0D9488);
  static const _checkGreen = Color(0xFF0EBF00);

  static const _steps = [
    'Sign in',
    'Navigate to CV Screening page',
    'Upload CV',
    'CV analyzed',
    'Get status',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset('lib/assets/logo.png', height: 40),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sign-in'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('Sign in'),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/cv-screen'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('Start Screening'),
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
                            style: TextStyle(color: _teal),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Upload CVs, let AI analyze and rate candidates against your '
                      'job requirements. Recognizes Kenyan educational institutions '
                      'with smart matching.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.black87,
                      ),
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
                          for (var i = 0; i < _steps.length; i++)
                            _StepTile(
                              label: _steps[i],
                              isLast: i == _steps.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _ContactFooter(),
              ),
            ),
          ],
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

class _ContactFooter extends StatelessWidget {
  const _ContactFooter();

  // Placeholder contact details — replace with the real values.
  static const _website = 'cvscreening.vercel.app';
  static const _email = 'cvscreening@example.co.ke';
  static const _phone = '+254 7XX XXX XXX';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: HomePage._teal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Contact',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _contactRow(
            const Icon(Icons.language, size: 18, color: Colors.black87),
            _website,
          ),
          const SizedBox(height: 10),
          _contactRow(
            const Icon(Icons.email, size: 18, color: Color(0xFFEA4335)),
            _email,
            underlined: true,
          ),
          const SizedBox(height: 10),
          _contactRow(
            const CircleAvatar(
              radius: 9,
              backgroundColor: Color(0xFF25D366),
              child: Icon(Icons.phone, size: 11, color: Colors.white),
            ),
            _phone,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '© 2026 CVScreen AI. All rights reserved.',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(Widget icon, String text, {bool underlined = false}) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              decoration: underlined ? TextDecoration.underline : null,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
