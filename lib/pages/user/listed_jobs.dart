import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/jobs_service.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/dashboard_nav_bar.dart';

/// Read-only view of advertised roles for the candidate. Tapping a job starts
/// the CV upload flow for that role.
class ListedJobs extends StatefulWidget {
  const ListedJobs({super.key});

  static const teal = Color(0xFF0D9488);
  static const border = Color(0xFFDBEFED);

  @override
  State<ListedJobs> createState() => _ListedJobsState();
}

class _ListedJobsState extends State<ListedJobs> {
  final _service = JobsService();
  final _auth = AuthService();
  late final StreamSubscription<AuthState> _authSubscription;

  Session? _session;
  List<Job> _jobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = _auth.session;
    _authSubscription = _auth.authChanges.listen(
      (state) {
        if (!mounted) return;
        setState(() => _session = state.session);
      },
      onError: (Object _) {},
    );
    _load();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await _service.fetchJobs();
      if (!mounted) return;
      setState(() => _jobs = jobs.where((j) => j.status == 'active').toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = JobsService.describeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/upload-cv');
      case 3:
        Navigator.pushReplacementNamed(context, '/applications');
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
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: DashboardNavBar(currentIndex: 1, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset('lib/assets/logo.png', height: 40),
                  const Spacer(),
                  if (_session == null)
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ListedJobs.teal,
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
                      child: const Text('Sign in'),
                    )
                  else
                    Tooltip(
                      message: _auth.displayName,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: ListedJobs.teal.withValues(alpha: 0.12),
                        child: Text(
                          _auth.displayName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ListedJobs.teal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Listed Jobs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(color: ListedJobs.teal),
        ),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          AuthErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(
              foregroundColor: ListedJobs.teal,
              side: const BorderSide(color: ListedJobs.teal),
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (_jobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Text(
          'No advertised jobs yet. Please check back later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Column(
      children: [
        for (final job in _jobs) ...[
          _JobListTile(
            job: job,
            onTap: () => Navigator.pushNamed(context, '/upload-cv'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _JobListTile extends StatelessWidget {
  const _JobListTile({required this.job, required this.onTap});

  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ListedJobs.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                job.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              job.status,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ListedJobs.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
