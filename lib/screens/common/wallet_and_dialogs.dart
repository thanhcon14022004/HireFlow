import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final credit = context.read<CreditProvider>();
      credit.fetchBalance();
      credit.fetchTransactions();
      credit.fetchPackages();
    });
  }

  void _showBuyPackagesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const BuyPackagesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credit = context.watch<CreditProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ví Credit & Giao dịch'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              credit.fetchBalance();
              credit.fetchTransactions();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await credit.fetchBalance();
          await credit.fetchTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Số dư ví hiện tại',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('HireFlow Wallet', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppColors.accent, size: 36),
                          const SizedBox(width: 10),
                          Text(
                            '${credit.balance}',
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Text('credits', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showBuyPackagesModal,
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Nạp thêm Credit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black87,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showFeeInfoDialog(context),
                            icon: const Icon(Icons.info_outline, size: 18, color: Colors.white),
                            label: const Text('Bảng giá phí', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Lịch sử biến động Credit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // Transaction list
              if (credit.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (credit.transactions.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.history,
                  title: 'Chưa có giao dịch nào',
                  subtitle: 'Mọi hoạt động nạp, ứng tuyển hoặc mở khóa liên hệ sẽ hiển thị tại đây.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: credit.transactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = credit.transactions[index];
                    final isPositive = tx.amount > 0;
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? AppColors.success.withAlpha(38) : AppColors.error.withAlpha(38),
                          child: Icon(
                            isPositive ? Icons.add : Icons.remove,
                            color: isPositive ? AppColors.success : AppColors.error,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.formatDate(tx.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          '${isPositive ? '+' : ''}${tx.amount} credits',
                          style: TextStyle(
                            color: isPositive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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

  void _showFeeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quy định chi phí Credit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _FeeRow(label: 'Nộp hồ sơ ứng tuyển (Freelancer):', fee: '3 credits / lần'),
            _FeeRow(label: 'Đăng tin tuyển dụng (Employer):', fee: '5 credits / tin'),
            _FeeRow(label: 'Mở khóa liên hệ NTD (Freelancer):', fee: '4 credits / NTD (vĩnh viễn)'),
            _FeeRow(label: 'Tìm kiếm & xem tin dự án:', fee: 'Miễn phí'),
            _FeeRow(label: 'Xem & tải CV ứng viên:', fee: 'Miễn phí'),
            _FeeRow(label: 'Chỉnh sửa tin tuyển dụng:', fee: 'Miễn phí'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String fee;

  const _FeeRow({required this.label, required this.fee});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Text(fee, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class BuyPackagesSheet extends StatefulWidget {
  const BuyPackagesSheet({super.key});

  @override
  State<BuyPackagesSheet> createState() => _BuyPackagesSheetState();
}

class _BuyPackagesSheetState extends State<BuyPackagesSheet> {
  int? _selectedPackageId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final credit = context.watch<CreditProvider>();
    final auth = context.watch<AuthProvider>();

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
              const Text('Chọn gói nạp Credit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn gói credit phù hợp để ứng tuyển hoặc đăng tin tuyển dụng không gián đoạn.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          if (credit.packages.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            ...credit.packages.map((pkg) {
              final isSelected = _selectedPackageId == pkg.creditPackageId;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedPackageId = pkg.creditPackageId),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('${pkg.creditAmount} credits', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  trailing: Text(
                    CurrencyFormatter.formatVnd(pkg.priceAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_selectedPackageId == null || _isProcessing)
                ? null
                : () async {
                    setState(() => _isProcessing = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final success = await credit.purchasePackageAndSimulate(_selectedPackageId!);
                    if (mounted) {
                      setState(() => _isProcessing = false);
                      if (success) {
                        auth.updateCreditBalance(credit.balance);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Nạp thành công! Số dư hiện tại: ${credit.balance} credits.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(credit.errorMessage ?? 'Giao dịch thất bại'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Thanh toán & Nhận Credit ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          const Text(
            '* Trong môi trường thử nghiệm, hệ thống mô phỏng thanh toán thành công tự động.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_currentCtrl.text.isEmpty || _newCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu hiện tại và mật khẩu mới ít nhất 6 ký tự'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận mật khẩu không khớp'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final msg = await AuthService.changePassword(_currentCtrl.text, _newCtrl.text);
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới (ít nhất 6 ký tự)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận lại mật khẩu mới'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}

class ReportDialog extends StatefulWidget {
  final String targetType;
  final int targetId;
  final String title;

  const ReportDialog({super.key, required this.targetType, required this.targetId, required this.title});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _reasonCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do báo cáo'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await AdminService.submitReport(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _reasonCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Báo cáo đã được gửi tới Ban quản trị kiểm duyệt.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Báo cáo vi phạm: ${widget.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Lý do báo cáo *',
                hintText: 'Ví dụ: Lừa đảo, thông tin giả mạo, nội dung xúc phạm...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết thêm',
                hintText: 'Cung cấp thêm bằng chứng hoặc chi tiết cụ thể nếu có...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Gửi báo cáo'),
        ),
      ],
    );
  }
}
