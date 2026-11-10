import 'package:flutter/material.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: const Color(0xFFB91C1C),
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
