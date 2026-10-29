class ProjectModel {
  final int projectId;
  final int employerId;
  final String employerName;
  final String? companyName;
  final String title;
  final String description;
  final double? budgetMin;
  final double? budgetMax;
  final String currencyCode;
  final String? experienceLevel;
  final DateTime? deadline;
  final String status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final List<String> skills;
  final int applicantCount;

  // Detail fields
  final bool isContactUnlocked;
  final String? contactEmail;
  final String? contactPhone;
  final bool hasApplied;
  final int? myApplicationId;
  final String? myApplicationStatus;

  ProjectModel({
    required this.projectId,
    required this.employerId,
    required this.employerName,
    this.companyName,
    required this.title,
    required this.description,
    this.budgetMin,
    this.budgetMax,
    required this.currencyCode,
    this.experienceLevel,
    this.deadline,
    required this.status,
    required this.createdAt,
    this.publishedAt,
    required this.skills,
    required this.applicantCount,
    this.isContactUnlocked = false,
    this.contactEmail,
    this.contactPhone,
    this.hasApplied = false,
    this.myApplicationId,
    this.myApplicationStatus,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['projectId'] ?? 0,
      employerId: json['employerId'] ?? 0,
      employerName: json['employerName'] ?? '',
      companyName: json['companyName'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      budgetMin: json['budgetMin'] != null ? (json['budgetMin'] as num).toDouble() : null,
      budgetMax: json['budgetMax'] != null ? (json['budgetMax'] as num).toDouble() : null,
      currencyCode: json['currencyCode'] ?? 'VND',
      experienceLevel: json['experienceLevel'],
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      status: json['status'] ?? 'Open',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'].toString()) : null,
      skills: (json['skills'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      applicantCount: json['applicantCount'] ?? 0,
      isContactUnlocked: json['isContactUnlocked'] == true,
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      hasApplied: json['hasApplied'] == true,
      myApplicationId: json['myApplicationId'],
      myApplicationStatus: json['myApplicationStatus'],
    );
  }

  bool get isOpen => status == 'Open';
  bool get isClosed => status == 'Closed';
}

class ApplicationModel {
  final int applicationId;
  final int projectId;
  final String projectTitle;
  final int freelancerId;
  final String freelancerName;
  final String? freelancerHeadline;
  final String? freelancerBio;
  final int? freelancerExperienceYears;
  final List<String> freelancerSkills;
  final int documentId;
  final String originalFileName;
  final String? coverLetter;
  final String status;
  final DateTime appliedAt;
  final DateTime updatedAt;
  final List<ApplicationStatusHistoryModel> statusHistories;

  ApplicationModel({
    required this.applicationId,
    required this.projectId,
    required this.projectTitle,
    required this.freelancerId,
    required this.freelancerName,
    this.freelancerHeadline,
    this.freelancerBio,
    this.freelancerExperienceYears,
    required this.freelancerSkills,
    required this.documentId,
    required this.originalFileName,
    this.coverLetter,
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
    required this.statusHistories,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      applicationId: json['applicationId'] ?? 0,
      projectId: json['projectId'] ?? 0,
      projectTitle: json['projectTitle'] ?? '',
      freelancerId: json['freelancerId'] ?? 0,
      freelancerName: json['freelancerName'] ?? '',
      freelancerHeadline: json['freelancerHeadline'],
      freelancerBio: json['freelancerBio'],
      freelancerExperienceYears: json['freelancerExperienceYears'],
      freelancerSkills: (json['freelancerSkills'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      documentId: json['documentId'] ?? 0,
      originalFileName: json['originalFileName'] ?? '',
      coverLetter: json['coverLetter'],
      status: json['status'] ?? 'Pending',
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      statusHistories: (json['statusHistories'] as List<dynamic>?)
              ?.map((h) => ApplicationStatusHistoryModel.fromJson(h))
              .toList() ??
          [],
    );
  }
}

class ApplicationStatusHistoryModel {
  final int historyId;
  final String? oldStatus;
  final String newStatus;
  final String changedByUserName;
  final DateTime changedAt;

  ApplicationStatusHistoryModel({
    required this.historyId,
    this.oldStatus,
    required this.newStatus,
    required this.changedByUserName,
    required this.changedAt,
  });

  factory ApplicationStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return ApplicationStatusHistoryModel(
      historyId: json['historyId'] ?? 0,
      oldStatus: json['oldStatus'],
      newStatus: json['newStatus'] ?? '',
      changedByUserName: json['changedByUserName'] ?? '',
      changedAt: DateTime.tryParse(json['changedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
