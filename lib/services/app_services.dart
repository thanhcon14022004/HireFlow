import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_and_profile_models.dart';
import '../models/project_and_application_models.dart';
import '../models/document_credit_and_admin_models.dart';
import 'api_service.dart';

class AuthService {
  static Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await ApiService.post(ApiConstants.register, body: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
    });

    final token = res['token']?.toString() ?? '';
    await ApiService.saveToken(token);

    final user = UserModel.fromJson(res['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiService.userKey, jsonEncode(user.toJson()));

    return user;
  }

  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post(ApiConstants.login, body: {
      'email': email,
      'password': password,
    });

    final token = res['token']?.toString() ?? '';
    await ApiService.saveToken(token);

    final user = UserModel.fromJson(res['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiService.userKey, jsonEncode(user.toJson()));

    return user;
  }

  static Future<UserModel?> getCurrentUser() async {
    final token = await ApiService.getToken();
    if (token == null) return null;

    try {
      final res = await ApiService.get(ApiConstants.me);
      final user = UserModel.fromJson(res);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiService.userKey, jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      // If network fails, try reading cached user
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(ApiService.userKey);
      if (userStr != null) {
        return UserModel.fromJson(jsonDecode(userStr));
      }
      return null;
    }
  }

  static Future<void> logout() async {
    await ApiService.removeToken();
  }

  static Future<String> forgotPassword(String email) async {
    final res = await ApiService.post(ApiConstants.forgotPassword, body: {'email': email});
    return res['message']?.toString() ?? 'Mã xác nhận đã được gửi.';
  }

  static Future<String> resetPassword(String email, String code, String newPassword) async {
    final res = await ApiService.post(ApiConstants.resetPassword, body: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    return res['message']?.toString() ?? 'Đặt lại mật khẩu thành công.';
  }

  static Future<String> changePassword(String currentPassword, String newPassword) async {
    final res = await ApiService.post(ApiConstants.changePassword, body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return res['message']?.toString() ?? 'Đổi mật khẩu thành công.';
  }
}

class ProfileService {
  static Future<FreelancerProfileModel> getFreelancerProfile() async {
    final res = await ApiService.get(ApiConstants.freelancerProfile);
    return FreelancerProfileModel.fromJson(res);
  }

  static Future<FreelancerProfileModel> updateFreelancerProfile({
    String? fullName,
    String? headline,
    String? bio,
    int? experienceYears,
    List<String>? skills,
  }) async {
    final res = await ApiService.put(ApiConstants.freelancerProfile, body: {
      'fullName': fullName,
      'headline': headline,
      'bio': bio,
      'experienceYears': experienceYears,
      'skills': skills,
    });
    return FreelancerProfileModel.fromJson(res);
  }

  static Future<EmployerProfileModel> getEmployerProfile() async {
    final res = await ApiService.get(ApiConstants.employerProfile);
    return EmployerProfileModel.fromJson(res);
  }

  static Future<EmployerProfileModel> updateEmployerProfile({
    String? fullName,
    String? companyName,
    String? description,
    String? publicDisplayName,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final res = await ApiService.put(ApiConstants.employerProfile, body: {
      'fullName': fullName,
      'companyName': companyName,
      'description': description,
      'publicDisplayName': publicDisplayName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    });
    return EmployerProfileModel.fromJson(res);
  }
}

class ProjectService {
  static Future<List<ProjectModel>> getProjects({
    String? keyword,
    String? skill,
    String? experienceLevel,
    double? minBudget,
    double? maxBudget,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (skill != null && skill.isNotEmpty) queryParams['skill'] = skill;
    if (experienceLevel != null && experienceLevel.isNotEmpty) queryParams['experienceLevel'] = experienceLevel;
    if (minBudget != null) queryParams['minBudget'] = minBudget.toString();
    if (maxBudget != null) queryParams['maxBudget'] = maxBudget.toString();
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final res = await ApiService.get(ApiConstants.projects, queryParams: queryParams);
    final items = res['items'] as List<dynamic>? ?? [];
    return items.map((p) => ProjectModel.fromJson(p)).toList();
  }

  static Future<ProjectModel> getProjectDetail(int projectId) async {
    final res = await ApiService.get(ApiConstants.projectDetail(projectId));
    return ProjectModel.fromJson(res);
  }

  static Future<int> createProject({
    required String title,
    required String description,
    double? budgetMin,
    double? budgetMax,
    String currencyCode = 'VND',
    String? experienceLevel,
    DateTime? deadline,
    List<String> skills = const [],
  }) async {
    final res = await ApiService.post(ApiConstants.projects, body: {
      'title': title,
      'description': description,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'currencyCode': currencyCode,
      'experienceLevel': experienceLevel,
      'deadline': deadline?.toIso8601String(),
      'skills': skills,
    });
    return res['projectId'] ?? 0;
  }

  static Future<void> updateProject(int projectId, {
    required String title,
    required String description,
    double? budgetMin,
    double? budgetMax,
    String currencyCode = 'VND',
    String? experienceLevel,
    DateTime? deadline,
    List<String> skills = const [],
  }) async {
    await ApiService.put(ApiConstants.projectDetail(projectId), body: {
      'title': title,
      'description': description,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'currencyCode': currencyCode,
      'experienceLevel': experienceLevel,
      'deadline': deadline?.toIso8601String(),
      'skills': skills,
    });
  }

  static Future<void> closeProject(int projectId) async {
    await ApiService.post(ApiConstants.closeProject(projectId));
  }

  static Future<List<ProjectModel>> getEmployerProjects() async {
    final res = await ApiService.get(ApiConstants.employerProjects);
    final items = res as List<dynamic>? ?? [];
    return items.map((p) => ProjectModel.fromJson(p)).toList();
  }
}

class ApplicationService {
  static Future<Map<String, dynamic>> applyProject(int projectId, {
    required int documentId,
    String? coverLetter,
  }) async {
    final res = await ApiService.post(ApiConstants.applyProject(projectId), body: {
      'documentId': documentId,
      'coverLetter': coverLetter,
    });
    return Map<String, dynamic>.from(res);
  }

  static Future<List<ApplicationModel>> getMyApplications() async {
    final res = await ApiService.get(ApiConstants.myApplications);
    final items = res as List<dynamic>? ?? [];
    return items.map((a) => ApplicationModel.fromJson(a)).toList();
  }

  static Future<List<ApplicationModel>> getProjectApplications(int projectId) async {
    final res = await ApiService.get(ApiConstants.projectApplications(projectId));
    final items = res as List<dynamic>? ?? [];
    return items.map((a) => ApplicationModel.fromJson(a)).toList();
  }

  static Future<ApplicationModel> getApplicationDetail(int applicationId) async {
    final res = await ApiService.get(ApiConstants.applicationDetail(applicationId));
    return ApplicationModel.fromJson(res);
  }

  static Future<void> updateApplicationStatus(int applicationId, String status) async {
    await ApiService.patch(ApiConstants.updateApplicationStatus(applicationId), body: {
      'status': status,
    });
  }
}

class DocumentService {
  static Future<DocumentModel> uploadCv(List<int> bytes, String filename, {bool isDefault = false}) async {
    final res = await ApiService.uploadFile(
      ApiConstants.uploadCv,
      bytes,
      filename,
      fields: {'isDefault': isDefault.toString()},
    );
    return DocumentModel.fromJson(res);
  }

  static Future<List<DocumentModel>> getMyCvs() async {
    final res = await ApiService.get(ApiConstants.myCvs);
    final items = res as List<dynamic>? ?? [];
    return items.map((d) => DocumentModel.fromJson(d)).toList();
  }

  static Future<void> setDefault(int documentId) async {
    await ApiService.put(ApiConstants.setDefaultDocument(documentId));
  }

  static Future<void> deleteCv(int documentId) async {
    await ApiService.delete(ApiConstants.deleteDocument(documentId));
  }
}

class CreditService {
  static Future<int> getBalance() async {
    final res = await ApiService.get(ApiConstants.creditBalance);
    return res['balance'] ?? 0;
  }

  static Future<List<CreditTransactionModel>> getTransactions() async {
    final res = await ApiService.get(ApiConstants.creditTransactions);
    final items = res as List<dynamic>? ?? [];
    return items.map((t) => CreditTransactionModel.fromJson(t)).toList();
  }

  static Future<List<CreditPackageModel>> getPackages() async {
    final res = await ApiService.get(ApiConstants.creditPackages);
    final items = res as List<dynamic>? ?? [];
    return items.map((p) => CreditPackageModel.fromJson(p)).toList();
  }

  static Future<Map<String, dynamic>> createPurchase(int packageId) async {
    final res = await ApiService.post(ApiConstants.createPurchase, body: {
      'creditPackageId': packageId,
    });
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> simulatePaymentSuccess(int purchaseId, {String? ref}) async {
    final endpoint = ref != null && ref.isNotEmpty
        ? '${ApiConstants.simulatePurchase(purchaseId)}?ref=$ref'
        : ApiConstants.simulatePurchase(purchaseId);
    final res = await ApiService.post(endpoint);
    return Map<String, dynamic>.from(res);
  }

  static Future<EmployerContactModel> unlockContact(int projectId) async {
    final res = await ApiService.post(ApiConstants.unlockContact(projectId));
    return EmployerContactModel.fromJson(res);
  }

  static Future<EmployerContactModel> getEmployerContact(int projectId) async {
    final res = await ApiService.get(ApiConstants.getEmployerContact(projectId));
    return EmployerContactModel.fromJson(res);
  }
}

class AdminService {
  static Future<List<UserModel>> getUsers({String? search, String? role, bool? isActive, int page = 1}) async {
    final q = <String, String>{'page': page.toString(), 'pageSize': '20'};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (role != null && role.isNotEmpty) q['role'] = role;
    if (isActive != null) q['isActive'] = isActive.toString();

    final res = await ApiService.get(ApiConstants.adminUsers, queryParams: q);
    final items = res['items'] as List<dynamic>? ?? [];
    return items.map((u) => UserModel.fromJson(u)).toList();
  }

  static Future<void> updateUserStatus(int userId, bool isActive) async {
    await ApiService.patch(ApiConstants.adminUserStatus(userId), body: {'isActive': isActive});
  }

  static Future<List<ProjectModel>> getAdminProjects({String? search, String? status, int page = 1}) async {
    final q = <String, String>{'page': page.toString(), 'pageSize': '20'};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;

    final res = await ApiService.get(ApiConstants.adminProjects, queryParams: q);
    final items = res['items'] as List<dynamic>? ?? [];
    return items.map((p) => ProjectModel.fromJson(p)).toList();
  }

  static Future<void> moderateProject(int projectId, String status, {String? reason}) async {
    await ApiService.patch(ApiConstants.adminProjectModeration(projectId), body: {
      'status': status,
      'reason': reason,
    });
  }

  static Future<void> submitReport({
    required String targetType,
    required int targetId,
    required String reason,
    String? description,
  }) async {
    await ApiService.post(ApiConstants.reports, body: {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'description': description,
    });
  }

  static Future<List<ReportModel>> getReports({String? status, int page = 1}) async {
    final q = <String, String>{'page': page.toString(), 'pageSize': '20'};
    if (status != null && status.isNotEmpty) q['status'] = status;

    final res = await ApiService.get(ApiConstants.adminReports, queryParams: q);
    final items = res['items'] as List<dynamic>? ?? [];
    return items.map((r) => ReportModel.fromJson(r)).toList();
  }

  static Future<void> updateReportStatus(int reportId, String status) async {
    await ApiService.patch(ApiConstants.adminReportStatus(reportId), body: {'status': status});
  }

  static Future<List<AuditLogModel>> getAuditLogs({int page = 1}) async {
    final res = await ApiService.get(ApiConstants.adminAuditLogs, queryParams: {
      'page': page.toString(),
      'pageSize': '25',
    });
    final items = res['items'] as List<dynamic>? ?? [];
    return items.map((a) => AuditLogModel.fromJson(a)).toList();
  }
}
