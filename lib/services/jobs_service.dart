import '../config/app_config.dart';
import '../models/job.dart';
import 'applications_service.dart';

class JobsService {
  final _applications = ApplicationsService();

  /// Loads advertised jobs and stamps each with a live applicant count.
  /// `jobs` has no applicant count column and `applications` RLS hides other
  /// candidates' rows from a recruiter, so counts come from the
  /// recruiter-gated `admin_list_applications()` function grouped by job title.
  Future<List<Job>> fetchJobs() async {
    final rows = await supabase
        .from('jobs')
        .select()
        .order('created_at', ascending: false);
    final jobs = rows.map(Job.fromMap).toList();

    final counts = <String, int>{};
    try {
      for (final applicant in await _applications.fetchApplicants()) {
        final title = applicant.jobTitle;
        if (title == null) continue;
        counts[title] = (counts[title] ?? 0) + 1;
      }
    } catch (_) {
      // Counts are best-effort; leave them at zero if the function is missing.
    }

    return [
      for (final job in jobs) job.copyWith(applicantCount: counts[job.title] ?? 0),
    ];
  }

  Future<Job> createJob(Job job) async {
    final row = await supabase.from('jobs').insert(job.toMap()).select().single();
    return Job.fromMap(row);
  }

  Future<Job> updateJob(String id, Job job) async {
    final row = await supabase
        .from('jobs')
        .update(job.toMap())
        .eq('id', id)
        .select()
        .single();
    // The reloaded row has no applicant_count, so keep the loaded count.
    return Job.fromMap(row).copyWith(applicantCount: job.applicantCount);
  }

  Future<void> deleteJob(String id) =>
      supabase.from('jobs').delete().eq('id', id);

  static String describeError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Could not reach the database. Check your connection and try again.';
    }
    return message;
  }
}
