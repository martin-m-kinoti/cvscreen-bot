import 'dart:typed_data';

import '../config/app_config.dart';
import '../models/application.dart';

/// Candidate-facing applications. Rows are written here; the CV analysis that
/// flips `status` from `pending` to `match`/`no_match` is owned by the backend
/// (see [requestAnalysis]) and is expected to update the same row.
class ApplicationsService {
  static const _bucket = 'cvs';

  Future<List<Application>> fetchApplications(String applicantId) async {
    final rows = await supabase
        .from('applications')
        .select()
        .eq('applicant_id', applicantId)
        .order('created_at', ascending: false);
    return rows.map(Application.fromMap).toList();
  }

  /// Stores the CV (best-effort) and records a `pending` application.
  Future<Application> submitApplication({
    required Application application,
    Uint8List? cvBytes,
  }) async {
    var storagePath = application.cvStoragePath;
    if (cvBytes != null && storagePath == null) {
      storagePath = await _uploadCv(
        applicantId: application.applicantId,
        fileName: application.cvFileName,
        bytes: cvBytes,
      );
    }
    final row = await supabase
        .from('applications')
        .insert({
          ...application.toMap(),
          'cv_storage_path': storagePath,
        })
        .select()
        .single();
    final saved = Application.fromMap(row);
    await requestAnalysis(saved.id);
    return saved;
  }

  /// Hook for the CV-screening backend. The backend should read the stored CV,
  /// score it against the job requirements and update this row's `status`.
  /// Wire this to an Edge Function / queue once it is available.
  Future<void> requestAnalysis(String applicationId) async {
    // Intentionally empty until the analysis backend is linked.
  }

  /// Returns the storage path, or null if the bucket is unavailable — the
  /// application is still recorded so the candidate sees a confirmation.
  Future<String?> _uploadCv({
    required String applicantId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$applicantId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    try {
      await supabase.storage.from(_bucket).uploadBinary(path, bytes);
      return path;
    } catch (_) {
      return null;
    }
  }

  static String describeError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return message;
  }
}
