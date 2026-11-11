import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/application.dart';
import '../models/job.dart';
import '../services/applications_service.dart';
import '../services/auth_service.dart';
import '../services/jobs_service.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/dashboard_nav_bar.dart';

/// Candidate journey: upload a CV against an advertised job, then review the
/// match result. Shared teal/border palette with the rest of the dashboard.
class CvUpload extends StatefulWidget {
  const CvUpload({super.key});

  static const teal = Color(0xFF0D9488);
  static const border = Color(0xFFDBEFED);
  static const inputBorder = Color(0xFFD4ECEA);
  static const maxCvBytes = 5 * 1024 * 1024;

  @override
  State<CvUpload> createState() => _CvUploadState();
}

class _CvUploadState extends State<CvUpload> {
  final _jobsService = JobsService();
  final _applications = ApplicationsService();
  final _auth = AuthService();

  List<Job> _jobs = [];
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;

  Job? _selectedJob;
  PlatformFile? _cvFile;
  int? _cvSize;

  String? _listError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _listError = null;
    });
    try {
      final jobs = await _jobsService.fetchJobs();
      if (!mounted) return;
      setState(() => _jobs = jobs.where((j) => j.status == 'active').toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _listError = JobsService.describeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return;
    if (file.extension?.toLowerCase() != 'pdf') {
      setState(() => _formError = 'Only PDF files are supported.');
      return;
    }
    final size = file.lengthSync() ?? await file.length();
    if (size != null && size > CvUpload.maxCvBytes) {
      setState(() => _formError = 'The CV must be 5 MB or smaller.');
      return;
    }
    setState(() {
      _cvFile = file;
      _cvSize = size;
      _formError = null;
    });
  }

  Future<void> _apply() async {
    if (_submitting) return;
    if (_selectedJob == null) {
      setState(() => _formError = 'Choose a job to apply for.');
      return;
    }
    if (_cvFile == null) {
      setState(() => _formError = 'Attach your CV (PDF).');
      return;
    }
    final userId = _auth.user?.id;
    if (userId == null) {
      setState(() => _formError = 'Please sign in before applying.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final job = _selectedJob!;
      final bytes = await _cvFile!.readAsBytes();
      final draft = Application(
        id: '',
        jobId: job.id,
        jobTitle: job.title,
        applicantId: userId,
        cvFileName: _cvFile!.name,
        createdAt: DateTime.now(),
      );
      await _applications.submitApplication(
        application: draft,
        cvBytes: bytes,
      );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = ApplicationsService.describeError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
      case 1:
        Navigator.pushReplacementNamed(context, '/jobs');
      case 2:
        break;
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
      bottomNavigationBar: DashboardNavBar(currentIndex: 2, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('lib/assets/logo.png', height: 40),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload CV',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              if (_submitted)
                const _SuccessNotice()
              else ...[
                const Text(
                  'Upload your CV (PDF) to apply',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                if (_formError != null) ...[
                  AuthErrorBanner(
                    message: _formError!,
                    onDismiss: () => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildJobSelector(),
                const SizedBox(height: 16),
                _buildDropZone(),
                const SizedBox(height: 20),
                Center(child: _buildApplyButton()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: CvUpload.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Job to apply for *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(color: CvUpload.teal),
            )
          else if (_listError != null)
            AuthErrorBanner(
              message: _listError!,
              onDismiss: () => setState(() => _listError = null),
            )
          else if (_jobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No advertised jobs yet. Please check back later.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedJob?.id ?? 'choose'),
              initialValue: _selectedJob?.id,
              isExpanded: true,
              hint: const Text(
                'Choose a job…',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              icon: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CvUpload.teal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: [
                for (final job in _jobs)
                  DropdownMenuItem(value: job.id, child: Text(job.title)),
              ],
              onChanged: (value) => setState(() {
                _selectedJob = _jobs.firstWhere((j) => j.id == value);
                _formError = null;
              }),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CvUpload.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CvUpload.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CvUpload.teal, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _DashedBorder(color: CvUpload.teal.withValues(alpha: 0.5)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: CvUpload.teal.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                _cvFile == null ? Icons.upload_outlined : Icons.description_outlined,
                size: 30,
                color: CvUpload.teal,
              ),
              const SizedBox(height: 12),
              Text(
                _cvFile == null
                    ? 'Drag & drop your cv here, or\nclick to browse'
                    : _cvFile!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cvFile == null
                    ? 'Supports PDF files only up to 5mb'
                    : _cvSize == null
                        ? 'PDF selected · tap to change'
                        : '${(_cvSize! / 1024).toStringAsFixed(0)} KB · tap to change',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return FilledButton(
      onPressed: _submitting ? null : _apply,
      style: FilledButton.styleFrom(
        backgroundColor: CvUpload.teal,
        disabledBackgroundColor: CvUpload.teal.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: _submitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Apply'),
    );
  }
}

/// Post-submit screen shown in place of the form.
class _SuccessNotice extends StatelessWidget {
  const _SuccessNotice();

  @override
  Widget build(BuildContext context) {
    const lines = [
      'Your application has been made successfully',
      'Check your email for confirmation and feedback',
      'Thank you',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          for (final line in lines) ...[
            Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: CvUpload.teal,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// The candidate's applications with the backend match verdict.
class MyApplications extends StatefulWidget {
  const MyApplications({super.key});

  static const teal = CvUpload.teal;
  static const border = CvUpload.border;

  @override
  State<MyApplications> createState() => _MyApplicationsState();
}

class _MyApplicationsState extends State<MyApplications> {
  final _applications = ApplicationsService();
  final _auth = AuthService();

  List<Application> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final userId = _auth.user?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Please sign in to view your applications.';
      });
      return;
    }
    try {
      final items = await _applications.fetchApplications(userId);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApplicationsService.describeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
      case 1:
        Navigator.pushReplacementNamed(context, '/jobs');
      case 2:
        Navigator.pushReplacementNamed(context, '/upload-cv');
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
          backgroundColor: const Color(0xFFB91C1C),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('lib/assets/logo.png', height: 40),
              ),
              const SizedBox(height: 12),
              const Text(
                'My Applications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
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
          child: CircularProgressIndicator(color: MyApplications.teal),
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
              foregroundColor: MyApplications.teal,
              side: const BorderSide(color: MyApplications.teal),
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Text(
          'You have not applied to any jobs yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Column(
      children: [
        for (final item in _items) ...[
          _ApplicationCard(application: item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final isMatch = application.status == 'match';
    final label = switch (application.status) {
      'match' => 'Match',
      'no_match' => 'Not a match',
      _ => 'Under review',
    };
    final color = switch (application.status) {
      'match' => MyApplications.teal,
      'no_match' => const Color(0xFFB91C1C),
      _ => Colors.grey.shade600,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: MyApplications.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              application.jobTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isMatch ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded dashed outline for the CV drop area.
class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final radius = const Radius.circular(8);
    final rect = Offset.zero & size;
    const dash = 6.0;
    const gap = 4.0;
    _drawDashedRRect(canvas, paint, rect, radius, dash, gap);
  }

  static void _drawDashedRRect(
    Canvas canvas,
    Paint paint,
    Rect rect,
    Radius radius,
    double dash,
    double gap,
  ) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(paint.strokeWidth / 2), radius),
      );
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) =>
      oldDelegate.color != color;
}
