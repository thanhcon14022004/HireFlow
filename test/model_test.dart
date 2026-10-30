import 'package:flutter_test/flutter_test.dart';
import 'package:hireflow/models/user_and_profile_models.dart';
import 'package:hireflow/models/project_and_application_models.dart';
import 'package:hireflow/core/utils/currency_formatter.dart';

void main() {
  group('Model and Utility Tests', () {
    test('UserModel should parse correctly and identify roles', () {
      final json = {
        'userId': 42,
        'fullName': 'Nguyễn Văn An',
        'email': 'an@hireflow.com',
        'role': 'Freelancer',
        'isActive': true,
        'creditBalance': 15,
      };

      final user = UserModel.fromJson(json);

      expect(user.userId, 42);
      expect(user.fullName, 'Nguyễn Văn An');
      expect(user.email, 'an@hireflow.com');
      expect(user.isFreelancer, true);
      expect(user.isEmployer, false);
      expect(user.isAdmin, false);
      expect(user.creditBalance, 15);
    });

    test('ProjectModel should parse skills, budget and status correctly', () {
      final json = {
        'projectId': 101,
        'employerId': 5,
        'employerName': 'Công ty TechNova',
        'title': 'Dự án Flutter Mobile',
        'description': 'Mô tả dự án',
        'budgetMin': 10000000.0,
        'budgetMax': 20000000.0,
        'currencyCode': 'VND',
        'status': 'Open',
        'createdAt': '2026-10-30T00:00:00Z',
        'skills': ['Flutter', 'Dart', 'Bloc'],
        'applicantCount': 3,
        'isContactUnlocked': false,
      };

      final project = ProjectModel.fromJson(json);

      expect(project.projectId, 101);
      expect(project.title, 'Dự án Flutter Mobile');
      expect(project.isOpen, true);
      expect(project.isClosed, false);
      expect(project.skills.length, 3);
      expect(project.skills.contains('Flutter'), true);
      expect(project.applicantCount, 3);
      expect(project.isContactUnlocked, false);
    });

    test('CurrencyFormatter should format VND and budget ranges', () {
      expect(CurrencyFormatter.formatBudget(null, null), 'Thỏa thuận');
      expect(CurrencyFormatter.formatBudget(10000000, 10000000).contains('10.000.000'), true);
      expect(CurrencyFormatter.formatBudget(5000000, 10000000).contains('5.000.000'), true);
    });
  });
}

