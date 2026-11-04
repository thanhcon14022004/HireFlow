import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/project_and_application_models.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';
import '../common/cv_document_viewer_screen.dart';
import '../common/wallet_and_dialogs.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    EmployerProjectsTab(),
    PostProjectTab(),
    EmployerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final credit = context.watch<CreditProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HireFlow Tuyển Dụng',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    auth.user?.fullName ?? 'Nhà tuyển dụng',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CreditBadge(
              balance: credit.balance > 0 ? credit.balance : (auth.user?.creditBalance ?? 0),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 22, color: AppColors.textPrimary),
            tooltip: 'Ví Credit',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22, color: AppColors.textSecondary),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Tin tuyển dụng',
            ),
            NavigationDestination(
              icon: Icon(Icons.post_add_rounded),
              selectedIcon: Icon(Icons.post_add_rounded, color: AppColors.primary),
              label: 'Đăng tin (5 cr)',
            ),
            NavigationDestination(
              icon: Icon(Icons.domain_outlined),
              selectedIcon: Icon(Icons.domain_rounded, color: AppColors.primary),
              label: 'Doanh nghiệp',
            ),
          ],
        ),
      ),
    );
  }
}

class EmployerProjectsTab extends StatefulWidget {
  const EmployerProjectsTab({super.key});

  @override
  State<EmployerProjectsTab> createState() => _EmployerProjectsTabState();
}

