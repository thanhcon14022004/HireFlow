import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';
import '../common/wallet_and_dialogs.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProjectSearchTab(),
    MyApplicationsTab(),
    CvManagementTab(),
    FreelancerProfileTab(),
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
            const Icon(Icons.work, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('HireFlow', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
          NavigationDestination(icon: Icon(Icons.search), label: 'Tìm việc'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Ứng tuyển'),
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'CV của tôi'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

class ProjectSearchTab extends StatefulWidget {
  const ProjectSearchTab({super.key});

  @override
  State<ProjectSearchTab> createState() => _ProjectSearchTabState();
}

class _ProjectSearchTabState extends State<ProjectSearchTab> {
  final _searchCtrl = TextEditingController();
  String? _selectedSkill;
  String? _selectedExp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<ProjectProvider>().fetchProjects(
          keyword: _searchCtrl.text.trim(),
          skill: _selectedSkill,
          experienceLevel: _selectedExp,
        );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm theo vị trí, kỹ năng (vd: Flutter, .NET, React)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearch();
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _onSearch(),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả kỹ năng'),
                      selected: _selectedSkill == null,
                      onSelected: (_) {
                        setState(() => _selectedSkill = null);
                        _onSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Flutter'),
                      selected: _selectedSkill == 'Flutter',
                      onSelected: (val) {
                        setState(() => _selectedSkill = val ? 'Flutter' : null);
                        _onSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('.NET'),
                      selected: _selectedSkill == '.NET',
                      onSelected: (val) {
                        setState(() => _selectedSkill = val ? '.NET' : null);
                        _onSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('React'),
                      selected: _selectedSkill == 'React',
                      onSelected: (val) {
                        setState(() => _selectedSkill = val ? 'React' : null);
                        _onSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('SQL Server'),
                      selected: _selectedSkill == 'SQL Server',
                      onSelected: (val) {
                        setState(() => _selectedSkill = val ? 'SQL Server' : null);
                        _onSearch();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Project list
        Expanded(
          child: projectProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : projectProvider.projects.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'Không tìm thấy dự án phù hợp',
                      subtitle: 'Thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.',
                      buttonText: 'Làm mới',
                      onButtonPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _selectedSkill = null;
                          _selectedExp = null;
                        });
                        _onSearch();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _onSearch(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: projectProvider.projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final project = projectProvider.projects[index];
                          return Card(
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.projectId)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            project.title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: project.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      project.companyName ?? project.employerName,
                                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      project.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: project.skills.map((s) => Chip(
                                        label: Text(s, style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          CurrencyFormatter.formatBudget(project.budgetMin, project.budgetMax),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text('${project.applicantCount} ứng viên', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjectDetail(widget.projectId);
      context.read<DocumentProvider>().fetchCvs();
    });
  }

  void _onApply() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ApplyModal(projectId: widget.projectId),
    );
  }

  void _onUnlockContact() async {
    final credit = context.read<CreditProvider>();
    final auth = context.read<AuthProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mở khóa liên hệ Nhà tuyển dụng'),
        content: const Text('Chi phí: 4 credits. Sau khi mở khóa, bạn có thể xem số điện thoại và email của nhà tuyển dụng này vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black87),
            child: const Text('Mở khóa (-4 credits)'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final projectProvider = context.read<ProjectProvider>();
      final contact = await credit.unlockContact(widget.projectId);
      if (contact != null && mounted) {
        auth.updateCreditBalance(credit.balance);
        projectProvider.fetchProjectDetail(widget.projectId);
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã mở khóa thông tin liên hệ thành công!'), backgroundColor: AppColors.success),
        );
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(credit.errorMessage ?? 'Mở khóa thất bại'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.currentProject;

    if (projectProvider.isLoading || project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết dự án')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết dự án'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Báo cáo vi phạm',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ReportDialog(
                  targetType: 'Project',
                  targetId: project.projectId,
                  title: project.title,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        StatusBadge(status: project.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.companyName ?? project.employerName,
                      style: const TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MetaBadge(icon: Icons.attach_money, text: CurrencyFormatter.formatBudget(project.budgetMin, project.budgetMax)),
                        const SizedBox(width: 12),
                        if (project.experienceLevel != null)
                          _MetaBadge(icon: Icons.trending_up, text: project.experienceLevel!),
                      ],
                    ),
                    if (project.deadline != null) ...[
                      const SizedBox(height: 8),
                      _MetaBadge(icon: Icons.calendar_today, text: 'Hạn nộp: ${CurrencyFormatter.formatDateOnly(project.deadline)}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mô tả công việc & yêu cầu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      project.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text('Kỹ năng yêu cầu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: project.skills.map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.primaryLight,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Employer Contact Card (Unlock with 4 credits)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thông tin liên hệ Nhà tuyển dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (project.isContactUnlocked)
                          const Chip(
                            label: Text('Đã mở khóa', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            backgroundColor: Color(0xFFDEF7EC),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (project.isContactUnlocked) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email, color: AppColors.primary),
                        title: const Text('Email liên hệ'),
                        subtitle: SelectableText(project.contactEmail ?? 'Chưa cập nhật', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (project.contactPhone != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone, color: AppColors.primary),
                          title: const Text('Số điện thoại'),
                          subtitle: SelectableText(project.contactPhone!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ] else ...[
                      const Text(
                        'Thông tin liên hệ (Email, SĐT) được bảo mật. Mở khóa với 4 credit để liên hệ trực tiếp với nhà tuyển dụng.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _onUnlockContact,
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text('Mở khóa liên hệ (4 credits)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: project.hasApplied
            ? Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEF7EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF03543F)),
                    const SizedBox(width: 8),
                    Text(
                      'Bạn đã nộp hồ sơ (Trạng thái: ${project.myApplicationStatus})',
                      style: const TextStyle(color: Color(0xFF03543F), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: project.isOpen ? _onApply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  project.isOpen ? 'Ứng tuyển ngay (Phí: 3 credits)' : 'Dự án đã đóng ứng tuyển',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class ApplyModal extends StatefulWidget {
  final int projectId;

  const ApplyModal({super.key, required this.projectId});

  @override
  State<ApplyModal> createState() => _ApplyModalState();
}

class _ApplyModalState extends State<ApplyModal> {
  int? _selectedDocId;
  final _coverLetterCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final docs = context.read<DocumentProvider>();
    if (docs.defaultCv != null) {
      _selectedDocId = docs.defaultCv!.documentId;
    }
  }

  @override
  void dispose() {
    _coverLetterCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một CV PDF để nộp hồ sơ'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final appProvider = context.read<ApplicationProvider>();
    final credit = context.read<CreditProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final projectProvider = context.read<ProjectProvider>();

    setState(() => _isSubmitting = true);
    final success = await appProvider.applyProject(
      widget.projectId,
      documentId: _selectedDocId!,
      coverLetter: _coverLetterCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        await credit.fetchBalance();
        auth.updateCreditBalance(credit.balance);
        projectProvider.fetchProjectDetail(widget.projectId);
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Nộp hồ sơ ứng tuyển thành công (-3 credits)!'), backgroundColor: AppColors.success),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(appProvider.errorMessage ?? 'Ứng tuyển thất bại'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = context.watch<DocumentProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nộp hồ sơ ứng tuyển', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Phí ứng tuyển: 3 credits. Bạn chỉ nộp được 1 lần cho mỗi dự án.',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // CV Selection
          const Text('Chọn CV nộp ứng tuyển *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),

          if (docs.cvs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(10),
                color: Colors.orange.shade50,
              ),
              child: const Text('Bạn chưa có CV nào trong hệ thống. Vui lòng vào tab "CV của tôi" để tải lên file PDF trước khi ứng tuyển.'),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _selectedDocId,
              items: docs.cvs.map((d) {
                return DropdownMenuItem<int>(
                  value: d.documentId,
                  child: Text('${d.originalFileName} (${d.formattedSize})${d.isDefault ? " [Mặc định]" : ""}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDocId = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
            ),

          const SizedBox(height: 16),
          TextField(
            controller: _coverLetterCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Thư giới thiệu / Lời nhắn tới nhà tuyển dụng (tùy chọn)',
              hintText: 'Giới thiệu ngắn gọn kinh nghiệm liên quan và lý do bạn phù hợp với dự án...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_selectedDocId == null || _isSubmitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Xác nhận nộp hồ sơ (-3 credits)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class MyApplicationsTab extends StatefulWidget {
  const MyApplicationsTab({super.key});

  @override
  State<MyApplicationsTab> createState() => _MyApplicationsTabState();
}

class _MyApplicationsTabState extends State<MyApplicationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();

    if (appProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appProvider.myApplications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'Chưa ứng tuyển dự án nào',
        subtitle: 'Khám phá các dự án freelance hấp dẫn và nộp hồ sơ ngay hôm nay.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => appProvider.fetchMyApplications(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appProvider.myApplications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final app = appProvider.myApplications[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app.projectTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      StatusBadge(status: app.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('CV đã nộp: ${app.originalFileName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'Thư giới thiệu: "${app.coverLetter!}"',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nộp lúc: ${CurrencyFormatter.formatDate(app.appliedAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: app.projectId)),
                          );
                        },
                        child: const Text('Xem tin dự án', style: TextStyle(fontSize: 12)),
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

class CvManagementTab extends StatefulWidget {
  const CvManagementTab({super.key});

  @override
  State<CvManagementTab> createState() => _CvManagementTabState();
}

class _CvManagementTabState extends State<CvManagementTab> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchCvs();
    });
  }

  void _pickAndUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      setState(() => _isUploading = true);
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final docProvider = context.read<DocumentProvider>();
      final success = await docProvider.uploadCv(bytes, file.name);

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải lên CV PDF thành công!'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(docProvider.errorMessage ?? 'Tải tệp thất bại'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload button
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickAndUpload,
            icon: _isUploading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Đang tải lên...' : 'Tải lên CV mới (Định dạng PDF, tối đa 5MB)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // CV list
          Expanded(
            child: docProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : docProvider.cvs.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.picture_as_pdf,
                        title: 'Chưa có CV nào',
                        subtitle: 'Hãy tải lên CV PDF của bạn để sẵn sàng ứng tuyển các dự án chất lượng.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => docProvider.fetchCvs(),
                        child: ListView.separated(
                          itemCount: docProvider.cvs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cv = docProvider.cvs[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFDE8E8),
                                  child: Icon(Icons.picture_as_pdf, color: Colors.red),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(cv.originalFileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                    if (cv.isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Mặc định', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${cv.formattedSize} • Tải lên: ${CurrencyFormatter.formatDate(cv.uploadedAt)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'default') docProvider.setDefault(cv.documentId);
                                    if (val == 'delete') docProvider.deleteCv(cv.documentId);
                                  },
                                  itemBuilder: (_) => [
                                    if (!cv.isDefault)
                                      const PopupMenuItem(value: 'default', child: Text('Đặt làm mặc định')),
                                    const PopupMenuItem(value: 'delete', child: Text('Xóa CV', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class FreelancerProfileTab extends StatefulWidget {
  const FreelancerProfileTab({super.key});

  @override
  State<FreelancerProfileTab> createState() => _FreelancerProfileTabState();
}

class _FreelancerProfileTabState extends State<FreelancerProfileTab> {
  final _headlineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _skillInputCtrl = TextEditingController();
  final List<String> _skills = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final p = await ProfileService.getFreelancerProfile();
      if (mounted) {
        setState(() {
          _headlineCtrl.text = p.headline ?? '';
          _bioCtrl.text = p.bio ?? '';
          _expCtrl.text = p.experienceYears?.toString() ?? '';
          _skills.clear();
          _skills.addAll(p.skills);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final exp = int.tryParse(_expCtrl.text);
      await ProfileService.updateFreelancerProfile(
        headline: _headlineCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        experienceYears: exp,
        skills: _skills,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
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
            controller: _headlineCtrl,
            decoration: InputDecoration(
              labelText: 'Tiêu đề nghề nghiệp / Chuyên môn',
              hintText: 'Ví dụ: Senior Mobile App Developer (Flutter & iOS)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số năm kinh nghiệm',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Giới thiệu bản thân & Thành tựu nổi bật',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Skills
          const Text('Kỹ năng chuyên môn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputCtrl,
                  decoration: InputDecoration(
                    hintText: 'Nhập kỹ năng (vd: Dart, SQL, REST)...',
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
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu thông tin hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
