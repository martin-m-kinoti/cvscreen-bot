import '../config/app_config.dart';
import '../models/job.dart';

class JobsService {
  Future<List<Job>> fetchJobs() async {
    final rows = await supabase
        .from('jobs')
        .select()
        .order('created_at', ascending: false);
    return rows.map(Job.fromMap).toList();
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
    return Job.fromMap(row);
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
