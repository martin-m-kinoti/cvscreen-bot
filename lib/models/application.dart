class Application {
  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.cvFileName,
    this.cvStoragePath,
    this.status = 'pending',
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String applicantId;
  final String cvFileName;
  final String? cvStoragePath;
  final String status;
  final DateTime createdAt;

  factory Application.fromMap(Map<String, dynamic> map) => Application(
        id: map['id'] as String,
        jobId: map['job_id'] as String,
        jobTitle: map['job_title'] as String,
        applicantId: map['applicant_id'] as String,
        cvFileName: map['cv_file_name'] as String? ?? '',
        cvStoragePath: map['cv_storage_path'] as String?,
        status: (map['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'job_id': jobId,
        'job_title': jobTitle,
        'applicant_id': applicantId,
        'cv_file_name': cvFileName,
        'cv_storage_path': cvStoragePath,
        'status': status,
      };
}
