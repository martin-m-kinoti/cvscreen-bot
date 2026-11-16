/// One AI CV-screening result row.
/// In the `applications` table `id` is the application's own row id, `user_id`
/// is the candidate's `auth.users` uuid, and `job_title` names the advertised
/// job it targets (there is no job_id column). Scores are 0-100 percentages
/// written by the n8n backend.
class Application {
  const Application({
    required this.id,
    required this.createdAt,
    required this.name,
    this.jobTitle,
    required this.overallScore,
    required this.skillMatch,
    required this.experienceMatch,
    required this.educationMatch,
    required this.certMatch,
    this.summary,
    this.strengths = const [],
    this.weaknesses = const [],
    this.status = 'pending',
  });

  final String id;
  final DateTime createdAt;
  final String name;
  final String? jobTitle;
  final double overallScore;
  final double skillMatch;
  final double experienceMatch;
  final double educationMatch;
  final double certMatch;
  final String? summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final String status;

  factory Application.fromMap(Map<String, dynamic> map) => Application(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        name: (map['name'] as String?) ?? '',
        jobTitle: map['job_title'] as String?,
        overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0,
        skillMatch: (map['skill_match'] as num?)?.toDouble() ?? 0,
        experienceMatch: (map['experience_match'] as num?)?.toDouble() ?? 0,
        educationMatch: (map['education_match'] as num?)?.toDouble() ?? 0,
        certMatch: (map['cert_match'] as num?)?.toDouble() ?? 0,
        summary: map['summary'] as String?,
        strengths: _stringList(map['strengths']),
        weaknesses: _stringList(map['weaknesses']),
        status: (map['status'] as String?) ?? 'pending',
      );

  static List<String> _stringList(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  bool get isPending => status == 'pending';
}
