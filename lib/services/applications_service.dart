import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/applicant.dart';
import '../models/application.dart';

/// Candidate-facing applications. The CV is NOT stored in Supabase: it is
/// streamed to the n8n screening workflow, which reads the job requirements,
/// scores the CV and writes the resulting `applications` row that
/// [fetchApplications] later shows back to the candidate.
class ApplicationsService {
  Future<List<Application>> fetchApplications(String userId) async {
    final rows = await supabase
        .from('applications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(Application.fromMap).toList();
  }

  /// Recruiter view: screened applicants joined with their email. Pass a job
  /// title to scope to one role, or null for all. Backed by the
  /// recruiter-gated `admin_list_applications()` function.
  Future<List<Applicant>> fetchApplicants({String? jobTitle}) async {
    final rows = await supabase.rpc(
      'admin_list_applications',
      params: {'p_job_title': jobTitle},
    );
    final list = (rows as List?) ?? const [];
    return list
        .map((row) => Applicant.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Uploads the CV to the n8n webhook with the signed-in user's Supabase
  /// access token as the `Authorization` header. The workflow needs the
  /// `auth.users` uuid and the CV file; `job_id`/`job_title` are sent as extra
  /// fields so the run can be tied to the advertised role.
  Future<void> submitCv({
    required String userId,
    required String emailAddress,
    required Uint8List cvBytes,
    required String cvFileName,
    String? jobId,
    String? jobTitle,
  }) async {
    final accessToken = supabase.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('Please sign in before applying.');
    }
    final request = http.MultipartRequest('POST', Uri.parse(AppConfig.n8nWebhookUrl))
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['user_id'] = userId
      ..fields['email_address'] = emailAddress;
    if (jobId != null) request.fields['job_id'] = jobId;
    if (jobTitle != null) request.fields['job_title'] = jobTitle;
    request.files.add(
      http.MultipartFile.fromBytes('cv', cvBytes, filename: cvFileName),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'The screening service rejected the CV (HTTP ${response.statusCode}).',
      );
    }
  }

  static String describeError(Object error) {
    if (error is http.ClientException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('ClientException')) {
      return 'Could not reach the screening service. Check your connection and try again.';
    }
    return error.toString();
  }
}
