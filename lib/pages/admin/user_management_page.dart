import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_nav_bar.dart';

/// Recruiter directory of registered candidates with email search and
/// per-user edit/delete. Sample rows stand in until the users backend is linked.
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
  final _searchController = TextEditingController();

  // Populated by the users backend.
  final List<_UserRow> _users = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_UserRow> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) => u.email.toLowerCase().contains(q)).toList();
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

  Future<void> _confirmDelete(_UserRow user) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete user?',
      message: 'Remove ${user.name} from the directory.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    setState(() => _users.removeWhere((u) => u.email == user.email));
  }

  void _onEdit(_UserRow user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${user.name} is coming soon.')),
    );
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No users match this search.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          )
        else
          for (final u in rows) ...[
            _row(
              _cell(u.name, flex: 3),
              _cell(u.email, flex: 4, underline: true),
              _cell(u.lastActive, flex: 3, color: Colors.grey.shade600),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _onEdit(u),
                    child: const Icon(Icons.edit_outlined,
                        size: 18, color: UserManagement.teal),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _confirmDelete(u),
                    child: const Icon(Icons.delete_outline,
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

class _UserRow {
  const _UserRow(this.name, this.email, this.lastActive);
  final String name;
  final String email;
  final String lastActive;
}
