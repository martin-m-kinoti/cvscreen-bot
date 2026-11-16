/// A registered account shown in the recruiter User Management directory.
/// Populated from the `admin_list_users()` database function, which reads
/// Supabase's `auth.users` table on behalf of a signed-in recruiter.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastActive,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastActive;

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        name: (map['name'] as String?)?.trim().isNotEmpty == true
            ? (map['name'] as String).trim()
            : 'Unnamed user',
        email: (map['email'] as String?) ?? '',
        role: (map['role'] as String?) ?? 'candidate',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
        lastActive: DateTime.tryParse(map['last_active'] as String? ?? ''),
      );

  /// Human-friendly "last active" label used in the directory table.
  String get lastActiveLabel {
    final value = lastActive;
    if (value == null) return 'Never';
    final local = value.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return _formatDate(local);
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
