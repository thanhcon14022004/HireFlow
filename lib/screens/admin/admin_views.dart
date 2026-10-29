import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/document_credit_and_admin_models.dart';
import '../../models/project_and_application_models.dart';
import '../../models/user_and_profile_models.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminUsersTab(),
    AdminProjectsTab(),
    AdminReportsTab(),
    AdminAuditTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: Colors.amber, size: 26),
            SizedBox(width: 8),
            Text('HireFlow Quản Trị Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(auth.user?.fullName ?? 'Admin', style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.manage_accounts), label: 'Tài khoản'),
          NavigationDestination(icon: Icon(Icons.rule), label: 'Kiểm duyệt'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), label: 'Báo cáo'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Nhật ký audit'),
        ],
      ),
    );
  }
}

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _selectedRole;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await AdminService.getUsers(search: _searchCtrl.text.trim(), role: _selectedRole);
      if (mounted) setState(() => _users = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _toggleUser(UserModel user) async {
    final nextStatus = !user.isActive;
    try {
      await AdminService.updateUserStatus(user.userId, nextStatus);
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ${nextStatus ? "mở khóa" : "khóa"} tài khoản ${user.fullName}'),
            backgroundColor: nextStatus ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String?>(
                value: _selectedRole,
                hint: const Text('Tất cả vai trò'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'Freelancer', child: Text('Freelancer')),
                  DropdownMenuItem(value: 'Employer', child: Text('Employer')),
                ],
                onChanged: (val) {
                  setState(() => _selectedRole = val);
                  _fetch();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const EmptyStateWidget(icon: Icons.person_off, title: 'Không tìm thấy người dùng nào')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = _users[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.isActive ? AppColors.primaryLight : const Color(0xFFFDE8E8),
                              child: Icon(
                                u.isFreelancer ? Icons.person : (u.isEmployer ? Icons.business : Icons.security),
                                color: u.isActive ? AppColors.primary : Colors.red,
                              ),
                            ),
                            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text('${u.email} • ${u.role} • Ví: ${u.creditBalance} cr', style: const TextStyle(fontSize: 12)),
                            trailing: Switch(
                              value: u.isActive,
                              activeThumbColor: AppColors.success,
                              onChanged: u.isAdmin ? null : (_) => _toggleUser(u),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class AdminProjectsTab extends StatefulWidget {
  const AdminProjectsTab({super.key});

  @override
  State<AdminProjectsTab> createState() => _AdminProjectsTabState();
}

class _AdminProjectsTabState extends State<AdminProjectsTab> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await AdminService.getAdminProjects();
      if (mounted) setState(() => _projects = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _moderate(int projectId, String newStatus) async {
    try {
      await AdminService.moderateProject(projectId, newStatus);
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái dự án thành: $newStatus'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _projects[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    StatusBadge(status: p.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Đăng bởi: ${p.companyName ?? p.employerName} (ID: ${p.employerId})', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (p.status != 'Open')
                      TextButton.icon(
                        icon: const Icon(Icons.check, size: 16, color: Colors.green),
                        label: const Text('Công khai (Open)', style: TextStyle(color: Colors.green)),
                        onPressed: () => _moderate(p.projectId, 'Open'),
                      ),
                    if (p.status != 'Hidden')
                      TextButton.icon(
                        icon: const Icon(Icons.visibility_off, size: 16, color: Colors.orange),
                        label: const Text('Tạm ẩn (Hidden)', style: TextStyle(color: Colors.orange)),
                        onPressed: () => _moderate(p.projectId, 'Hidden'),
                      ),
                    if (p.status != 'Removed')
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Gỡ bỏ (Removed)', style: TextStyle(color: Colors.red)),
                        onPressed: () => _moderate(p.projectId, 'Removed'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await AdminService.getReports();
      if (mounted) setState(() => _reports = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _updateStatus(int reportId, String status) async {
    try {
      await AdminService.updateReportStatus(reportId, status);
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái báo cáo thành: $status'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_reports.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.verified_user,
        title: 'Không có báo cáo vi phạm nào',
        subtitle: 'Hệ thống hiện tại đang an toàn và tuân thủ chuẩn mực.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _reports[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Báo cáo ${r.targetType} #${r.targetId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    StatusBadge(status: r.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Người báo cáo: ${r.reporterName} (ID: ${r.reporterUserId})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Lý do: ${r.reason}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 13)),
                if (r.description != null && r.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Chi tiết: ${r.description!}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => _updateStatus(r.reportId, 'Reviewing'), child: const Text('Đang xử lý')),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => _updateStatus(r.reportId, 'Resolved'), child: const Text('Giải quyết', style: TextStyle(color: Colors.green))),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => _updateStatus(r.reportId, 'Rejected'), child: const Text('Bác bỏ', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminAuditTab extends StatefulWidget {
  const AdminAuditTab({super.key});

  @override
  State<AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<AdminAuditTab> {
  List<AuditLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await AdminService.getAuditLogs();
      if (mounted) setState(() => _logs = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_logs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'Chưa có nhật ký audit nào',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.shield_outlined, size: 20, color: Color(0xFF475569)),
            ),
            title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${log.actorUserName ?? "Hệ thống"} • ${log.details ?? ""}\n${CurrencyFormatter.formatDate(log.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        );
      },
    );
  }
}
