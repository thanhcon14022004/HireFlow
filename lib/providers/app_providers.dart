import 'package:flutter/foundation.dart';
import '../models/user_and_profile_models.dart';
import '../models/project_and_application_models.dart';
import '../models/document_credit_and_admin_models.dart';
import '../services/app_services.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await AuthService.getCurrentUser();
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await AuthService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await AuthService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> reloadUser() async {
    try {
      _user = await AuthService.getCurrentUser();
      notifyListeners();
    } catch (_) {}
  }

  void updateCreditBalance(int newBalance) {
    if (_user != null) {
      _user = UserModel(
        userId: _user!.userId,
        fullName: _user!.fullName,
        email: _user!.email,
        role: _user!.role,
        isActive: _user!.isActive,
        creditBalance: newBalance,
      );
      notifyListeners();
    }
  }
}

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  List<ProjectModel> _myEmployerProjects = [];
  ProjectModel? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get myEmployerProjects => _myEmployerProjects;
  ProjectModel? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProjects({
    String? keyword,
    String? skill,
    String? experienceLevel,
    double? minBudget,
    double? maxBudget,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _projects = await ProjectService.getProjects(
        keyword: keyword,
        skill: skill,
        experienceLevel: experienceLevel,
        minBudget: minBudget,
        maxBudget: maxBudget,
        status: status,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProjectDetail(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentProject = await ProjectService.getProjectDetail(projectId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> createProject({
    required String title,
    required String description,
    double? budgetMin,
    double? budgetMax,
    String currencyCode = 'VND',
    String? experienceLevel,
    DateTime? deadline,
    List<String> skills = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final projectId = await ProjectService.createProject(
        title: title,
        description: description,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        currencyCode: currencyCode,
        experienceLevel: experienceLevel,
        deadline: deadline,
        skills: skills,
      );
      await fetchEmployerProjects();
      return projectId;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProject(int projectId, {
    required String title,
    required String description,
    double? budgetMin,
    double? budgetMax,
    String currencyCode = 'VND',
    String? experienceLevel,
    DateTime? deadline,
    List<String> skills = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await ProjectService.updateProject(
        projectId,
        title: title,
        description: description,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        currencyCode: currencyCode,
        experienceLevel: experienceLevel,
        deadline: deadline,
        skills: skills,
      );
      await fetchEmployerProjects();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> closeProject(int projectId) async {
    try {
      await ProjectService.closeProject(projectId);
      await fetchEmployerProjects();
      if (_currentProject?.projectId == projectId) {
        await fetchProjectDetail(projectId);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchEmployerProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _myEmployerProjects = await ProjectService.getEmployerProjects();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ApplicationProvider extends ChangeNotifier {
  List<ApplicationModel> _myApplications = [];
  List<ApplicationModel> _projectApplications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ApplicationModel> get myApplications => _myApplications;
  List<ApplicationModel> get projectApplications => _projectApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _myApplications = await ApplicationService.getMyApplications();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProjectApplications(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _projectApplications = await ApplicationService.getProjectApplications(projectId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyProject(int projectId, {required int documentId, String? coverLetter}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await ApplicationService.applyProject(projectId, documentId: documentId, coverLetter: coverLetter);
      await fetchMyApplications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(int applicationId, int projectId, String status) async {
    try {
      await ApplicationService.updateApplicationStatus(applicationId, status);
      await fetchProjectApplications(projectId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class DocumentProvider extends ChangeNotifier {
  List<DocumentModel> _cvs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DocumentModel> get cvs => _cvs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DocumentModel? get defaultCv => _cvs.cast<DocumentModel?>().firstWhere((d) => d?.isDefault == true, orElse: () => _cvs.isNotEmpty ? _cvs.first : null);

  Future<void> fetchCvs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cvs = await DocumentService.getMyCvs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadCv(List<int> bytes, String filename, {bool isDefault = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await DocumentService.uploadCv(bytes, filename, isDefault: isDefault);
      await fetchCvs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setDefault(int documentId) async {
    try {
      await DocumentService.setDefault(documentId);
      await fetchCvs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCv(int documentId) async {
    try {
      await DocumentService.deleteCv(documentId);
      await fetchCvs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class CreditProvider extends ChangeNotifier {
  int _balance = 0;
  List<CreditTransactionModel> _transactions = [];
  List<CreditPackageModel> _packages = [];
  bool _isLoading = false;
  String? _errorMessage;

  int get balance => _balance;
  List<CreditTransactionModel> get transactions => _transactions;
  List<CreditPackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBalance() async {
    try {
      _balance = await CreditService.getBalance();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _transactions = await CreditService.getTransactions();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPackages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _packages = await CreditService.getPackages();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchasePackageAndSimulate(int packageId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final purchaseRes = await CreditService.createPurchase(packageId);
      final purchaseId = purchaseRes['creditPurchaseId'] as int;
      final providerRef = purchaseRes['providerReference'] as String?;

      // Execute simulated dev payment callback
      final simRes = await CreditService.simulatePaymentSuccess(purchaseId, ref: providerRef);
      if (simRes['newBalance'] != null) {
        _balance = simRes['newBalance'] as int;
      } else {
        await fetchBalance();
      }
      await fetchTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EmployerContactModel?> unlockContact(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final contact = await CreditService.unlockContact(projectId);
      await fetchBalance();
      await fetchTransactions();
      return contact;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
