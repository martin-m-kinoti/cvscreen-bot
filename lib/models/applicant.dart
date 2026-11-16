/// A screened applicant shown in the recruiter Applications table.
/// Read from the `admin_list_applications()` function, which joins the
/// candidate's `applications` row with their email from `auth.users`.
class Applicant {
  const Applicant({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.jobTitle,
    required this.score,
    required this.status,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String? jobTitle;
  final int score;
  final String status;

  factory Applicant.fromMap(Map<String, dynamic> map) => Applicant(
        id: map['id'] as String,
        userId: (map['user_id'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        jobTitle: map['job_title'] as String?,
        score: (map['overall_score'] as num?)?.round() ?? 0,
        status: (map['status'] as String?) ?? 'pending',
      );

  bool get isPending => status == 'pending';
}
