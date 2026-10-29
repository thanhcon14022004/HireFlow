class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final int creditBalance;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.creditBalance = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId'].toString()) ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['isActive'] == true || json['isActive'] == 1,
      creditBalance: json['creditBalance'] is int
          ? json['creditBalance']
          : int.tryParse(json['creditBalance']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'isActive': isActive,
      'creditBalance': creditBalance,
    };
  }

  bool get isFreelancer => role.toLowerCase() == 'freelancer';
  bool get isEmployer => role.toLowerCase() == 'employer';
  bool get isAdmin => role.toLowerCase() == 'admin';
}

class FreelancerProfileModel {
  final int profileId;
  final int userId;
  final String fullName;
  final String email;
  final String? avatarStorageKey;
  final String? headline;
  final String? bio;
  final int? experienceYears;
  final List<String> skills;
  final DateTime updatedAt;

  FreelancerProfileModel({
    required this.profileId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarStorageKey,
    this.headline,
    this.bio,
    this.experienceYears,
    required this.skills,
    required this.updatedAt,
  });

  factory FreelancerProfileModel.fromJson(Map<String, dynamic> json) {
    return FreelancerProfileModel(
      profileId: json['profileId'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatarStorageKey: json['avatarStorageKey'],
      headline: json['headline'],
      bio: json['bio'],
      experienceYears: json['experienceYears'],
      skills: (json['skills'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class EmployerProfileModel {
  final int employerProfileId;
  final int userId;
  final String fullName;
  final String email;
  final String? companyName;
  final String? description;
  final String? publicDisplayName;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime updatedAt;

  EmployerProfileModel({
    required this.employerProfileId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.companyName,
    this.description,
    this.publicDisplayName,
    this.contactEmail,
    this.contactPhone,
    required this.updatedAt,
  });

  factory EmployerProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployerProfileModel(
      employerProfileId: json['employerProfileId'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      companyName: json['companyName'],
      description: json['description'],
      publicDisplayName: json['publicDisplayName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
