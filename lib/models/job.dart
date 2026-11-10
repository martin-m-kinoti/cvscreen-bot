class Job {
  const Job({
    required this.id,
    required this.title,
    required this.skills,
    required this.experienceLevel,
    required this.educationLevel,
    this.additionalRequirements,
    this.status = 'active',
    this.applicantCount = 0,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String skills;
  final String experienceLevel;
  final String educationLevel;
  final String? additionalRequirements;
  final String status;
  final int applicantCount;
  final DateTime createdAt;

  factory Job.fromMap(Map<String, dynamic> map) => Job(
        id: map['id'] as String,
        title: map['title'] as String,
        skills: map['skills'] as String,
        experienceLevel: map['experience_level'] as String,
        educationLevel: map['education_level'] as String,
        additionalRequirements: map['additional_requirements'] as String?,
        status: (map['status'] as String?) ?? 'active',
        applicantCount: (map['applicant_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'skills': skills,
        'experience_level': experienceLevel,
        'education_level': educationLevel,
        'additional_requirements': additionalRequirements,
      };

  Job copyWith({
    String? title,
    String? skills,
    String? experienceLevel,
    String? educationLevel,
    String? additionalRequirements,
  }) =>
      Job(
        id: id,
        title: title ?? this.title,
        skills: skills ?? this.skills,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        educationLevel: educationLevel ?? this.educationLevel,
        additionalRequirements: additionalRequirements ?? this.additionalRequirements,
        status: status,
        applicantCount: applicantCount,
        createdAt: createdAt,
      );
}