class _EmployerProjectsTabState extends State<EmployerProjectsTab> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchEmployerProjects();
      context.read<CreditProvider>().fetchBalance();
    });
  }

  void _onCloseProject(int projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đóng nhận hồ sơ tin này?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Tin tuyển dụng sau khi đóng sẽ ngừng tiếp nhận ứng viên mới trên bảng tin việc làm. Các ứng viên đã nộp vẫn được lưu giữ an toàn để bạn tiếp tục đánh giá.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận đóng tin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final success = await context.read<ProjectProvider>().closeProject(projectId);
      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã đóng nhận hồ sơ tin tuyển dụng thành công.'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.employerProjects;

    final openCount = projects.where((p) => p.status.toLowerCase() == 'open').length;
    final totalApplicants = projects.fold<int>(0, (sum, p) => sum + p.applicantCount);

    final filtered = _statusFilter == null
        ? projects
        : projects.where((p) => p.status.toLowerCase() == _statusFilter!.toLowerCase()).toList();

    return RefreshIndicator(
      onRefresh: () => projectProvider.fetchEmployerProjects(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TopCV Recruiter KPI Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Tổng tin đăng',
                    value: '${projects.length}',
                    icon: Icons.assignment_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Đang mở',
                    value: '$openCount',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Ứng viên',
                    value: '$totalApplicants',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả (${projects.length})', null),
                  _buildFilterChip('Đang tuyển ($openCount)', 'Open'),
                  _buildFilterChip('Đã đóng (${projects.length - openCount})', 'Closed'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (projectProvider.isLoading && projects.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              const EmptyStateWidget(
                icon: Icons.post_add_rounded,
                title: 'Chưa có tin tuyển dụng nào',
                subtitle: 'Bấm vào tab "Đăng tin (5 cr)" để tạo bài đăng tuyển dụng IT đầu tiên của bạn.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  return _buildEmployerProjectCard(p);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = status),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
        ),
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  void _openProjectDetails(ProjectModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployerProjectDetailScreen(initialProject: p),
      ),
    );
  }

  Widget _buildEmployerProjectCard(ProjectModel p) {
    final salaryShort = CurrencyFormatter.formatBudgetShort(p.budgetMin, p.budgetMax);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProjectDetails(p),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: p.status, isSmall: true),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Salary pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_money_rounded, size: 13, color: AppColors.primary),
                          Text(
                            salaryShort,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    if (p.experienceLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.experienceLevel!,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                if (p.skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    children: p.skills.take(4).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),

                // Action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Detail & Applicant button
                    ElevatedButton.icon(
                      onPressed: () => _openProjectDetails(p),
                      icon: const Icon(Icons.description_outlined, size: 15),
                      label: Text(
                        'Chi tiết tin & Ứng viên (${p.applicantCount})',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    if (p.isOpen)
                      TextButton.icon(
                        onPressed: () => _onCloseProject(p.projectId),
                        icon: const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF64748B)),
                        label: const Text('Đóng tin', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectApplicantsScreen extends StatelessWidget {
  final int projectId;
  final String projectTitle;

  const ProjectApplicantsScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  Widget build(BuildContext context) {
    return EmployerProjectDetailScreen(
      projectId: projectId,
      projectTitle: projectTitle,
    );
  }
}

class EmployerProjectDetailScreen extends StatefulWidget {
  final ProjectModel? initialProject;
  final int? projectId;
  final String? projectTitle;

  const EmployerProjectDetailScreen({
    super.key,
    this.initialProject,
    this.projectId,
    this.projectTitle,
  });

  @override
  State<EmployerProjectDetailScreen> createState() => _EmployerProjectDetailScreenState();
}

class _EmployerProjectDetailScreenState extends State<EmployerProjectDetailScreen> {
  ProjectModel? _project;
  bool _isLoadingProject = false;
  String? _statusFilter;

  int get _effectiveProjectId => _project?.projectId ?? widget.projectId ?? 0;
  String get _effectiveProjectTitle => _project?.title ?? widget.projectTitle ?? 'Chi tiết tin tuyển dụng';

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final pid = _effectiveProjectId;
    if (pid <= 0) return;

    setState(() => _isLoadingProject = true);
    try {
      final fetched = await ProjectService.getProjectDetail(pid);
      if (mounted) {
        setState(() {
          _project = fetched;
        });
      }
    } catch (_) {
      // Keep initial project if any
    } finally {
      if (mounted) setState(() => _isLoadingProject = false);
    }

    if (mounted) {
      context.read<ApplicationProvider>().fetchProjectApplications(pid);
    }
  }

  void _onCloseProject() async {
    final pid = _effectiveProjectId;
    if (pid <= 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đóng nhận hồ sơ tin này?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Tin tuyển dụng sau khi đóng sẽ ngừng tiếp nhận ứng viên mới trên bảng tin việc làm. Các ứng viên đã nộp vẫn được lưu giữ an toàn để bạn tiếp tục đánh giá.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận đóng tin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final success = await context.read<ProjectProvider>().closeProject(pid);
      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã đóng nhận hồ sơ tin tuyển dụng thành công.'), backgroundColor: AppColors.success),
        );
        _loadData();
      }
    }
  }

  void _updateStatus(int applicationId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final statuses = [
          {'key': 'Reviewing', 'name': 'Đang đánh giá hồ sơ', 'color': const Color(0xFF8B5CF6)},
          {'key': 'Shortlisted', 'name': 'Mời phỏng vấn', 'color': const Color(0xFF2563EB)},
          {'key': 'Accepted', 'name': 'Chấp nhận trúng tuyển', 'color': const Color(0xFF10B981)},
          {'key': 'Rejected', 'name': 'Từ chối ứng tuyển', 'color': const Color(0xFFEF4444)},
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cập nhật trạng thái ứng viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Trạng thái mới sẽ được thông báo ngay tới Freelancer.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              ...statuses.map((st) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: (st['color'] as Color).withAlpha(30),
                    child: Icon(Icons.circle, size: 8, color: st['color'] as Color),
                  ),
                  title: Text(st['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await context.read<ApplicationProvider>().updateStatus(
                          applicationId,
                          _effectiveProjectId,
                          st['key'] as String,
                        );
                    if (success && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Đã cập nhật: ${st['name']} (Đã gửi thông báo đến máy ứng viên)!'),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _viewCvDetails(ApplicationModel app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CvDocumentViewerScreen.fromApplication(
          application: app,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = status),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
        ),
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final apps = appProvider.projectApplications;

    final filtered = _statusFilter == null
        ? apps
        : apps.where((a) => a.status.toLowerCase() == _statusFilter!.toLowerCase()).toList();

    final p = _project;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chi tiết tin & Ứng viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            Text(
              _effectiveProjectTitle,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // SECTION 1: CHI TIẾT BẢN TIN TUYỂN DỤNG
              // ==========================================
              if (p != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & ID Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Mã tin: #HF-PRJ-${p.projectId}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                            StatusBadge(status: p.status, isSmall: true),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          p.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.3),
                        ),
                        const SizedBox(height: 12),

                        // 3 Key Metrics Pills
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              // Salary
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.monetization_on_outlined, size: 13, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text('Mức lương', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      CurrencyFormatter.formatBudgetShort(p.budgetMin, p.budgetMax),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                              const SizedBox(width: 10),

                              // Experience Level
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.military_tech_outlined, size: 13, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text('Cấp bậc', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      p.experienceLevel ?? 'Tất cả cấp bậc',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                              const SizedBox(width: 10),

                              // Deadline
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFFD97706)),
                                        SizedBox(width: 4),
                                        Text('Hạn nộp', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      p.deadline != null ? CurrencyFormatter.formatDate(p.deadline!) : 'Không giới hạn',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Required Skills for Project
                        if (p.skills.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.label_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'Kỹ năng chuyên môn yêu cầu:',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: p.skills.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Detailed Description
                        const Row(
                          children: [
                            Icon(Icons.article_outlined, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Text(
                              'Mô tả chi tiết công việc:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            p.description,
                            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bottom row of project card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đăng ngày: ${CurrencyFormatter.formatDate(p.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            if (p.isOpen)
                              TextButton.icon(
                                onPressed: _onCloseProject,
                                icon: const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFFDC2626)),
                                label: const Text(
                                  'Đóng nhận hồ sơ',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ] else if (_isLoadingProject) ...[
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                const SizedBox(height: 18),
              ],

              // ==========================================
              // SECTION 2: DANH SÁCH ỨNG VIÊN ĐÃ NỘP HỒ SƠ
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Danh sách hồ sơ ứng tuyển',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${apps.length} ứng viên',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả (${apps.length})', null),
                    _buildFilterChip('Chờ xem xét', 'Pending'),
                    _buildFilterChip('Đang đánh giá', 'Reviewing'),
                    _buildFilterChip('Mời phỏng vấn', 'Shortlisted'),
                    _buildFilterChip('Trúng tuyển', 'Accepted'),
                    _buildFilterChip('Từ chối', 'Rejected'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Applicants List
              if (appProvider.isLoading && apps.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.person_search_rounded,
                  title: 'Chưa có ứng viên nào trong mục này',
                  subtitle: 'Khi ứng viên nộp hồ sơ, danh sách thông tin và CV của họ sẽ hiển thị tại đây.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = filtered[index];
                    final initial = app.freelancerName.isNotEmpty ? app.freelancerName[0].toUpperCase() : 'U';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Candidate Header: Avatar, Name, Headline, Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.freelancerName,
                                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                      ),
                                      if (app.freelancerHeadline != null && app.freelancerHeadline!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          app.freelancerHeadline!,
                                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.work_outline_rounded, size: 12, color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                app.freelancerExperienceYears != null
                                                    ? '${app.freelancerExperienceYears} năm KN'
                                                    : 'Chưa cập nhật KN',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                          const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                                          Text(
                                            'Nộp: ${CurrencyFormatter.formatDate(app.appliedAt)}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(status: app.status, isSmall: true),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ==========================================
                            // KỸ NĂNG MÀ NGƯỜI ỨNG TUYỂN GHI TRONG HỒ SƠ
                            // ==========================================
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.stars_rounded, size: 14, color: Color(0xFF16A34A)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Kỹ năng chuyên môn ghi trong hồ sơ:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (app.freelancerSkills.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 5,
                                      children: app.freelancerSkills.map((s) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF86EFAC)),
                                            boxShadow: const [
                                              BoxShadow(color: Color(0x04000000), blurRadius: 2, offset: Offset(0, 1)),
                                            ],
                                          ),
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  else
                                    const Text(
                                      'Ứng viên chưa cập nhật danh sách kỹ năng chuyên môn trong hồ sơ.',
                                      style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                    ),
                                ],
                              ),
                            ),

                            // Cover Letter (if any)
                            if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Lời nhắn: "${app.coverLetter!}"',
                                        style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF475569), height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 10),

                            // CV Document Box & Actions
                            Row(
                              children: [
                                // CV Pill Clickable
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _viewCvDetails(app),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 18),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  app.originalFileName,
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Text(
                                                  'Chạm để mở xem CV A4',
                                                  style: TextStyle(fontSize: 9.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Open CV Button
                                ElevatedButton.icon(
                                  onPressed: () => _viewCvDetails(app),
                                  icon: const Icon(Icons.visibility_rounded, size: 14),
                                  label: const Text('Xem CV', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Update Status Button
                                ElevatedButton(
                                  onPressed: () => _updateStatus(app.applicationId, app.status),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Trạng thái', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostProjectTab extends StatefulWidget {
  const PostProjectTab({super.key});

  @override
  State<PostProjectTab> createState() => _PostProjectTabState();
}

class _PostProjectTabState extends State<PostProjectTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _minBudgetCtrl = TextEditingController();
  final _maxBudgetCtrl = TextEditingController();
  final _skillInputCtrl = TextEditingController();
  final List<String> _skills = [];
  String _selectedExp = 'Trung cấp (2-3 năm)';
  bool _isSubmitting = false;

  final List<String> _popularSuggestions = [
    'Flutter',
    'Dart',
    'C#',
    '.NET 8',
    'SQL Server',
    'React',
    'Node.js',
    'Python',
    'Docker',
    'AWS',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _minBudgetCtrl.dispose();
    _maxBudgetCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final credit = context.read<CreditProvider>();
    if (credit.balance < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần tối thiểu 5 credits để đăng bài tuyển dụng. Vui lòng nạp thêm.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final projectProvider = context.read<ProjectProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final minB = double.tryParse(_minBudgetCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    final maxB = double.tryParse(_maxBudgetCtrl.text.replaceAll('.', '').replaceAll(',', ''));

    if (minB != null && maxB != null && minB > maxB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngân sách tối thiểu không thể lớn hơn ngân sách tối đa.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final success = await projectProvider.createProject(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      budgetMin: minB,
      budgetMax: maxB,
      experienceLevel: _selectedExp,
      skills: _skills,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        await credit.fetchBalance();
        auth.updateCreditBalance(credit.balance);
        _titleCtrl.clear();
        _descCtrl.clear();
        _minBudgetCtrl.clear();
        _maxBudgetCtrl.clear();
        _skills.clear();
        messenger.showSnackBar(
          const SnackBar(content: Text('Đăng tin tuyển dụng thành công (-5 credits)!'), backgroundColor: AppColors.success),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(projectProvider.errorMessage ?? 'Đăng tin thất bại'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = context.watch<CreditProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TopCV Cost Reminder Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFB45309), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phí đăng tin tuyển dụng: 5 credits',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF92400E)),
                        ),
                        Text(
                          'Số dư của bạn: ${credit.balance} credits (Chỉnh sửa nội dung dự án sau này hoàn toàn miễn phí).',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 1: Project Basic Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 6),
                      Text('1. Thông tin vị trí tuyển dụng', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề tin tuyển dụng *',
                      hintText: 'vd: Tuyển Senior Flutter Developer phát triển ứng dụng FinTech',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả công việc & Yêu cầu chi tiết *',
                      hintText: 'Mô tả mục tiêu dự án, trách nhiệm chính, công nghệ sử dụng và tiến độ mong đợi...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mô tả dự án' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Requirements & Skills
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 6),
                      Text('2. Yêu cầu chuyên môn & Kỹ năng', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedExp,
                    decoration: const InputDecoration(labelText: 'Yêu cầu kinh nghiệm'),
                    items: const [
                      DropdownMenuItem(value: 'Mới đi làm', child: Text('Mới đi làm (< 1 năm)')),
                      DropdownMenuItem(value: 'Trung cấp (2-3 năm)', child: Text('Trung cấp (2-3 năm)')),
                      DropdownMenuItem(value: 'Cao cấp (3+ năm)', child: Text('Cao cấp (3+ năm)')),
                      DropdownMenuItem(value: 'Chuyên gia (5+ năm)', child: Text('Chuyên gia (5+ năm)')),
                    ],
                    onChanged: (v) => setState(() => _selectedExp = v!),
                  ),
                  const SizedBox(height: 14),

                  const Text('Gợi ý kỹ năng 1 chạm:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _popularSuggestions.map((sk) {
                        final isAdded = _skills.contains(sk);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 6),
                          child: ActionChip(
                            label: Text(sk, style: TextStyle(fontSize: 11, color: isAdded ? Colors.grey : AppColors.primary)),
                            avatar: isAdded ? const Icon(Icons.check, size: 12, color: Colors.green) : const Icon(Icons.add, size: 12, color: AppColors.primary),
                            onPressed: isAdded
                                ? null
                                : () {
                                    setState(() => _skills.add(sk));
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillInputCtrl,
                          decoration: const InputDecoration(hintText: 'Nhập kỹ năng khác (vd: Docker, AWS)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final sk = _skillInputCtrl.text.trim();
                          if (sk.isNotEmpty && !_skills.contains(sk)) {
                            setState(() {
                              _skills.add(sk);
                              _skillInputCtrl.clear();
                            });
                          }
                        },
                        child: const Text('Thêm'),
                      ),
                    ],
                  ),
                  if (_skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _skills.map((s) {
                        return Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11.5)),
                          onDeleted: () => setState(() => _skills.remove(s)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 3: Budget
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 6),
                      Text('3. Mức ngân sách / Lương dự kiến', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minBudgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tối thiểu (VNĐ)', hintText: 'vd: 15000000'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _maxBudgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tối đa (VNĐ)', hintText: 'vd: 25000000'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.rocket_launch_rounded, size: 16),
              label: const Text('Đăng tin tuyển dụng (-5 credits)', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class EmployerProfileTab extends StatefulWidget {
  const EmployerProfileTab({super.key});

  @override
  State<EmployerProfileTab> createState() => _EmployerProfileTabState();
}

class _EmployerProfileTabState extends State<EmployerProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  void _showEditProfileModal() {
    final auth = context.read<AuthProvider>();
    final p = auth.employerProfile;
    final nameCtrl = TextEditingController(text: auth.user?.fullName);
    final companyCtrl = TextEditingController(text: p?.companyName);
    final displayCtrl = TextEditingController(text: p?.publicDisplayName);
    final emailCtrl = TextEditingController(text: p?.contactEmail);
    final phoneCtrl = TextEditingController(text: p?.contactPhone);
    final descCtrl = TextEditingController(text: p?.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hồ sơ Doanh nghiệp', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên người đại diện *')),
                const SizedBox(height: 10),
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Tên pháp nhân công ty')),
                const SizedBox(height: 10),
                TextField(controller: displayCtrl, decoration: const InputDecoration(labelText: 'Tên hiển thị công khai *')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email liên hệ công việc')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Giới thiệu về doanh nghiệp')),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await auth.updateEmployerProfile(
                      fullName: nameCtrl.text.trim(),
                      companyName: companyCtrl.text.trim(),
                      publicDisplayName: displayCtrl.text.trim(),
                      contactEmail: emailCtrl.text.trim(),
                      contactPhone: phoneCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    if (success) {
                      nav.pop();
                      messenger.showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: AppColors.success));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final credit = context.watch<CreditProvider>();
    final p = auth.employerProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 10),
                Text(
                  p?.publicDisplayName ?? (auth.user?.fullName ?? ''),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                if (p?.companyName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p!.companyName!,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  p?.contactEmail ?? (auth.user?.email ?? ''),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showEditProfileModal,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Chỉnh sửa thông tin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Business Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin doanh nghiệp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', p?.contactPhone ?? 'Chưa cập nhật'),
                _buildInfoRow(Icons.email_outlined, 'Email liên hệ', p?.contactEmail ?? 'Chưa cập nhật'),
                if (p?.description != null && p!.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Giới thiệu:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(p.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                  title: const Text('Ví HireFlow Credit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CreditBadge(balance: credit.balance, isLarge: false),
                      const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB)),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 20),
                  title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                  onTap: () => showDialog(context: context, builder: (_) => const ChangePasswordDialog()),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB)),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  title: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.red)),
                  onTap: () => auth.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
