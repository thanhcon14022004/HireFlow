import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/document_credit_and_admin_models.dart';
import '../../models/project_and_application_models.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common_widgets.dart';
import '../common/cv_document_viewer_screen.dart';
import '../common/google_drive_picker_modal.dart';
import '../common/wallet_and_dialogs.dart';
import '../common/chat_screen.dart';
import '../common/conversations_list_screen.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    JobSearchTab(),
    MyApplicationsTab(),
    MyCvsTab(),
    FreelancerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchUnreadCount();
      final notif = context.read<NotificationProvider>();
      notif.startPolling();
      notif.onNewNotificationReceived = (newNotif) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newNotif.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        newNotif.message,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFE2E8F0)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Xem ngay',
              textColor: const Color(0xFF34D399),
              onPressed: () {
                setState(() => _currentIndex = 1);
                context.read<ApplicationProvider>().fetchMyApplications();
              },
            ),
          ),
        );
      };
    });
  }

  void _showNotificationBottomSheet(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.fetchNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<NotificationProvider>(
          builder: (context, notif, _) {
            final list = notif.notifications;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Thông báo của bạn',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            if (notif.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${notif.unreadCount} mới',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (list.isNotEmpty && notif.unreadCount > 0)
                          TextButton(
                            onPressed: () => notif.markAllAsRead(),
                            child: const Text('Đọc tất cả', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  if (notif.isLoading && list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'Chưa có thông báo nào',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Khi Nhà tuyển dụng thay đổi trạng thái hồ sơ, thông báo sẽ xuất hiện tại đây và trên thanh trạng thái máy ảo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
                        itemBuilder: (context, i) {
                          final item = list[i];
                          return ListTile(
                            tileColor: item.isRead ? Colors.transparent : const Color(0xFFF0FDF4),
                            leading: CircleAvatar(
                              backgroundColor: item.isRead ? Colors.grey.shade100 : const Color(0xFFDCFCE7),
                              child: Icon(
                                Icons.assignment_turned_in_rounded,
                                color: item.isRead ? Colors.grey : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: item.isRead ? AppColors.textPrimary : const Color(0xFF065F46),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Text(
                                  item.message,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatDate(item.createdAt),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            trailing: !item.isRead
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  )
                                : null,
                            onTap: () {
                              notif.markAsRead(item.notificationId);
                              Navigator.pop(ctx);
                              setState(() => _currentIndex = 1);
                              context.read<ApplicationProvider>().fetchMyApplications();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HireFlow',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    auth.user?.fullName ?? 'Freelancer',
                    style: const TextStyle(
                      fontSize: 11.5,
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
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_outlined, size: 22, color: AppColors.textPrimary),
                    tooltip: 'Tin nhắn & Trao đổi',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConversationsListScreen()),
                      );
                    },
                  ),
                  if (chat.totalUnreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          chat.totalUnreadCount > 9 ? '9+' : '${chat.totalUnreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 23, color: AppColors.textPrimary),
                    tooltip: 'Thông báo',
                    onPressed: () => _showNotificationBottomSheet(context),
                  ),
                  if (notif.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          notif.unreadCount > 9 ? '9+' : '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              label: 'Tìm việc',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.primary),
              label: 'Hồ sơ đã nộp',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary),
              label: 'Quản lý CV',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

class JobSearchTab extends StatefulWidget {
  const JobSearchTab({super.key});

  @override
  State<JobSearchTab> createState() => _JobSearchTabState();
}

class _JobSearchTabState extends State<JobSearchTab> {
  final _searchCtrl = TextEditingController();
  String? _selectedSkill;
  String? _selectedExp;
  double? _minBudget;
  bool _onlySaved = false;

  final List<String> _popularSkills = [
    'Tất cả',
    'Flutter',
    'C# / .NET',
    'React',
    'Node.js',
    'SQL Server',
    'Python',
    'Docker',
    'DevOps',
    'Mobile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjects();
      context.read<CreditProvider>().fetchBalance();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter({String? search, String? skill, String? exp, double? minBudget}) {
    context.read<ProjectProvider>().fetchProjects(
          search: search ?? _searchCtrl.text.trim(),
          skill: skill ?? _selectedSkill,
          experienceLevel: exp ?? _selectedExp,
          minBudget: minBudget ?? _minBudget,
        );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedSkill != null && _selectedSkill!.isNotEmpty) count++;
    if (_selectedExp != null && _selectedExp!.isNotEmpty) count++;
    if (_minBudget != null && _minBudget! > 0) count++;
    return count;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        const Text('Bộ lọc tìm việc làm', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),

                    const Text('Cấp bậc kinh nghiệm:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Tất cả', 'Mới đi làm', 'Trung cấp (2-3 năm)', 'Cao cấp (3+ năm)', 'Chuyên gia (5+ năm)'].map((e) {
                        final val = e == 'Tất cả' ? null : e;
                        final isSel = _selectedExp == val;
                        return ChoiceChip(
                          label: Text(e),
                          selected: isSel,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setModalState(() => _selectedExp = val);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Mức ngân sách / Lương tối thiểu:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': 'Tất cả', 'val': null},
                        {'label': '< 10 Triệu', 'val': 0.0},
                        {'label': 'Từ 10 Triệu', 'val': 10000000.0},
                        {'label': 'Từ 20 Triệu', 'val': 20000000.0},
                        {'label': 'Từ 35 Triệu', 'val': 35000000.0},
                      ].map((item) {
                        final val = item['val'] as double?;
                        final isSel = _minBudget == val;
                        return ChoiceChip(
                          label: Text(item['label'] as String),
                          selected: isSel,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setModalState(() => _minBudget = val);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedExp = null;
                                _minBudget = null;
                                _selectedSkill = null;
                              });
                              setState(() {});
                              Navigator.pop(ctx);
                              _applyFilter(skill: '', exp: '', minBudget: 0);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            child: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _applyFilter();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onQuickApply(ProjectModel p) {
    if (p.hasApplied && p.myApplicationStatus != 'Rejected') {
      final statusVn = p.myApplicationStatus == 'Reviewing'
          ? 'Đang đánh giá'
          : (p.myApplicationStatus == 'Accepted' ? 'Đã duyệt' : 'Chờ xem xét');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn đã nộp hồ sơ ứng tuyển vào tin này rồi (Trạng thái: $statusVn).'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ApplyModal(projectId: p.projectId, isReapplying: p.myApplicationStatus == 'Rejected'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();

    return Column(
      children: [
        // TopCV Search & Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Tìm việc làm, kỹ năng, công ty...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _applyFilter(search: '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (val) => _applyFilter(search: val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0 ? AppColors.primaryLight : const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeFilterCount > 0 ? AppColors.primary : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: _activeFilterCount > 0 ? AppColors.primary : const Color(0xFF4B5563),
                            size: 20,
                          ),
                          tooltip: 'Bộ lọc',
                          onPressed: _showFilterModal,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Horizontal skills scroll
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        avatar: Icon(
                          _onlySaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 15,
                          color: _onlySaved ? Colors.white : AppColors.primary,
                        ),
                        label: Text(
                          'Đã lưu ()',
                        ),
                        selected: _onlySaved,
                        onSelected: (val) {
                          setState(() => _onlySaved = val);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _onlySaved ? FontWeight.w700 : FontWeight.w500,
                          color: _onlySaved ? Colors.white : AppColors.primary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: _onlySaved ? AppColors.primary : const Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    ..._popularSkills.map((s) {
                    final isAll = s == 'Tất cả';
                    final isSelected = isAll ? (_selectedSkill == null || _selectedSkill!.isEmpty) : (_selectedSkill == s);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(s),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedSkill = isAll ? null : s);
                          _applyFilter(skill: isAll ? '' : s);
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                        ),
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: const Color(0xFFF4F6F8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
                        ),
                      ),
                    );
                  }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Job Cards List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => context.read<ProjectProvider>().fetchProjects(),
            child: projectProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : projectProvider.projects.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'Không tìm thấy việc làm phù hợp',
                        subtitle: 'Hãy thử tìm kiếm với từ khóa khác hoặc điều chỉnh lại bộ lọc ngân sách/kỹ năng.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: projectProvider.projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = projectProvider.projects[index];
                          return _buildTopCvJobCard(p);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // TopCV Signature Job Card
  Widget _buildTopCvJobCard(ProjectModel p) {
    final companyName = (p.companyName != null && p.companyName!.isNotEmpty) ? p.companyName! : p.employerName;
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'H';
    final salaryShort = CurrencyFormatter.formatBudgetShort(p.budgetMin, p.budgetMax);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: p.projectId)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Company Avatar + Company Name + Title + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Avatar (Rounded Square 44x44)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title and Company Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Name with Verified Check
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 13, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Job Title
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
const SizedBox(width: 6),
                  StatusBadge(status: p.hasApplied ? (p.myApplicationStatus ?? 'Pending') : p.status, isSmall: true),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.read<ProjectProvider>().toggleSaveProject(p.projectId),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        p.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 20,
                        color: p.isSaved ? AppColors.primary : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // TopCV Trademark Tag Pills Row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Emerald Salary Pill (Focal point of TopCV)
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Experience Pill
                  if (p.experienceLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.experienceLevel!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  // Deadline / Location Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.isExpired
                          ? 'Đã hết hạn'
                          : (p.deadline != null
                              ? 'Còn ${(p.deadline!.difference(DateTime.now()).inDays).clamp(0, 999)} ngày'
                              : 'Toàn quốc'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: p.isExpired ? AppColors.error : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom Row: Skills + Quick Apply Action
              Row(
                children: [
                  // Skills preview
                  Expanded(
                    child: p.skills.isNotEmpty
                        ? Wrap(
                            spacing: 4,
                            children: p.skills.take(2).map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          )
                        : Text(
                            '${p.applicantCount} ứng viên đã nộp',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                  ),
                  // Quick Action
                  if (p.hasApplied && p.myApplicationStatus != 'Rejected')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 12.5, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            p.myApplicationStatus == 'Reviewing'
                                ? 'Đang đánh giá'
                                : (p.myApplicationStatus == 'Accepted' ? 'Đã duyệt' : 'Chờ xem xét'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    )
                  else if (p.hasApplied && p.myApplicationStatus == 'Rejected')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Text(
                            'Bị từ chối',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                          ),
                        ),
                        if (p.isOpen && !p.isExpired) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _onQuickApply(p),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Nộp lại',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  else if (p.isOpen && !p.isExpired)
                    InkWell(
                      onTap: () => _onQuickApply(p),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Ứng tuyển',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    final project = context.read<ProjectProvider>().currentProject;
    if (project != null && project.hasApplied && project.myApplicationStatus != 'Rejected') {
      final statusVn = project.myApplicationStatus == 'Reviewing'
          ? 'Đang đánh giá'
          : (project.myApplicationStatus == 'Accepted' ? 'Đã duyệt' : 'Chờ xem xét');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn đã nộp hồ sơ ứng tuyển vào tin này rồi (Trạng thái: $statusVn).'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ApplyModal(projectId: widget.projectId, isReapplying: project?.myApplicationStatus == 'Rejected'),
    );
  }



  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final credit = context.watch<CreditProvider>();
    final project = projectProvider.currentProject;

    if (projectProvider.isLoading || project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(title: const Text('Chi tiết tin tuyển dụng')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final companyName = (project.companyName != null && project.companyName!.isNotEmpty)
        ? project.companyName!
        : project.employerName;
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'H';
    final salaryShort = CurrencyFormatter.formatBudgetShort(project.budgetMin, project.budgetMax);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
title: const Text('Chi tiết công việc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              project.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: project.isSaved ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            tooltip: project.isSaved ? 'Bỏ lưu tin' : 'Lưu tin',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await context.read<ProjectProvider>().toggleSaveProject(project.projectId);
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(project.isSaved ? 'Đã bỏ lưu tin tuyển dụng' : 'Đã lưu tin tuyển dụng vào danh sách quan tâm!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.textPrimary),
            tooltip: 'Chia sẻ tin',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Dự án HireFlow: ${project.title}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép link tin tuyển dụng!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 20, color: AppColors.textSecondary),
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
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // TopCV Header Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Company Card Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        alignment: Alignment.center,
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    companyName,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                              ],
                            ),
                            Text(
                              'Đăng ngày ${CurrencyFormatter.formatDate(project.createdAt)}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: project.hasApplied ? (project.myApplicationStatus ?? 'Pending') : project.status, isSmall: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // TopCV 3 Key Metric Highlights
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        // Metric 1: Salary
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payments_outlined, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text('Mức lương', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                salaryShort,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 10),
                        // Metric 2: Experience
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.workspace_premium_outlined, size: 14, color: Color(0xFF64748B)),
                                  SizedBox(width: 4),
                                  Text('Kinh nghiệm', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project.experienceLevel ?? 'Không yêu cầu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 10),
                        // Metric 3: Deadline
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.hourglass_bottom_rounded, size: 14, color: Color(0xFF64748B)),
                                  SizedBox(width: 4),
                                  Text('Hạn nộp', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project.isExpired
                                    ? 'Hết hạn'
                                    : (project.deadline != null
                                        ? '${project.deadline!.day}/${project.deadline!.month}/${project.deadline!.year}'
                                        : 'Liên tục'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: project.isExpired ? AppColors.error : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Chi tiết việc làm'),
                  Tab(text: 'Yêu cầu kỹ năng'),
                  Tab(text: 'Liên hệ NTD'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Description
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Container(
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
                              Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Mô tả công việc & Trách nhiệm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            project.description,
                            style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.65),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                              SizedBox(width: 8),
                              Text('Lưu ý khi nộp hồ sơ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Phí ứng tuyển: 3 credits/hồ sơ.\n• Mỗi ứng viên nộp 1 lần duy nhất cho tin tuyển dụng này.\n• Hồ sơ CV của bạn sẽ được gửi trực tiếp đến hộp thư quản lý của NTD.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: Skills
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Container(
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
                              Icon(Icons.code_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Kỹ năng chuyên môn yêu cầu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (project.skills.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: project.skills.map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryContainer),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        s,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            const Text('Không có yêu cầu kỹ năng cụ thể cho vị trí này.', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),

                  // Tab 3: Contact Unlock
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: project.isContactUnlocked ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: project.isContactUnlocked ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          width: 1,
                        ),
                      ),
                      child: project.isContactUnlocked
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Thông tin liên hệ NTD (Đã mở khóa sau khi Apply):',
                                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF065F46), fontSize: 13.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (project.contactEmail != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(project.contactEmail!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 15),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: project.contactEmail!));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chép Email!')));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                if (project.contactPhone != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(project.contactPhone!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 15),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: project.contactPhone!));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chép Số điện thoại!')));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                if (project.hasApplied && project.myApplicationStatus != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Color(0xFF065F46)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Hồ sơ của bạn: ${project.myApplicationStatus}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Text(
                                  'Ghi chú: Nhà tuyển dụng đã nhận được CV của bạn. Bạn có thể chủ động liên hệ trực tiếp qua Email hoặc Số điện thoại trên.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), height: 1.35),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final chatProvider = context.read<ChatProvider>();
                                      final conv = await chatProvider.startConversation(
                                        projectId: project.projectId,
                                        employerId: project.employerId,
                                      );
                                      if (conv != null && context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              conversationId: conv.conversationId,
                                              otherPartyName: conv.otherPartyName,
                                              otherPartyRole: conv.otherPartyRole,
                                              projectTitle: conv.projectTitle,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                                    label: const Text('Nhắn tin trao đổi với NTD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cần ứng tuyển (Apply) để lấy thông tin liên hệ',
                                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 13.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Để bảo vệ thông tin liên lạc và tránh spam, hệ thống quy định ứng viên cần nộp hồ sơ ứng tuyển (Apply) vào tin tuyển dụng này trước. Sau khi ứng tuyển thành công, Số điện thoại và Email của Nhà tuyển dụng sẽ được mở khóa tự động ngay tại đây.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF78350F), height: 1.45),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: project.canApply ? _onApply : null,
                                  icon: Icon(project.myApplicationStatus == 'Rejected' ? Icons.replay_rounded : Icons.send_rounded, size: 16),
                                  label: Text(project.myApplicationStatus == 'Rejected' ? 'Nộp lại hồ sơ vào tin này' : 'Ứng tuyển ngay để lấy thông tin liên hệ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Persistent Floating Bottom Bar (TopCV Style)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Ví hiện có', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${credit.balance} cr',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: (project.hasApplied && project.myApplicationStatus != 'Rejected')
                        ? Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.hourglass_top_rounded, color: Color(0xFF2563EB), size: 15),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Đã nộp (${project.myApplicationStatus == "Pending" ? "Chờ xem xét" : (project.myApplicationStatus ?? "Chờ xem xét")})',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB), fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  final chatProvider = context.read<ChatProvider>();
                                  final conv = await chatProvider.startConversation(
                                    projectId: project.projectId,
                                    employerId: project.employerId,
                                  );
                                  if (conv != null && context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          conversationId: conv.conversationId,
                                          otherPartyName: conv.otherPartyName,
                                          otherPartyRole: conv.otherPartyRole,
                                          projectTitle: conv.projectTitle,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : (project.hasApplied && project.myApplicationStatus == 'Rejected')
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: project.isOpen && !project.isExpired ? _onApply : null,
                                      icon: const Icon(Icons.replay_rounded, size: 16),
                                      label: Text(
                                        project.isExpired ? 'Hết hạn nộp hồ sơ' : 'Nộp lại hồ sơ (3 cr)',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      final chatProvider = context.read<ChatProvider>();
                                      final conv = await chatProvider.startConversation(
                                        projectId: project.projectId,
                                        employerId: project.employerId,
                                      );
                                      if (conv != null && context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              conversationId: conv.conversationId,
                                              otherPartyName: conv.otherPartyName,
                                              otherPartyRole: conv.otherPartyRole,
                                              projectTitle: conv.projectTitle,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.chat_bubble_rounded, color: AppColors.error, size: 16),
                                          SizedBox(width: 4),
                                          Text('Chat', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: project.canApply ? _onApply : null,
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: Text(
                                  project.isExpired
                                      ? 'Hết hạn nộp hồ sơ'
                                      : (project.isOpen ? 'Ứng tuyển ngay (3 credits)' : 'Tin tuyển dụng đã đóng'),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: project.canApply ? AppColors.primary : Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplyModal extends StatefulWidget {
  final int projectId;
  final bool isReapplying;

  const ApplyModal({super.key, required this.projectId, this.isReapplying = false});

  @override
  State<ApplyModal> createState() => _ApplyModalState();
}

class _ApplyModalState extends State<ApplyModal> {
  int? _selectedDocId;
  final _coverLetterCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickTemplates = [
    '⚡ Đã có kinh nghiệm thực chiến công nghệ này',
    '🚀 Sẵn sàng bắt đầu dự án ngay hôm nay',
    '💼 Đã hoàn thành nhiều dự án tương tự chất lượng cao',
  ];

  @override
  void initState() {
    super.initState();
    final docs = context.read<DocumentProvider>();
    if (docs.defaultCv != null) {
      _selectedDocId = docs.defaultCv!.documentId;
    } else if (docs.cvs.isNotEmpty) {
      _selectedDocId = docs.cvs.first.documentId;
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

    final credit = context.read<CreditProvider>();
    if (credit.balance < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư không đủ 3 credits để ứng tuyển. Vui lòng nạp thêm.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final appProvider = context.read<ApplicationProvider>();
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
        projectProvider.markProjectApplied(widget.projectId, status: 'Pending');
        projectProvider.fetchProjects();
        projectProvider.fetchProjectDetail(widget.projectId);
        appProvider.fetchMyApplications();
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.isReapplying
                ? 'Nộp lại hồ sơ ứng tuyển thành công (-3 credits)! Trạng thái: Chờ xem xét.'
                : 'Nộp hồ sơ ứng tuyển thành công (-3 credits)! Trạng thái: Chờ xem xét.'),
            backgroundColor: AppColors.success,
          ),
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
    final credit = context.watch<CreditProvider>();

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
                Text(widget.isReapplying ? 'Nộp lại hồ sơ ứng tuyển' : 'Nộp hồ sơ ứng tuyển', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phí nộp: 3 credits (Ví hiện có: ${credit.balance} cr).',
                      style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Chọn CV nộp vào dự án *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary)),
            const SizedBox(height: 8),

            if (docs.cvs.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange.shade50,
                ),
                child: Column(
                  children: [
                    const Text('Bạn chưa có CV nào trong hệ thống.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Hãy chọn CV từ Google Drive hoặc thiết bị để tải lên và nộp hồ sơ ngay.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => GoogleDrivePickerBottomSheet.show(context),
                      icon: const Icon(Icons.add_to_drive_rounded, size: 16),
                      label: const Text('Tải CV từ Google Drive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: docs.cvs.map((d) {
                  final isSelected = _selectedDocId == d.documentId;
                  return InkWell(
                    onTap: () => setState(() => _selectedDocId = d.documentId),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.originalFileName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  CurrencyFormatter.formatFileSize(d.fileSize),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          if (d.isDefault) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                              child: const Text('CV chính', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF64748B)),
                            tooltip: 'Xem trước CV',
                            onPressed: () {
                              final auth = context.read<AuthProvider>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CvDocumentViewerScreen(
                                    document: d,
                                    candidateName: auth.user?.fullName,
                                    candidateHeadline: auth.freelancerProfile?.headline,
                                    candidateEmail: auth.user?.email,
                                    candidateSkills: auth.freelancerProfile?.skills,
                                    candidateBio: auth.freelancerProfile?.bio,
                                    candidateExperienceYears: auth.freelancerProfile?.experienceYears,
                                    canDelete: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),

            const Text('Thư giới thiệu (Cover Letter)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            // Quick suggestion chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickTemplates.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: ActionChip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF4F6F8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Color(0xFFE5E7EB))),
                      onPressed: () {
                        if (_coverLetterCtrl.text.isEmpty) {
                          _coverLetterCtrl.text = t;
                        } else {
                          _coverLetterCtrl.text = '${_coverLetterCtrl.text}\n$t';
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _coverLetterCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Giới thiệu ngắn gọn kinh nghiệm liên quan và cam kết của bạn đối với vị trí này...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: (docs.cvs.isEmpty || _isSubmitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.isReapplying ? 'Nộp lại hồ sơ ngay (-3 credits)' : 'Nộp hồ sơ ứng tuyển (-3 credits)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().fetchMyApplications();
    });
  }

  void _showWithdrawDialog(ApplicationModel app) {
    String selectedReason = 'Đã tìm được công việc khác';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isPending = app.status == 'Pending';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Rút hồ sơ ứng tuyển', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn có chắc chắn muốn rút hồ sơ ứng tuyển vào dự án "${app.projectTitle}"?',
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 10),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hồ sơ đang ở trạng thái Chờ xem xét, bạn sẽ được hoàn lại 1 credit khi rút hồ sơ.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    const Text('Lý do rút hồ sơ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...[
                      'Đã tìm được công việc khác',
                      'Bận đột xuất / Trùng lịch làm việc',
                      'Mức lương hoặc yêu cầu không còn phù hợp',
                      'Lý do cá nhân khác',
                    ].map((r) {
                      final isSelected = selectedReason == r;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 18,
                                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(r, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    final credit = context.read<CreditProvider>();
                    final appProv = context.read<ApplicationProvider>();
                    Navigator.pop(ctx);
                    try {
                      final res = await appProv.withdrawApplication(
                        app.applicationId,
                        reason: selectedReason,
                      );
                      credit.fetchBalance();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(res['message']?.toString() ?? 'Đã rút hồ sơ thành công.'),
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                      );
                    } catch (e) {
                      scaffold.showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  },
                  child: const Text('Xác nhận rút'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStatusTimeline(ApplicationModel app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiến trình hồ sơ ứng tuyển', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(
                app.projectTitle,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('Thời gian nộp: ${CurrencyFormatter.formatDate(app.appliedAt)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              if (app.statusHistories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hồ sơ đang ở trạng thái Chờ xem xét (Pending). Nhà tuyển dụng sẽ sớm phản hồi.',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...app.statusHistories.map((h) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chuyển sang: ${h.newStatus}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              Text(
                                '${CurrencyFormatter.formatDate(h.changedAt)} • Thực hiện bởi ${h.changedByUserName}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // TopCV 4-Stage Visual Application Progress Tracker
  Widget _buildTopCvApplicationProgressTracker(String status) {
    // Stage mapping
    // 1: Pending (Đã nộp)
    // 2: Reviewing (Đang đánh giá)
    // 3: Shortlisted (Mời phỏng vấn)
    // 4: Accepted / Rejected (Kết quả)
    int currentStep = 1;
    bool isRejected = false;

    final lower = status.toLowerCase();
    if (lower == 'withdrawn') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hồ sơ này đã được bạn chủ động rút.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (lower == 'reviewing') {
      currentStep = 2;
    } else if (lower == 'shortlisted') {
      currentStep = 3;
    } else if (lower == 'accepted') {
      currentStep = 4;
    } else if (lower == 'rejected') {
      currentStep = 4;
      isRejected = true;
    }

    final steps = [
      'Đã nộp',
      'Đang đánh giá',
      'Phỏng vấn',
      isRejected ? 'Từ chối' : 'Trúng tuyển',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (idx) {
          if (idx.isOdd) {
            // Connecting line
            final stepIndex = idx ~/ 2;
            final isLineActive = stepIndex < currentStep - 1;
            return Expanded(
              child: Container(
                height: 2,
                color: isLineActive ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
            );
          } else {
            // Step node
            final stepIndex = idx ~/ 2;
            final isCompleted = stepIndex < currentStep - 1;
            final isCurrent = stepIndex == currentStep - 1;
            final nodeColor = isCurrent
                ? (isRejected && stepIndex == 3 ? AppColors.error : AppColors.primary)
                : (isCompleted ? AppColors.primary : const Color(0xFFCBD5E1));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: (isCurrent || isCompleted) ? nodeColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 3),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? (isRejected && stepIndex == 3 ? AppColors.error : AppColors.primary)
                        : (isCompleted ? AppColors.textPrimary : const Color(0xFF94A3B8)),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();

    if (appProvider.isLoading && appProvider.myApplications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _statusFilter == null
        ? appProvider.myApplications
        : appProvider.myApplications.where((a) => a.status.toLowerCase() == _statusFilter!.toLowerCase()).toList();

    return Column(
      children: [
        // Filter tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả (${appProvider.myApplications.length})', null),
                _buildFilterChip('Chờ xem xét', 'Pending'),
                _buildFilterChip('Đang đánh giá', 'Reviewing'),
                _buildFilterChip('Mời phỏng vấn', 'Shortlisted'),
                _buildFilterChip('Trúng tuyển', 'Accepted'),
                _buildFilterChip('Từ chối', 'Rejected'),
                _buildFilterChip('Đã rút', 'Withdrawn'),
              ],
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => appProvider.fetchMyApplications(),
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: 'Chưa có hồ sơ ứng tuyển nào',
                    subtitle: 'Hãy khám phá các dự án IT hấp dẫn trong tab "Tìm việc" và nộp hồ sơ ngay.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                      app.projectTitle,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: app.status, isSmall: true),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'CV nộp: ${app.originalFileName}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatDate(app.appliedAt),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    '"${app.coverLetter!}"',
                                    style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              // TopCV 4-Stage Progress Tracker
                              _buildTopCvApplicationProgressTracker(app.status),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showStatusTimeline(app),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.timeline_rounded, size: 15, color: Color(0xFF475569)),
                                    label: const Text('Tiến trình chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: app.projectId)),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Xem tin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                                  ),
                                  if (app.canWithdraw) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _showWithdrawDialog(app),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.undo_rounded, size: 13, color: Color(0xFFDC2626)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Rút hồ sơ',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (app.status == 'Rejected') ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                          builder: (ctx) => ApplyModal(projectId: app.projectId, isReapplying: true),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.replay_rounded, size: 13, color: Colors.white),
                                            SizedBox(width: 3),
                                            Text('Nộp lại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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
        backgroundColor: const Color(0xFFF4F6F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}

class MyCvsTab extends StatefulWidget {
  const MyCvsTab({super.key});

  @override
  State<MyCvsTab> createState() => _MyCvsTabState();
}

class _MyCvsTabState extends State<MyCvsTab> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchCvs();
    });
  }

  void _openCvViewer(DocumentModel cv) {
    final auth = context.read<AuthProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CvDocumentViewerScreen(
          document: cv,
          candidateName: auth.user?.fullName,
          candidateHeadline: auth.freelancerProfile?.headline,
          candidateEmail: auth.user?.email,
          candidateSkills: auth.freelancerProfile?.skills,
          candidateBio: auth.freelancerProfile?.bio,
          candidateExperienceYears: auth.freelancerProfile?.experienceYears,
          canDelete: true,
        ),
      ),
    );
  }

  void _openGoogleDrivePicker() {
    GoogleDrivePickerBottomSheet.show(context);
  }

  void _pickAndUpload() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.xFile.readAsBytes();

        if (!mounted) return;
        setState(() => _isUploading = true);
        final docProvider = context.read<DocumentProvider>();
        final auth = context.read<AuthProvider>();
        final messenger = ScaffoldMessenger.of(context);
        final email = auth.user?.email ?? 'freelancer@hireflow.com';

        // Automatically add/sync to user's Google Drive storage for their email!
        await GoogleDriveStorageService.addFile(
          email,
          DriveCvFile(
            name: file.name,
            size: CurrencyFormatter.formatFileSize(bytes.length),
            modified: 'Hôm nay',
            title: 'CV Đã đồng bộ từ thiết bị',
            fileBytes: bytes,
          ),
        );

        final newDoc = await docProvider.uploadCvAndReturn(bytes, file.name);
        if (mounted) {
          setState(() => _isUploading = false);
          if (newDoc != null) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Tải lên CV PDF thành công & đã lưu vào Google Drive! Đang mở tài liệu...'), backgroundColor: AppColors.success),
            );
            _openCvViewer(newDoc);
          } else {
            messenger.showSnackBar(
              SnackBar(content: Text(docProvider.errorMessage ?? 'Tải file thất bại'), backgroundColor: AppColors.error),
            );
          }
        }
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() => _isUploading = false);
        GoogleDrivePickerBottomSheet.showDriveOfflineHelp(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể nạp tệp: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: () => docProvider.fetchCvs(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TopCV Upload Banner
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tải lên CV bản PDF mới',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Định dạng PDF chuẩn, tối đa 5MB. Quản lý nhiều phiên bản CV để ứng tuyển cho từng vị trí phù hợp nhất.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openGoogleDrivePicker,
                          icon: const Icon(Icons.add_to_drive_rounded, size: 18),
                          label: const Text('Tải từ Google Drive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUpload,
                          icon: _isUploading
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.file_upload_outlined, size: 18),
                          label: Text(_isUploading ? 'Đang tải...' : 'Chọn từ thiết bị'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Danh sách CV của bạn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('${docProvider.cvs.length} CV', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),

              if (docProvider.isLoading && docProvider.cvs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (docProvider.cvs.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.description_outlined,
                  title: 'Chưa có CV nào được tải lên',
                  subtitle: 'Hãy tải lên bản CV PDF đầu tiên để bắt đầu ứng tuyển các công việc IT hấp dẫn.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docProvider.cvs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cv = docProvider.cvs[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cv.isDefault ? AppColors.primary : const Color(0xFFE5E7EB),
                          width: cv.isDefault ? 1.4 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _openCvViewer(cv),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cv.originalFileName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (cv.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                child: const Text('CV chính', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${CurrencyFormatter.formatFileSize(cv.fileSize)} • Tải lên: ${CurrencyFormatter.formatDate(cv.uploadedAt)}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'view') {
                              _openCvViewer(cv);
                            } else if (val == 'default') {
                              await docProvider.setDefaultCv(cv.documentId);
                            } else if (val == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Xóa CV này?'),
                                  content: Text('Bạn có chắc muốn xóa "${cv.originalFileName}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                final success = await docProvider.deleteCv(cv.documentId);
                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã xóa "${cv.originalFileName}" thành công!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(docProvider.errorMessage ?? 'Xóa CV thất bại'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Xem nội dung CV'),
                                ],
                              ),
                            ),
                            if (!cv.isDefault)
                              const PopupMenuItem(value: 'default', child: Text('Đặt làm CV chính')),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa CV này', style: TextStyle(color: Colors.red))),
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

class FreelancerProfileTab extends StatefulWidget {
  const FreelancerProfileTab({super.key});

  @override
  State<FreelancerProfileTab> createState() => _FreelancerProfileTabState();
}

class _FreelancerProfileTabState extends State<FreelancerProfileTab> {
  final List<String> _suggestedSkills = [
    'Flutter',
    'Dart',
    'C#',
    '.NET Core',
    'SQL Server',
    'React',
    'Node.js',
    'Python',
    'Docker',
    'DevOps',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  void _showEditProfileModal() {
    final auth = context.read<AuthProvider>();
    final p = auth.freelancerProfile;
    final nameCtrl = TextEditingController(text: auth.user?.fullName);
    final headlineCtrl = TextEditingController(text: p?.headline);
    final bioCtrl = TextEditingController(text: p?.bio);
    final expCtrl = TextEditingController(text: p?.experienceYears?.toString() ?? '2');
    final skills = List<String>.from(p?.skills ?? []);
    final skillInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        const Text('Cập nhật hồ sơ năng lực', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Họ và tên *', hintText: 'Nhập họ và tên đầy đủ'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: headlineCtrl,
                      decoration: const InputDecoration(labelText: 'Chức danh nghề nghiệp', hintText: 'vd: Senior Flutter & .NET Developer'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số năm kinh nghiệm', suffixText: 'năm'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Giới thiệu bản thân & Điểm mạnh'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Kỹ năng chuyên môn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _suggestedSkills.map((sk) {
                          final isAdded = skills.contains(sk);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 6),
                            child: ActionChip(
                              label: Text(sk, style: TextStyle(fontSize: 11, color: isAdded ? Colors.grey : AppColors.primary)),
                              avatar: isAdded ? const Icon(Icons.check, size: 12, color: Colors.green) : const Icon(Icons.add, size: 12, color: AppColors.primary),
                              onPressed: isAdded
                                  ? null
                                  : () {
                                      setModalState(() => skills.add(sk));
                                    },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skillInputCtrl,
                            decoration: const InputDecoration(hintText: 'Nhập kỹ năng khác (vd: Docker, AWS)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final sk = skillInputCtrl.text.trim();
                            if (sk.isNotEmpty && !skills.contains(sk)) {
                              setModalState(() {
                                skills.add(sk);
                                skillInputCtrl.clear();
                              });
                            }
                          },
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.map((s) {
                          return Chip(
                            label: Text(s, style: const TextStyle(fontSize: 11.5)),
                            onDeleted: () => setModalState(() => skills.remove(s)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final exp = int.tryParse(expCtrl.text);
                        final success = await auth.updateFreelancerProfile(
                          fullName: nameCtrl.text.trim(),
                          headline: headlineCtrl.text.trim(),
                          bio: bioCtrl.text.trim(),
                          experienceYears: exp,
                          skills: skills,
                        );
                        if (success) {
                          nav.pop();
                          messenger.showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: AppColors.success));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Lưu thông tin hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final credit = context.watch<CreditProvider>();
    final p = auth.freelancerProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card (TopCV Style)
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
                  child: Text(
                    auth.user?.fullName.isNotEmpty == true ? auth.user!.fullName[0].toUpperCase() : 'F',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  auth.user?.fullName ?? '',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                Text(
                  p?.headline ?? 'Chưa cập nhật chức danh nghề nghiệp',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                Text(
                  auth.user?.email ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showEditProfileModal,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Chỉnh sửa hồ sơ'),
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

          // Experience & Skills
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kỹ năng & Chuyên môn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(
                      '${p?.experienceYears ?? 0} năm kinh nghiệm',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (p?.skills.isNotEmpty == true)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p!.skills.map((s) {
                      return Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFFF4F6F8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide.none),
                      );
                    }).toList(),
                  )
                else
                  const Text('Chưa có kỹ năng nào. Nhấn "Chỉnh sửa hồ sơ" để thêm.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                if (p?.bio != null && p!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Giới thiệu tóm tắt:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(p.bio!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4)),
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
                  leading: const Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 20),
                  title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                  onTap: () => showDialog(context: context, builder: (_) => const ChangePasswordDialog()),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB)),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red, size: 20),
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
}
