import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/users_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_nav_bar.dart';

/// Recruiter directory of registered accounts, read live from Supabase's
/// `auth.users` table through the `admin_list_users()` function, with email
/// search and per-user edit/delete.
class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  static const teal = Color(0xFF0D9488);
  static const inputBorder = Color(0xFFD4ECEA);
  static const danger = Color(0xFFB91C1C);

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final _auth = AuthService();
  final _users = UsersService();
  final _searchController = TextEditingController();

  List<AppUser> _rows = const [];
  bool _isLoading = true;
  String? _error;
  String? _isDeleting;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _users.fetchUsers();
      if (!mounted) return;
      setState(() {
        _rows = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = UsersService.describeError(e);
        _isLoading = false;
      });
    }
  }

  List<AppUser> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((u) => u.email.toLowerCase().contains(q)).toList();
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin');
      case 1:
        Navigator.pushReplacementNamed(context, '/admin-jobs');
      case 2:
        Navigator.pushReplacementNamed(context, '/admin-applications');
      case 3:
        break;
      case 4:
        _signOut();
    }
  }

  Future<void> _signOut() async {
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
          backgroundColor: UserManagement.danger,
        ),
      );
    }
  }

  Future<void> _confirmDelete(AppUser user) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete user?',
      message: 'Remove ${user.name} from the directory.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    setState(() => _isDeleting = user.id);
    try {
      await _users.deleteUser(user.id);
      if (!mounted) return;
      setState(() {
        _rows = _rows.where((u) => u.id != user.id).toList();
        _isDeleting = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UsersService.describeError(e)),
          backgroundColor: UserManagement.danger,
        ),
      );
    }
  }

  String? get _currentUserId => _auth.user?.id;

  bool _isSelf(AppUser user) => user.id == _currentUserId;

  Future<void> _editEmail(AppUser user) async {
    final newEmail = await showDialog<String>(
      context: context,
      builder: (_) => _EmailEditDialog(initialEmail: user.email),
    );
    final trimmed = newEmail?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == user.email) return;
    try {
      await _users.updateUserEmail(user.id, trimmed);
      if (!mounted) return;
      setState(() {
        _rows = [
          for (final u in _rows)
            u.id == user.id
                ? AppUser(
                    id: u.id,
                    name: u.name,
                    email: trimmed,
                    role: u.role,
                    createdAt: u.createdAt,
                    lastActive: u.lastActive,
                  )
                : u,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email updated.'),
          backgroundColor: UserManagement.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UsersService.describeError(e)),
          backgroundColor: UserManagement.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: DashboardNavBar(currentIndex: 3, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                signedIn: true,
                displayName: _auth.displayName,
                teal: UserManagement.teal,
              ),
              const SizedBox(height: 12),
              const Text(
                'User Management',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildSearch(),
              const SizedBox(height: 24),
              _buildTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      cursorColor: UserManagement.teal,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search by email...',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UserManagement.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UserManagement.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UserManagement.teal, width: 2),
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: UserManagement.teal,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: UserManagement.danger),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(foregroundColor: UserManagement.teal),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final rows = _filtered;
    return Column(
      children: [
        _row(
          _cell('Name', flex: 3, bold: true),
          _cell('Email', flex: 4, bold: true),
          _cell('Last Active', flex: 3, bold: true),
          const SizedBox(width: 72),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _rows.isEmpty
                  ? 'No registered users yet.'
                  : 'No users match this search.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          )
        else
          for (final u in rows) ...[
            _row(
              _cell(u.name, flex: 3),
              _cell(u.email, flex: 4, underline: true),
              _cell(u.lastActiveLabel, flex: 3, color: Colors.grey.shade600),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _editEmail(u),
                    child: const Icon(Icons.edit_outlined,
                        size: 18, color: UserManagement.teal),
                  ),
                  const SizedBox(width: 12),
                  if (_isSelf(u))
                    // Protect the signed-in recruiter's own account from deletion.
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_outline,
                          size: 16, color: Colors.grey),
                    )
                  else
                    InkWell(
                      onTap: _isDeleting == u.id ? null : () => _confirmDelete(u),
                      child: _isDeleting == u.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: UserManagement.danger,
                              ),
                            )
                          : const Icon(Icons.delete_outline,
                              size: 18, color: UserManagement.danger),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  Widget _row(Widget a, Widget b, Widget c, Widget d) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [a, b, c, d]);
  }

  Widget _cell(
    String text, {
    required int flex,
    bool bold = false,
    bool underline = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? Colors.black87,
          decoration: underline ? TextDecoration.underline : null,
        ),
      ),
    );
  }
}

/// Owns its [TextEditingController] so the controller is disposed with the
/// dialog element, not by the caller after pop (which trips the framework's
/// `_dependents.isEmpty` assertion).
class _EmailEditDialog extends StatefulWidget {
  const _EmailEditDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EmailEditDialog> createState() => _EmailEditDialogState();
}

class _EmailEditDialogState extends State<_EmailEditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Edit email',
          style: TextStyle(fontSize: 17, color: Colors.black87)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        cursorColor: UserManagement.teal,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: const TextStyle(color: Colors.grey),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: UserManagement.teal, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _controller.text.trim()),
          style: FilledButton.styleFrom(
            backgroundColor: UserManagement.teal,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
