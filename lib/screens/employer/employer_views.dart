import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.business_center, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('HireFlow Tuyển Dụng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
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
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Ví Credit',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          ),
        ],
        elevation: 0.5,
        backgroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Dự án của tôi'),
          NavigationDestination(icon: Icon(Icons.post_add), label: 'Đăng tin mới (5 cr)'),
          NavigationDestination(icon: Icon(Icons.domain), label: 'Hồ sơ doanh nghiệp'),
        ],
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchEmployerProjects();
    });
  }

  void _onCloseProject(int projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đóng nhận hồ sơ?'),
        content: const Text('Dự án sau khi đóng sẽ không nhận thêm hồ sơ mới. Các hồ sơ đã nộp vẫn được bảo lưu để bạn xem xét.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Đóng dự án'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ProjectProvider>().closeProject(projectId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đóng dự án thành công.'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();

    if (projectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (projectProvider.myEmployerProjects.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.post_add,
        title: 'Chưa có tin tuyển dụng nào',
        subtitle: 'Đăng tin dự án mới để tiếp cận hàng nghìn freelancer tài năng.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => projectProvider.fetchEmployerProjects(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: projectProvider.myEmployerProjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = projectProvider.myEmployerProjects[index];
          return Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      StatusBadge(status: p.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatBudget(p.budgetMin, p.budgetMax),
                    style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng ngày: ${CurrencyFormatter.formatDate(p.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    children: [
                      // Applicant count button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectApplicantsScreen(projectId: p.projectId, projectTitle: p.title),
                            ),
                          );
                        },
                        icon: const Icon(Icons.people, size: 18),
                        label: Text('Ứng viên (${p.applicantCount})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const Spacer(),
                      if (p.isOpen)
                        OutlinedButton(
                          onPressed: () => _onCloseProject(p.projectId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Đóng tin'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProjectApplicantsScreen extends StatefulWidget {
  final int projectId;
  final String projectTitle;

  const ProjectApplicantsScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  State<ProjectApplicantsScreen> createState() => _ProjectApplicantsScreenState();
}

class _ProjectApplicantsScreenState extends State<ProjectApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().fetchProjectApplications(widget.projectId);
    });
  }

  void _updateStatus(int applicationId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final statuses = [
          {'key': 'Reviewing', 'name': 'Đang xem xét (Reviewing)', 'color': Colors.purple},
          {'key': 'Shortlisted', 'name': 'Chọn lọc phỏng vấn (Shortlisted)', 'color': Colors.blue},
          {'key': 'Accepted', 'name': 'Chấp nhận trúng tuyển (Accepted)', 'color': Colors.green},
          {'key': 'Rejected', 'name': 'Từ chối ứng tuyển (Rejected)', 'color': Colors.red},
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cập nhật trạng thái ứng viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...statuses.map((st) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (st['color'] as Color).withAlpha(38),
                    child: Icon(Icons.circle, size: 14, color: st['color'] as Color),
                  ),
                  title: Text(st['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await context.read<ApplicationProvider>().updateStatus(
                          applicationId,
                          widget.projectId,
                          st['key'] as String,
                        );
                    if (success && mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Đã cập nhật trạng thái thành ${st['name']}'), backgroundColor: AppColors.success),
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

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ứng viên: ${widget.projectTitle}'),
      ),
      body: appProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : appProvider.projectApplications.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'Chưa có ứng viên nào nộp hồ sơ',
                  subtitle: 'Các hồ sơ ứng tuyển từ freelancer sẽ hiển thị tại đây.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: appProvider.projectApplications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = appProvider.projectApplications[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.freelancerName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      if (app.freelancerHeadline != null)
                                        Text(
                                          app.freelancerHeadline!,
                                          style: const TextStyle(fontSize: 13, color: AppColors.primary),
                                        ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: app.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (app.freelancerExperienceYears != null)
                              Text('Kinh nghiệm: ${app.freelancerExperienceYears} năm', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            if (app.freelancerSkills.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: app.freelancerSkills.map((s) => Chip(
                                  label: Text(s, style: const TextStyle(fontSize: 11)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )).toList(),
                              ),
                            ],
                            if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                                child: Text('Thư giới thiệu: "${app.coverLetter}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                              ),
                            ],
                            const SizedBox(height: 14),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('CV đính kèm: ${app.originalFileName} (Đã xác thực hợp lệ)'),
                                        backgroundColor: AppColors.info,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                                  label: Text(app.originalFileName, style: const TextStyle(fontSize: 13)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _updateStatus(app.applicationId, app.status),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Cập nhật trạng thái'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _minBudgetCtrl.dispose();
    _maxBudgetCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  void _addSkill() {
    final sk = _skillInputCtrl.text.trim();
    if (sk.isNotEmpty && !_skills.contains(sk)) {
      setState(() {
        _skills.add(sk);
        _skillInputCtrl.clear();
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final credit = context.read<CreditProvider>();
    final auth = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng tin tuyển dụng'),
        content: const Text('Phí đăng tin là 5 credits. Số credit sẽ được trừ trực tiếp từ ví nhà tuyển dụng của bạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Đăng tin (-5 credits)'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    final minB = double.tryParse(_minBudgetCtrl.text);
    final maxB = double.tryParse(_maxBudgetCtrl.text);

    final projectId = await projectProvider.createProject(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      budgetMin: minB,
      budgetMax: maxB,
      experienceLevel: _selectedExp,
      skills: _skills,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (projectId != null) {
        credit.fetchBalance();
        auth.updateCreditBalance(credit.balance);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng tin dự án thành công (-5 credits)!'), backgroundColor: AppColors.success),
        );
        _titleCtrl.clear();
        _descCtrl.clear();
        _minBudgetCtrl.clear();
        _maxBudgetCtrl.clear();
        setState(() => _skills.clear());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(projectProvider.errorMessage ?? 'Đăng tin thất bại'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cost Notice Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(26),
                border: Border.all(color: AppColors.accent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info, color: AppColors.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Phí đăng tin dự án: 5 credits. Tin tuyển dụng sẽ được xuất bản công khai ngay lập tức cho các ứng viên.',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Tiêu đề dự án tuyển dụng *',
                hintText: 'Ví dụ: Cần tuyển Senior Flutter Developer xây dựng app FinTech',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết dự án & yêu cầu kỹ thuật *',
                hintText: 'Mô tả phạm vi công việc, công nghệ sử dụng, thời gian hoàn thành dự kiến...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mô tả' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minBudgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ngân sách tối thiểu (VND)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxBudgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ngân sách tối đa (VND)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedExp,
              decoration: InputDecoration(
                labelText: 'Yêu cầu kinh nghiệm',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Mới bắt đầu / Junior (< 1 năm)', child: Text('Mới bắt đầu / Junior (< 1 năm)')),
                DropdownMenuItem(value: 'Trung cấp (2-3 năm)', child: Text('Trung cấp (2-3 năm)')),
                DropdownMenuItem(value: 'Cao cấp (3+ năm)', child: Text('Cao cấp (3+ năm)')),
                DropdownMenuItem(value: 'Chuyên gia / Lead (5+ năm)', child: Text('Chuyên gia / Lead (5+ năm)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedExp = val);
              },
            ),
            const SizedBox(height: 16),

            // Skills
            const Text('Kỹ năng yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillInputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập kỹ năng rồi bấm Thêm (vd: Flutter, .NET)...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addSkill, child: const Text('Thêm')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _skills.map((s) => Chip(
                label: Text(s),
                onDeleted: () => setState(() => _skills.remove(s)),
              )).toList(),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Xuất bản tin tuyển dụng (-5 credits)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
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
  final _companyCtrl = TextEditingController();
  final _displayCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final p = await ProfileService.getEmployerProfile();
      if (mounted) {
        setState(() {
          _companyCtrl.text = p.companyName ?? '';
          _displayCtrl.text = p.publicDisplayName ?? '';
          _descCtrl.text = p.description ?? '';
          _emailCtrl.text = p.contactEmail ?? '';
          _phoneCtrl.text = p.contactPhone ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _save() async {
    setState(() => _isSaving = true);
    try {
      await ProfileService.updateEmployerProfile(
        companyName: _companyCtrl.text.trim(),
        publicDisplayName: _displayCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin doanh nghiệp thành công!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _companyCtrl,
            decoration: InputDecoration(
              labelText: 'Tên công ty / Doanh nghiệp',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _displayCtrl,
            decoration: InputDecoration(
              labelText: 'Tên hiển thị công khai (VD: Phòng Nhân sự TechNova)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'Email liên hệ tuyển dụng (Bảo mật, chỉ hiện sau khi mở khóa)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneCtrl,
            decoration: InputDecoration(
              labelText: 'Số điện thoại hotline (Bảo mật, chỉ hiện sau khi mở khóa)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Giới thiệu về doanh nghiệp & môi trường làm việc',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              showDialog(context: context, builder: (_) => const ChangePasswordDialog());
            },
            child: const Text('Đổi mật khẩu tài khoản'),
          ),
        ],
      ),
    );
  }
}
