import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL: Android emulator uses 10.0.2.2, Web/Desktop uses localhost
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5136';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5136';
    }
    return 'http://localhost:5136';
  }

  static String baseUrl = defaultBaseUrl;

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';

  // Profile endpoints
  static const String freelancerProfile = '/api/freelancer/profile';
  static const String employerProfile = '/api/employer/profile';
  static const String employerProjects = '/api/employer/projects';

  // Document endpoints
  static const String uploadCv = '/api/documents/cv';
  static const String myCvs = '/api/documents/my-cvs';
  static String documentDetail(int id) => '/api/documents/$id';
  static String downloadDocument(int id) => '/api/documents/$id/download';
  static String setDefaultDocument(int id) => '/api/documents/$id/default';
  static String deleteDocument(int id) => '/api/documents/$id';

  // Project endpoints
  static const String projects = '/api/projects';
  static String projectDetail(int id) => '/api/projects/$id';
  static String closeProject(int id) => '/api/projects/$id/close';

  // Application endpoints
  static String applyProject(int projectId) => '/api/projects/$projectId/applications';
  static const String myApplications = '/api/applications/my';
  static String projectApplications(int projectId) => '/api/projects/$projectId/applications';
  static String applicationDetail(int id) => '/api/applications/$id';
  static String downloadApplicationCv(int id) => '/api/applications/$id/cv';
  static String updateApplicationStatus(int id) => '/api/applications/$id/status';

  // Credit endpoints
  static const String creditBalance = '/api/credits/balance';
  static const String creditTransactions = '/api/credits/transactions';
  static const String creditPackages = '/api/credits/packages';
  static const String createPurchase = '/api/credits/purchases';
  static String purchaseDetail(int id) => '/api/credits/purchases/$id';
  static String simulatePurchase(int id) => '/api/credits/purchases/$id/simulate-success';
  static String unlockContact(int projectId) => '/api/projects/$projectId/contact-unlock';
  static String getEmployerContact(int projectId) => '/api/projects/$projectId/employer-contact';

  // Admin & Report endpoints
  static const String adminUsers = '/api/admin/users';
  static String adminUserStatus(int id) => '/api/admin/users/$id/status';
  static const String adminProjects = '/api/admin/projects';
  static String adminProjectModeration(int id) => '/api/admin/projects/$id/moderation';
  static const String reports = '/api/reports';
  static const String adminReports = '/api/admin/reports';
  static String adminReportStatus(int id) => '/api/admin/reports/$id';
  static const String adminCreditTransactions = '/api/admin/credit-transactions';
  static const String adminAuditLogs = '/api/admin/audit-logs';
}

