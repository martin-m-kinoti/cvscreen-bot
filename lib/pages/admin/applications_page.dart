import 'package:flutter/material.dart';
import '../../models/applicant.dart';
import '../../models/job.dart';
import '../../services/applications_service.dart';
import '../../services/auth_service.dart';
import '../../services/jobs_service.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_nav_bar.dart';

/// Recruiter view of the applicants screened against a chosen role, with a
/// minimum-score filter. Both the job list and the applicant rows are read
/// live from Supabase.
class AdminApplications extends StatefulWidget {
  const AdminApplications({super.key});

  static const teal = Color(0xFF0D9488);
  static const border = Color(0xFFDBEFED);
  static const inputBorder = Color(0xFFD4ECEA);
  static const danger = Color(0xFFB91C1C);
  static const amber = Color(0xFFB45309);

  @override
  State<AdminApplications> createState() => _AdminApplicationsState();
}

class _AdminApplicationsState extends State<AdminApplications> {
  final _auth = AuthService();
  final _jobsService = JobsService();
  final _applications = ApplicationsService();
  final _scoreController = TextEditingController();

  List<Job> _jobs = [];
  bool _jobsLoading = true;
  String? _jobsError;
  String? _selectedJobId;

  List<Applicant> _applicants = [];
  bool _applicantsLoading = false;
  String? _applicantsError;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  String? get _selectedJobTitle {
    if (_selectedJobId == null) return null;
    final job = _jobs.where((j) => j.id == _selectedJobId);
    return job.isEmpty ? null : job.first.title;
  }

  Future<void> _loadJobs() async {
    setState(() {
      _jobsLoading = true;
      _jobsError = null;
    });
    try {
      final jobs = await _jobsService.fetchJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _selectedJobId = jobs.isEmpty ? null : jobs.first.id;
      });
      _loadApplicants();
    } catch (e) {
      if (!mounted) return;
      setState(() => _jobsError = JobsService.describeError(e));
    } finally {
      if (mounted) setState(() => _jobsLoading = false);
    }
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _applicantsLoading = true;
      _applicantsError = null;
    });
    try {
      final applicants =
          await _applications.fetchApplicants(jobTitle: _selectedJobTitle);
      if (!mounted) return;
      setState(() => _applicants = applicants);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applicantsError = ApplicationsService.describeError(e));
    } finally {
      if (mounted) setState(() => _applicantsLoading = false);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin');
      case 1:
        Navigator.pushReplacementNamed(context, '/admin-jobs');
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/admin-users');
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
          backgroundColor: AdminApplications.danger,
        ),
      );
    }
  }

  List<Applicant> get _filtered {
    final min = int.tryParse(_scoreController.text.trim());
    if (min == null) return _applicants;
    return _applicants.where((a) => a.score >= min).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: DashboardNavBar(currentIndex: 2, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                signedIn: true,
                displayName: _auth.displayName,
                teal: AdminApplications.teal,
              ),
              const SizedBox(height: 12),
              const Text(
                'Applications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildJobSelector(),
              const SizedBox(height: 16),
              _buildScoreFilter(),
              const SizedBox(height: 24),
              _buildTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobSelector() {
    if (_jobsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(color: AdminApplications.teal),
      );
    }
    if (_jobsError != null) {
      return Column(
        children: [
          AuthErrorBanner(
            message: _jobsError!,
            onDismiss: () => setState(() => _jobsError = null),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadJobs,
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminApplications.teal,
              side: const BorderSide(color: AdminApplications.teal),
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (_jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AdminApplications.inputBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No jobs yet. Create one from the Jobs tab.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AdminApplications.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedJobId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            for (final job in _jobs)
              DropdownMenuItem(value: job.id, child: Text(job.title)),
          ],
          onChanged: (value) {
            setState(() => _selectedJobId = value);
            _loadApplicants();
          },
        ),
      ),
    );
  }

  Widget _buildScoreFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AdminApplications.inputBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Filter by score',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            cursorColor: AdminApplications.teal,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: AdminApplications.teal),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminApplications.teal),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminApplications.teal),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: AdminApplications.teal, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_applicantsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AdminApplications.teal,
            ),
          ),
        ),
      );
    }
    if (_applicantsError != null) {
      return Column(
        children: [
          AuthErrorBanner(
            message: _applicantsError!,
            onDismiss: () => setState(() => _applicantsError = null),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadApplicants,
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminApplications.teal,
              side: const BorderSide(color: AdminApplications.teal),
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    final rows = _filtered;
    return Column(
      children: [
        _tableRow(
          _cell('Name', flex: 3, bold: true),
          _cell('Email', flex: 4, bold: true),
          _cell('Score (%)', flex: 2, bold: true),
          _cell('Status', flex: 2, bold: true),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No applicants to show yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          )
        else
          for (final a in rows) ...[
            _tableRow(
              _cell(a.name, flex: 3),
              _cell(a.email, flex: 4, underline: true),
              _cell('${a.score}', flex: 2, color: _statusColor(a)),
              _cell(_statusLabel(a), flex: 2, color: _statusColor(a)),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  static Color _statusColor(Applicant a) => switch (a.status) {
        'Strong Match' => AdminApplications.teal,
        'Possible Match' => AdminApplications.amber,
        'Not a Match' => AdminApplications.danger,
        _ => Colors.grey.shade600,
      };

  static String _statusLabel(Applicant a) =>
      a.isPending ? 'Under review' : a.status;

  Widget _tableRow(Widget a, Widget b, Widget c, Widget d) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [a, b, c, d]);
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
