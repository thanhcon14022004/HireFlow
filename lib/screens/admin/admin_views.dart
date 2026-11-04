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
  bool _isAutoRunning = false;

  void _onTriggerAutomation() async {
    setState(() => _isAutoRunning = true);
    try {
      final res = await AdminService.triggerAutomation();
      if (mounted) {
        final data = res['data'] as Map<String, dynamic>?;
        final closed = data?['projectsClosed'] ?? 0;
        final expired = data?['purchasesExpired'] ?? 0;
        final reconciled = data?['purchasesAutoReconciled'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tự động hóa hoàn tất: Đóng $closed dự án, hủy $expired đơn quá hạn, khớp $reconciled GD'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chạy tự động hóa: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAutoRunning = false);
    }
  }

  final List<Widget> _pages = const [
    AdminUsersTab(),
    AdminProjectsTab(),
    AdminReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HireFlow Quản Trị',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    auth.user?.fullName ?? 'Admin',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isAutoRunning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                  )
                : const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 24),
            tooltip: 'Chạy tác vụ tự động hóa ngay',
            onPressed: _isAutoRunning ? null : _onTriggerAutomation,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.manage_accounts_outlined), label: 'Tài khoản'),
          NavigationDestination(icon: Icon(Icons.rule_folder_outlined), label: 'Kiểm duyệt'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), label: 'Báo cáo vi phạm'),
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
    final actionName = nextStatus ? "Mở khóa tài khoản" : "Khóa tài khoản";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionName),
        content: Text(
          'Bạn có chắc muốn ${nextStatus ? "kích hoạt lại" : "tạm ngưng"} tài khoản của ${user.fullName} (${user.email})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: nextStatus ? AppColors.success : AppColors.error),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await AdminService.updateUserStatus(user.userId, nextStatus);
        _fetch();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã ${nextStatus ? "mở khóa" : "khóa"} tài khoản ${user.fullName} thành công.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter header
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
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetch();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String?>(
                value: _selectedRole,
                hint: const Text('Tất cả vai trò'),
                underline: const SizedBox(),
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
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: u.isActive ? AppColors.primaryLight : const Color(0xFFFEE2E2),
                                  child: Icon(
                                    u.isFreelancer ? Icons.person : (u.isEmployer ? Icons.business : Icons.security),
                                    color: u.isActive ? AppColors.primary : Colors.red,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSecondary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(u.role, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${u.email} • Ví: ${u.creditBalance} cr', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: u.isActive,
                                  activeThumbColor: AppColors.success,
                                  onChanged: u.isAdmin ? null : (_) => _toggleUser(u),
                                ),
                              ],
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
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await AdminService.getAdminProjects(status: _statusFilter);
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
    return Column(
      children: [
        // Status filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', null),
                _buildFilterChip('Công khai (Open)', 'Open'),
                _buildFilterChip('Tạm ẩn (Hidden)', 'Hidden'),
                _buildFilterChip('Đã gỡ (Removed)', 'Removed'),
              ],
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _projects.isEmpty
                  ? const EmptyStateWidget(icon: Icons.assignment_outlined, title: 'Không có dự án nào')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = _projects[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    ),
                                    StatusBadge(status: p.status, isSmall: true),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Đăng bởi: ${p.companyName ?? p.employerName} (ID: ${p.employerId}) • Ứng viên: ${p.applicantCount}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (p.status != 'Open')
                                      TextButton.icon(
                                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                        label: const Text('Công khai', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        onPressed: () => _moderate(p.projectId, 'Open'),
                                      ),
                                    if (p.status != 'Hidden')
                                      TextButton.icon(
                                        icon: const Icon(Icons.visibility_off_outlined, size: 16, color: Colors.orange),
                                        label: const Text('Tạm ẩn', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        onPressed: () => _moderate(p.projectId, 'Hidden'),
                                      ),
                                    if (p.status != 'Removed')
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        label: const Text('Gỡ bỏ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                        onPressed: () => _moderate(p.projectId, 'Removed'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          _fetch();
        },
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      ),
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
        icon: Icons.verified_user_outlined,
        title: 'Không có báo cáo vi phạm nào',
        subtitle: 'Hệ thống hiện tại đang tuân thủ an toàn & minh bạch.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _reports[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Báo cáo ${r.targetType} #${r.targetId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    StatusBadge(status: r.status, isSmall: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Người gửi: ${r.reporterName} (ID: ${r.reporterUserId})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Lý do: ${r.reason}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error, fontSize: 13.5)),
                if (r.description != null && r.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Chi tiết: ${r.description!}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => _updateStatus(r.reportId, 'Reviewing'), child: const Text('Đang xử lý')),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => _updateStatus(r.reportId, 'Resolved'), child: const Text('Giải quyết', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
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
  int _selectedSubTab = 0; // 0 = Audit Logs, 1 = Credit Transactions
  List<AuditLogModel> _logs = [];
  List<CreditTransactionModel> _txs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedSubTab == 0) {
        final list = await AdminService.getAuditLogs();
        if (mounted) setState(() => _logs = list);
      } else {
        final list = await AdminService.getCreditTransactions();
        if (mounted) setState(() => _txs = list);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Nhật ký sự kiện (Audit)')),
                  selected: _selectedSubTab == 0,
                  onSelected: (_) {
                    setState(() => _selectedSubTab = 0);
                    _fetch();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Giao dịch tín dụng toàn sàn')),
                  selected: _selectedSubTab == 1,
                  onSelected: (_) {
                    setState(() => _selectedSubTab = 1);
                    _fetch();
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedSubTab == 0
                  ? _buildAuditLogsList()
                  : _buildCreditTransactionsList(),
        ),
      ],
    );
  }

  Widget _buildAuditLogsList() {
    if (_logs.isEmpty) {
      return const EmptyStateWidget(icon: Icons.history, title: 'Chưa có nhật ký audit nào');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.shield_outlined, size: 20, color: Color(0xFF475569)),
            ),
            title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            subtitle: Text(
              '${log.actorUserName ?? "Hệ thống"} • ${log.details ?? ""}\n${CurrencyFormatter.formatDate(log.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditTransactionsList() {
    if (_txs.isEmpty) {
      return const EmptyStateWidget(icon: Icons.receipt_long, title: 'Chưa có giao dịch credit nào');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _txs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = _txs[index];
        final isPositive = tx.amount > 0;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPositive ? const Color(0xFFDEF7EC) : const Color(0xFFFEE2E2),
              child: Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPositive ? const Color(0xFF03543F) : const Color(0xFF991B1B),
                size: 18,
              ),
            ),
            title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            subtitle: Text(
              '${tx.transactionType} • ${CurrencyFormatter.formatDate(tx.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: Text(
              isPositive ? '+${tx.amount} cr' : '${tx.amount} cr',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isPositive ? const Color(0xFF047857) : const Color(0xFFDC2626),
              ),
            ),
          ),
        );
      },
    );
  }
}
