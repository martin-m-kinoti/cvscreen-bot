import 'package:flutter/material.dart';

/// Logo plus the signed-in avatar initial, or (when signed out) a Sign in text
/// button and an optional teal Apply button. Shared by the dashboard pages.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.signedIn,
    required this.displayName,
    required this.teal,
    this.onSignIn,
    this.onApply,
  });

  final bool signedIn;
  final String displayName;
  final Color teal;
  final VoidCallback? onSignIn;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('lib/assets/logo.png', height: 40),
        const Spacer(),
        if (!signedIn) ...[
          if (onSignIn != null)
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Sign in'),
            ),
          if (onApply != null) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: teal,
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
              child: const Text('Apply'),
            ),
          ],
        ] else
          Tooltip(
            message: displayName,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: teal.withValues(alpha: 0.12),
              child: Text(
                displayName.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: teal,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
