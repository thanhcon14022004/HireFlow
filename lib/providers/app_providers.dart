import 'package:flutter/foundation.dart';
import '../models/user_and_profile_models.dart';
import '../models/project_and_application_models.dart';
import '../models/document_credit_and_admin_models.dart';
import '../services/app_services.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  FreelancerProfileModel? _freelancerProfile;
  EmployerProfileModel? _employerProfile;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get user => _user;
  FreelancerProfileModel? get freelancerProfile => _freelancerProfile;
  EmployerProfileModel? get employerProfile => _employerProfile;
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
      if (_user != null) {
        await fetchProfile();
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (_user == null) return;
    try {
      if (_user!.isFreelancer) {
        _freelancerProfile = await ProfileService.getFreelancerProfile();
      } else if (_user!.isEmployer) {
        _employerProfile = await ProfileService.getEmployerProfile();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateFreelancerProfile({
    String? fullName,
    String? headline,
    String? bio,
    int? experienceYears,
    List<String>? skills,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _freelancerProfile = await ProfileService.updateFreelancerProfile(
        fullName: fullName,
        headline: headline,
        bio: bio,
        experienceYears: experienceYears,
        skills: skills,
      );
      if (fullName != null && _user != null) {
        _user = UserModel(
          userId: _user!.userId,
          fullName: fullName,
          email: _user!.email,
          role: _user!.role,
          isActive: _user!.isActive,
          creditBalance: _user!.creditBalance,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmployerProfile({
    String? fullName,
    String? companyName,
    String? description,
    String? publicDisplayName,
    String? contactEmail,
    String? contactPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _employerProfile = await ProfileService.updateEmployerProfile(
        fullName: fullName,
        companyName: companyName,
        description: description,
        publicDisplayName: publicDisplayName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
      );
      if (fullName != null && _user != null) {
        _user = UserModel(
          userId: _user!.userId,
          fullName: fullName,
          email: _user!.email,
          role: _user!.role,
          isActive: _user!.isActive,
          creditBalance: _user!.creditBalance,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
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
      await fetchProfile();
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
      await fetchProfile();
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
    _freelancerProfile = null;
    _employerProfile = null;
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
  List<ProjectModel> _savedProjects = [];
  List<ProjectModel> _myEmployerProjects = [];
  ProjectModel? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get savedProjects => _savedProjects;
  List<ProjectModel> get myEmployerProjects => _myEmployerProjects;
  List<ProjectModel> get employerProjects => _myEmployerProjects;
  ProjectModel? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSavedProjects() async {
    try {
      _savedProjects = await ProjectService.getSavedProjects();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching saved projects: ');
    }
  }

  Future<bool> toggleSaveProject(int projectId) async {
    final idx = _projects.indexWhere((p) => p.projectId == projectId);
    bool currentSaved = false;
    if (idx != -1) {
      currentSaved = _projects[idx].isSaved;
      _projects[idx] = _projects[idx].copyWith(isSaved: !currentSaved);
    }
    if (_currentProject?.projectId == projectId) {
      currentSaved = _currentProject!.isSaved;
      _currentProject = _currentProject!.copyWith(isSaved: !currentSaved);
    }
    notifyListeners();

    try {
      final newSavedState = !currentSaved;
      await ProjectService.toggleSaveProject(projectId, newSavedState);
      if (newSavedState) {
        ProjectModel? p;
        if (idx != -1) p = _projects[idx];
        p ??= _currentProject;
        if (p != null && !_savedProjects.any((item) => item.projectId == projectId)) {
          _savedProjects.insert(0, p.copyWith(isSaved: true));
        }
      } else {
        _savedProjects.removeWhere((item) => item.projectId == projectId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (idx != -1) {
        _projects[idx] = _projects[idx].copyWith(isSaved: currentSaved);
      }
      if (_currentProject?.projectId == projectId) {
        _currentProject = _currentProject!.copyWith(isSaved: currentSaved);
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProjects({
    String? keyword,
    String? search,
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
        keyword: keyword ?? search,
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

  void markProjectApplied(int projectId, {int? applicationId, String status = 'Pending'}) {
    final idx = _projects.indexWhere((p) => p.projectId == projectId);
    if (idx != -1) {
      _projects[idx] = _projects[idx].copyWith(
        hasApplied: true,
        myApplicationId: applicationId,
        myApplicationStatus: status,
      );
    }
    if (_currentProject?.projectId == projectId) {
      _currentProject = _currentProject!.copyWith(
        hasApplied: true,
        myApplicationId: applicationId,
        myApplicationStatus: status,
        isContactUnlocked: true,
      );
    }
    notifyListeners();
  }

  Future<bool> createProject({
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
      await ProjectService.createProject(
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

  Future<DocumentModel?> uploadCvAndReturn(List<int> bytes, String filename, {bool isDefault = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final doc = await DocumentService.uploadCv(bytes, filename, isDefault: isDefault);
      await fetchCvs();
      return doc;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadCv(List<int> bytes, String filename, {bool isDefault = false}) async {
    final doc = await uploadCvAndReturn(bytes, filename, isDefault: isDefault);
    return doc != null;
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

  Future<bool> setDefaultCv(int documentId) => setDefault(documentId);

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

  Future<CreditPurchaseModel?> createPurchase({
    int? packageId,
    int? customCredits,
    String paymentProvider = 'SepPay',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final purchase = await CreditService.createPurchase(
        packageId: packageId,
        customCredits: customCredits,
        paymentProvider: paymentProvider,
      );
      return purchase;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SepPayCheckResultModel?> checkSepPayPayment(int purchaseId) async {
    try {
      final res = await CreditService.checkSepPayPayment(purchaseId);
      if (res.status == 'Paid') {
        if (res.newBalance != null) {
          _balance = res.newBalance!;
        } else {
          await fetchBalance();
        }
        await fetchTransactions();
      }
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<SepPayCheckResultModel?> checkMoMoPayment(int purchaseId) async {
    try {
      final res = await CreditService.checkMoMoPayment(purchaseId);
      if (res.status == 'Paid') {
        if (res.newBalance != null) {
          _balance = res.newBalance!;
        } else {
          await fetchBalance();
        }
        await fetchTransactions();
      }
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> purchasePackageAndSimulate(int packageId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final purchase = await CreditService.createPurchase(packageId: packageId);

      // Execute simulated dev payment callback
      final simRes = await CreditService.simulatePaymentSuccess(purchase.creditPurchaseId, ref: purchase.providerReference);
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

  Future<bool> purchasePackage(int packageId) => purchasePackageAndSimulate(packageId);

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
