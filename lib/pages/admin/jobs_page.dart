import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/jobs_service.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/dashboard_nav_bar.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  static const _teal = Color(0xFF0D9488);
  static const _border = Color(0xFFDBEFED);

  static const _educationOptions = [
    'Certificate',
    'Diploma',
    "Bachelor's Degree",
    "Master's Degree",
    'Doctorate (PhD)',
    'Any',
  ];

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final _service = JobsService();
  final _auth = AuthService();

  final _titleController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _additionalController = TextEditingController();
  final _skillChips = <String>[];
  String? _educationLevel;

  List<Job> _jobs = [];
  bool _loading = true;
  bool _formVisible = false;
  bool _submitting = false;
  Job? _editing;
  String? _listError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _listError = null;
    });
    try {
      final jobs = await _service.fetchJobs();
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _listError = JobsService.describeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCreateForm() {
    setState(() {
      _editing = null;
      _titleController.clear();
      _skillsController.clear();
      _experienceController.clear();
      _additionalController.clear();
      _skillChips.clear();
      _educationLevel = null;
      _formError = null;
      _formVisible = true;
    });
  }

  void _openEditForm(Job job) {
    setState(() {
      _editing = job;
      _titleController.text = job.title;
      _skillsController.clear();
      _experienceController.text = job.experienceLevel;
      _additionalController.text = job.additionalRequirements ?? '';
      _skillChips
        ..clear()
        ..addAll(job.skills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty));
      _educationLevel = job.educationLevel;
      _formError = null;
      _formVisible = true;
    });
  }

  void _closeForm() {
    setState(() {
      _formVisible = false;
      _editing = null;
      _formError = null;
    });
  }

  void _addSkills() {
    final text = _skillsController.text.trim();
    if (text.isEmpty) return;
    final parts =
        text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    setState(() {
      for (final part in parts) {
        if (!_skillChips.contains(part)) _skillChips.add(part);
      }
      _skillsController.clear();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleController.text.trim();
    final experience = _experienceController.text.trim();
    if (title.isEmpty) {
      setState(() => _formError = 'Enter the job title.');
      return;
    }
    if (_skillChips.isEmpty && _skillsController.text.trim().isNotEmpty) {
      _addSkills();
    }
    if (_skillChips.isEmpty) {
      setState(() => _formError = 'Add at least one required skill.');
      return;
    }
    if (experience.isEmpty) {
      setState(() => _formError = 'Enter the experience level.');
      return;
    }
    if (_educationLevel == null) {
      setState(() => _formError = 'Select an education level.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final wasEditing = _editing;
      final additional = _additionalController.text.trim();
      final base = Job(
        id: '',
        title: title,
        skills: _skillChips.join(', '),
        experienceLevel: experience,
        educationLevel: _educationLevel!,
        additionalRequirements: additional.isEmpty ? null : additional,
        createdAt: DateTime.now(),
      );
      final saved = wasEditing == null
          ? await _service.createJob(base)
          : await _service.updateJob(wasEditing.id, base);
      if (!mounted) return;
      setState(() {
        if (wasEditing == null) {
          _jobs.insert(0, saved);
        } else {
          final index = _jobs.indexWhere((j) => j.id == saved.id);
          if (index != -1) _jobs[index] = saved;
        }
        _formVisible = false;
        _editing = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasEditing == null
              ? 'Job "${saved.title}" created.'
              : 'Job "${saved.title}" updated.'),
          backgroundColor: JobsPage._teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = JobsService.describeError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete(Job job) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete job?',
      message: 'Remove "${job.title}" and its requirements.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.deleteJob(job.id);
      if (!mounted) return;
      setState(() => _jobs.removeWhere((j) => j.id == job.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job "${job.title}" deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(JobsService.describeError(e)),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
      case 1:
        break;
      case 2:
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This section is coming soon.')),
        );
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
      bottomNavigationBar: DashboardNavBar(
        currentIndex: 1,
        onTap: _onNavTap,
      ),
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
                'Jobs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Manage job postings and requirements for CV screening',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _formVisible && _editing == null
                        ? _closeForm
                        : _openCreateForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(_formVisible && _editing == null
                        ? 'Close'
                        : 'New Job'),
                    style: FilledButton.styleFrom(
                      backgroundColor: JobsPage._teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_formVisible) ...[
                const SizedBox(height: 16),
                _buildForm(),
              ],
              const SizedBox(height: 20),
              _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(color: JobsPage._teal),
        ),
      );
    }
    if (_listError != null) {
      return Column(
        children: [
          AuthErrorBanner(
            message: _listError!,
            onDismiss: () => setState(() => _listError = null),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadJobs,
            style: OutlinedButton.styleFrom(
              foregroundColor: JobsPage._teal,
              side: const BorderSide(color: JobsPage._teal),
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
          'No jobs yet. Tap + New Job to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Column(
      children: [
        for (final job in _jobs) ...[
          _JobCard(job: job, onEdit: () => _openEditForm(job), onDelete: () => _confirmDelete(job)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: JobsPage._border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing == null ? 'Create New Job' : 'Edit Job',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_formError != null) ...[
            AuthErrorBanner(
              message: _formError!,
              onDismiss: () => setState(() => _formError = null),
            ),
            const SizedBox(height: 12),
          ],
          _buildLabel('Job Title *'),
          const SizedBox(height: 6),
          _buildInput(
            controller: _titleController,
            hint: 'e.g. Software Engineer',
          ),
          const SizedBox(height: 16),
          _buildLabel('Skills Require *'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _skillsController,
                  hint: 'e.g. Flutter, Firebase (comma separated)',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSkills(),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _addSkills,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: JobsPage._teal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_skillChips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in _skillChips)
                  Chip(
                    label: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        color: JobsPage._teal,
                      ),
                    ),
                    backgroundColor:
                        JobsPage._teal.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    deleteIconColor: JobsPage._teal,
                    onDeleted: () =>
                        setState(() => _skillChips.remove(skill)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildLabel('Experience Level *'),
          const SizedBox(height: 6),
          _buildInput(
            controller: _experienceController,
            hint: 'e.g. Mid-level, Senior (years)',
          ),
          const SizedBox(height: 16),
          _buildLabel('Education Level *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('education_${_editing?.id ?? 'new'}'),
            initialValue: _educationLevel,
            isExpanded: true,
            hint: const Text(
              'Select Education Level',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            icon: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JobsPage._teal,
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
              for (final option in JobsPage._educationOptions)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (value) => setState(() => _educationLevel = value),
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 16),
          _buildLabel('Additional Requirements (Optional)'),
          const SizedBox(height: 6),
          _buildInput(
            controller: _additionalController,
            hint: 'Any other requirements',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: JobsPage._teal,
                  disabledBackgroundColor:
                      JobsPage._teal.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_editing == null ? 'Create Job' : 'Update Job'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _submitting ? null : _closeForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFF95D0CB)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD4ECEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD4ECEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: JobsPage._teal, width: 2),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      cursorColor: JobsPage._teal,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: _inputDecoration().copyWith(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onEdit,
    required this.onDelete,
  });

  final Job job;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: JobsPage._border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Pill(
                      icon: Icons.work_outline,
                      label: job.status,
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      icon: Icons.people_outline,
                      label: '${job.applicantCount} Applicants',
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Colors.grey.shade700,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.grey.shade700,
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0D9488)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D9488),
            ),
          ),
        ],
      ),
    );
  }
}
