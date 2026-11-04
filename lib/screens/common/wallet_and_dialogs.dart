import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/document_credit_and_admin_models.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/skeleton_widgets.dart';

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

  void _showBuyPackagesModal() async {
    // 1. Pick Credit Package
    final selectedPkg = await showModalBottomSheet<CreditPackageModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const BuyPackagesSheet(),
    );

    if (selectedPkg != null && mounted) {
      // 2. Pick Payment Method (MoMo vs VietQR / SepPay)
      final method = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => PaymentMethodPickerSheet(package: selectedPkg),
      );

      if (method != null && mounted) {
        final credit = context.read<CreditProvider>();
        final purchase = await credit.createPurchase(
          packageId: selectedPkg.creditPackageId > 0 ? selectedPkg.creditPackageId : null,
          customCredits: selectedPkg.creditPackageId == 0 ? selectedPkg.creditAmount : null,
          paymentProvider: method,
        );

        if (purchase != null && mounted) {
          if (method == 'MoMo') {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => MoMoPaymentDialog(purchase: purchase),
            );
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => SepPayQrPaymentDialog(purchase: purchase),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(credit.errorMessage ?? 'Không thể khởi tạo giao dịch thanh toán'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = context.watch<CreditProvider>();

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        title: const Text('Ví HireFlow Credit'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới số dư',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.secondaryLight],
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
                            style: TextStyle(color: AppColors.slate400, fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.verified, size: 13, color: AppColors.accent),
                                SizedBox(width: 4),
                                Text('HireFlow Wallet', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.accent, size: 36),
                          const SizedBox(width: 10),
                          Text(
                            '${credit.balance}',
                            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1),
                          ),
                          const SizedBox(width: 8),
                          const Text('credits', style: TextStyle(color: AppColors.slate400, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showBuyPackagesModal,
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Nạp Credit ngay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _showFeeInfoDialog(context),
                            icon: const Icon(Icons.info_outline, size: 18, color: Colors.white70),
                            label: const Text('Biểu phí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch sử biến động Credit',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${credit.transactions.length} giao dịch',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction list
              if (credit.isLoading)
                const SkeletonList(type: SkeletonType.listTile, itemCount: 4, shrinkWrap: true)
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
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? const Color(0xFFD1FAE5) : AppColors.errorLight,
                          child: Icon(
                            isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isPositive ? const Color(0xFF059669) : AppColors.red600,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          CurrencyFormatter.formatDate(tx.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          '${isPositive ? '+' : ''}${tx.amount} cr',
                          style: TextStyle(
                            color: isPositive ? const Color(0xFF059669) : AppColors.red600,
                            fontWeight: FontWeight.w900,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quy định chi phí Credit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
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
  int _customCredits = 5;
  late final TextEditingController _creditCtrl;

  @override
  void initState() {
    super.initState();
    _creditCtrl = TextEditingController(text: '$_customCredits');
  }

  @override
  void dispose() {
    _creditCtrl.dispose();
    super.dispose();
  }

  void _updateCredits(int val) {
    final clamped = val < 1 ? 1 : val;
    setState(() {
      _customCredits = clamped;
      _creditCtrl.text = '$clamped';
    });
  }

  @override
  Widget build(BuildContext context) {
    final credit = context.watch<CreditProvider>();
    final totalAmount = _customCredits * 5000.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stars_rounded, color: AppColors.accentDark, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nạp Credit HireFlow',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '5.000 VNĐ / 1 Credit',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '• Tự chọn số lượng',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Credit Selector Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Chọn số Credit bạn muốn nạp',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 12),

                        // Stepper (- / text / +)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Minus button
                            Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 1,
                              child: InkWell(
                                onTap: _customCredits > 1 ? () => _updateCredits(_customCredits - 1) : null,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 22,
                                    color: _customCredits > 1 ? AppColors.textPrimary : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),

                            // Value display with direct edit
                            Container(
                              width: 110,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: _creditCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val.trim());
                                      if (parsed != null && parsed >= 1) {
                                        setState(() => _customCredits = parsed);
                                      }
                                    },
                                  ),
                                  const Text('credits', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),

                            // Plus button
                            Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _updateCredits(_customCredits + 1),
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.add_rounded, size: 22, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildQuickChip(1, '5k'),
                            _buildQuickChip(5, '25k'),
                            _buildQuickChip(10, '50k'),
                            _buildQuickChip(20, '100k'),
                            _buildQuickChip(50, '250k'),
                            _buildQuickChip(100, '500k'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Calculation Breakdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_customCredits cr × 5.000 VNĐ',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Tổng tiền thanh toán:',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.formatVND(totalAmount),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Continue button for custom credit
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                CreditPackageModel(
                                  creditPackageId: 0,
                                  name: 'Nạp tùy chọn ($_customCredits Credits)',
                                  creditAmount: _customCredits,
                                  priceAmount: totalAmount,
                                  currencyCode: 'VND',
                                  displayOrder: 0,
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              'Nạp $_customCredits Credit • ${CurrencyFormatter.formatVND(totalAmount)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'HOẶC CHỌN GÓI CÓ SẴN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate400, letterSpacing: 0.5),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Preset packages from backend
                  if (credit.isLoading && credit.packages.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (credit.packages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Không có gói gợi ý khác.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.slate400)),
                    )
                  else
                    ...credit.packages.map((pkg) => _buildPackageCard(context, pkg)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(int amount, String shortPrice) {
    final isSelected = _customCredits == amount;
    return InkWell(
      onTap: () => _updateCredits(amount),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          '$amount cr ($shortPrice)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, CreditPackageModel pkg) {
    final isPopular = pkg.creditAmount == 20 || pkg.creditAmount == 50;
    final isBestValue = pkg.creditAmount >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPopular ? AppColors.primary : (isBestValue ? AppColors.accent : const Color(0xFFE2E8F0)),
          width: (isPopular || isBestValue) ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isPopular ? AppColors.primaryLight : AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.stars_rounded,
                color: isPopular ? AppColors.primary : AppColors.accentDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pkg.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: const Text('HOT', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
                        ),
                      ],
                      if (isBestValue) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
                          child: const Text('TIẾT KIỆM', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatVND(pkg.priceAmount),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pkg),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? AppColors.primary : const Color(0xFFF1F5F9),
                foregroundColor: isPopular ? Colors.white : AppColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Nạp ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodPickerSheet extends StatelessWidget {
  final CreditPackageModel package;

  const PaymentMethodPickerSheet({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final amountFormatted = CurrencyFormatter.formatVND(package.priceAmount);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(package.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.primary)),
                Text(amountFormatted, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Option 1: MoMo E-Wallet
          InkWell(
            onTap: () => Navigator.pop(context, 'MoMo'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD82D8B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD82D8B).withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD82D8B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Ví điện tử MoMo',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFFA50064)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCE7F3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TIỆN LỢI',
                                style: TextStyle(color: Color(0xFFA50064), fontSize: 9.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Quét mã MoMo QR hoặc chuyển qua App MoMo',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFD82D8B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: VietQR Bank Transfer
          InkWell(
            onTap: () => Navigator.pop(context, 'SepPay'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Chuyển khoản VietQR',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TỰ ĐỘNG 24/7',
                                style: TextStyle(color: AppColors.primary, fontSize: 9.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Chuyển khoản qua mã VietQR miễn phí mọi ngân hàng',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SepPayQrPaymentDialog extends StatefulWidget {
  final CreditPurchaseModel purchase;

  const SepPayQrPaymentDialog({super.key, required this.purchase});

  @override
  State<SepPayQrPaymentDialog> createState() => _SepPayQrPaymentDialogState();
}

class _SepPayQrPaymentDialogState extends State<SepPayQrPaymentDialog> {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  bool _isChecking = false;
  bool _isSuccess = false;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.purchase.remainingSeconds > 0 ? widget.purchase.remainingSeconds : 120;
    _startTimers();
  }

  void _startTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _handleExpired();
        }
      });
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPaymentStatus();
    });
  }

  void _handleExpired() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _isExpired = true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên giao dịch đã hết hạn (quá 2 phút). Giao dịch đã tự động hủy.'),
        backgroundColor: AppColors.error,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || _isSuccess || _isExpired) return;
    _isChecking = true;

    try {
      final credit = context.read<CreditProvider>();
      final auth = context.read<AuthProvider>();
      final result = await credit.checkSepPayPayment(widget.purchase.creditPurchaseId);

      if (!mounted) return;

      if (result?.status == 'Paid') {
        _isSuccess = true;
        _countdownTimer?.cancel();
        _pollTimer?.cancel();

        auth.updateCreditBalance(credit.balance);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thành công qua SepPay! Đã cộng +${widget.purchase.creditsPurchased} credits vào ví.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop();
      } else if (result?.status == 'Expired') {
        _handleExpired();
      }
    } catch (_) {
    } finally {
      _isChecking = false;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds <= 30;
    final orderCode = widget.purchase.orderCode ?? widget.purchase.providerReference ?? 'HF${widget.purchase.creditPurchaseId}';
    final bankName = widget.purchase.bankBrandName ?? 'ACB';
    final accountNum = widget.purchase.accountNumber ?? '27655931';
    final accountHolder = widget.purchase.accountHolder ?? 'HA TRUNG THANH';
    final amountFormatted = CurrencyFormatter.formatVND(widget.purchase.priceAmount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Thanh toán VietQR',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _countdownTimer?.cancel();
                      _pollTimer?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Countdown Timer Banner (2 minutes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUrgent ? AppColors.errorLight : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUrgent ? AppColors.error : AppColors.accent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: isUrgent ? AppColors.red600 : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUrgent ? 'Sắp hết hạn phiên!' : 'Thời gian phiên thanh toán:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isUrgent ? AppColors.red600 : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTimer(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isUrgent ? AppColors.red600 : const Color(0xFF92400E),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // VietQR Code Image with SepPay
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Builder(builder: (context) {
                      // Use backend proxy endpoint directly to avoid emulator DNS/SSL issues with qr.sepay.vn
                      final proxyUrl = '${ApiConstants.baseUrl}/api/credits/purchases/${widget.purchase.creditPurchaseId}/qr';
                      final directUrl = widget.purchase.qrImageUrl;

                      return Image.network(
                        proxyUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('--- SEPPAY PROXY QR LOAD ERROR: $error --- Falling back to direct URL: $directUrl');
                          if (directUrl != null && directUrl.isNotEmpty && directUrl != proxyUrl) {
                            return Image.network(
                              directUrl,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              loadingBuilder: (ctx, ch, prog) => prog == null
                                  ? ch
                                  : const SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                                    ),
                              errorBuilder: (ctx, err, st) => Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                                ),
                              ),
                            );
                          }
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Quét bằng ứng dụng Ngân hàng bất kỳ (VietQR)',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 14),

              // Account Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Ngân hàng', '$bankName (Á Châu)'),
                    const Divider(height: 12),
                    _buildCopyableRow('Số tài khoản', accountNum),
                    const Divider(height: 12),
                    _buildInfoRow('Chủ tài khoản', accountHolder),
                    const Divider(height: 12),
                    _buildCopyableRow('Số tiền', amountFormatted, rawCopy: widget.purchase.priceAmount.toInt().toString()),
                    const Divider(height: 12),
                    _buildHighlightOrderCodeRow('Nội dung chuyển khoản', orderCode),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // SepPay live status banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đang kiểm tra biến động số dư qua SepPay...',
                        style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Manual Check status button
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkPaymentStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1.5,
                ),
                icon: _isChecking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Kiểm tra trạng thái thanh toán', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCopyableRow(String label, String displayValue, {String? rawCopy}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Row(
          children: [
            Text(displayValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy, size: 15, color: AppColors.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Sao chép',
              onPressed: () => _copyToClipboard(rawCopy ?? displayValue, label),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightOrderCodeRow(String label, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.copy, size: 15, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Sao chép',
                  onPressed: () => _copyToClipboard(code, 'Nội dung chuyển khoản'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '* Bắt buộc chuyển khoản đúng nội dung trên để hệ thống tự cộng credit',
          style: TextStyle(fontSize: 10, color: AppColors.red600, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class MoMoPaymentDialog extends StatefulWidget {
  final CreditPurchaseModel purchase;

  const MoMoPaymentDialog({super.key, required this.purchase});

  @override
  State<MoMoPaymentDialog> createState() => _MoMoPaymentDialogState();
}

class _MoMoPaymentDialogState extends State<MoMoPaymentDialog> {
  static const _momoChannel = MethodChannel('com.hireflow.app/momo_launcher');

  late int _remainingSeconds;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  bool _isChecking = false;
  bool _isSuccess = false;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.purchase.remainingSeconds > 0 ? widget.purchase.remainingSeconds : 120;
    _startTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchMoMoApp();
    });
  }

  Future<void> _launchMoMoApp() async {
    final orderCode = widget.purchase.orderCode ?? widget.purchase.providerReference ?? 'MOMO_HF${widget.purchase.creditPurchaseId}';
    final amountFormatted = CurrencyFormatter.formatVND(widget.purchase.priceAmount);
    final momoPhone = widget.purchase.momoPhoneNumber ?? '0364663787';
    final deeplink = widget.purchase.deeplink ?? 'momo://app?action=payWithApp&phoneNumber=$momoPhone&amount=${widget.purchase.priceAmount.toInt()}&comment=$orderCode';

    try {
      final success = await _momoChannel.invokeMethod<bool>('openMoMoApp', {
        'amount': amountFormatted,
        'orderCode': orderCode,
        'phone': momoPhone,
        'deeplink': deeplink,
      });
      if (success != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở tự động ứng dụng MoMo. Bạn có thể bấm nút bên dưới hoặc quét mã QR.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching MoMo app: $e');
    }
  }

  void _startTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _handleExpired();
        }
      });
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPaymentStatus();
    });
  }

  void _handleExpired() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _isExpired = true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên giao dịch MoMo đã hết hạn (quá 2 phút). Giao dịch đã tự động hủy.'),
        backgroundColor: AppColors.error,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || _isSuccess || _isExpired) return;
    _isChecking = true;

    try {
      final credit = context.read<CreditProvider>();
      final auth = context.read<AuthProvider>();
      final result = await credit.checkMoMoPayment(widget.purchase.creditPurchaseId);

      if (!mounted) return;

      if (result?.status == 'Paid') {
        _isSuccess = true;
        _countdownTimer?.cancel();
        _pollTimer?.cancel();

        auth.updateCreditBalance(credit.balance);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thành công qua Ví MoMo! Đã cộng +${widget.purchase.creditsPurchased} credits vào ví.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop();
      } else if (result?.status == 'Expired') {
        _handleExpired();
      }
    } catch (_) {
    } finally {
      _isChecking = false;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFA50064),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds <= 30;
    final orderCode = widget.purchase.orderCode ?? widget.purchase.providerReference ?? 'MOMO_HF${widget.purchase.creditPurchaseId}';
    final momoPhone = widget.purchase.momoPhoneNumber ?? '0364663787';
    final accountHolder = widget.purchase.accountHolder ?? 'HA TRUNG THANH';
    final amountFormatted = CurrencyFormatter.formatVND(widget.purchase.priceAmount);

    const momoColor = Color(0xFFD82D8B);
    const momoDark = Color(0xFFA50064);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFCE7F3), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.account_balance_wallet, color: momoDark, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Thanh toán Ví MoMo',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: momoDark),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _countdownTimer?.cancel();
                      _pollTimer?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Countdown Timer Banner (2 minutes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUrgent ? AppColors.errorLight : const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUrgent ? AppColors.error : momoColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: isUrgent ? AppColors.red600 : momoDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUrgent ? 'Sắp hết hạn phiên!' : 'Thời gian phiên thanh toán:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isUrgent ? AppColors.red600 : momoDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTimer(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isUrgent ? AppColors.red600 : momoDark,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // MoMo QR Code Image
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: momoColor, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: momoColor.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.purchase.qrImageUrl != null
                        ? Image.network(
                            widget.purchase.qrImageUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(child: CircularProgressIndicator(color: momoColor)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.qr_code_2, size: 80, color: momoColor),
                                ),
                              );
                            },
                          )
                        : const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: Icon(Icons.qr_code_2, size: 80, color: momoColor)),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Mở App MoMo và Quét mã QR trên để chuyển tiền',
                  style: TextStyle(fontSize: 11.5, color: momoDark, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),

              // MoMo Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Cổng thanh toán', 'Ví MoMo (E-Wallet)'),
                    const Divider(height: 12),
                    _buildCopyableRow('Số điện thoại MoMo', momoPhone),
                    const Divider(height: 12),
                    _buildInfoRow('Tên người nhận', accountHolder),
                    const Divider(height: 12),
                    _buildCopyableRow('Số tiền', amountFormatted, rawCopy: widget.purchase.priceAmount.toInt().toString()),
                    const Divider(height: 12),
                    _buildHighlightOrderCodeRow('Lời nhắn / Mã đơn', orderCode),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // MoMo live status banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: momoDark),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đang kiểm tra biến động giao dịch qua Ví MoMo...',
                        style: TextStyle(fontSize: 11.5, color: momoDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Open MoMo App button
              ElevatedButton.icon(
                onPressed: _launchMoMoApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: momoDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1.5,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Mở ứng dụng MoMo để thanh toán', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCopyableRow(String label, String displayValue, {String? rawCopy}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Row(
          children: [
            Text(displayValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy, size: 15, color: Color(0xFFA50064)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Sao chép',
              onPressed: () => _copyToClipboard(rawCopy ?? displayValue, label),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightOrderCodeRow(String label, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD82D8B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.copy, size: 15, color: Color(0xFFA50064)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Sao chép',
                  onPressed: () => _copyToClipboard(code, 'Lời nhắn MoMo'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '* Bắt buộc nhập đúng lời nhắn trên khi chuyển tiền MoMo để hệ thống tự cộng credit',
          style: TextStyle(fontSize: 10, color: AppColors.red600, fontStyle: FontStyle.italic),
        ),
      ],
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
