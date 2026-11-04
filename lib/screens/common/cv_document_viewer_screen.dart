import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/document_credit_and_admin_models.dart';
import '../../models/project_and_application_models.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';

class CvDocumentViewerScreen extends StatefulWidget {
  final DocumentModel document;
  final String? candidateName;
  final String? candidateHeadline;
  final String? candidateEmail;
  final String? candidatePhone;
  final List<String>? candidateSkills;
  final String? candidateBio;
  final int? candidateExperienceYears;
  final bool canDelete;

  const CvDocumentViewerScreen({
    super.key,
    required this.document,
    this.candidateName,
    this.candidateHeadline,
    this.candidateEmail,
    this.candidatePhone,
    this.candidateSkills,
    this.candidateBio,
    this.candidateExperienceYears,
    this.canDelete = false,
  });

  factory CvDocumentViewerScreen.fromApplication({
    Key? key,
    required ApplicationModel application,
  }) {
    return CvDocumentViewerScreen(
      key: key,
      document: DocumentModel(
        documentId: application.documentId,
        originalFileName: application.originalFileName,
        contentType: 'application/pdf',
        fileSize: 154200,
        isDefault: true,
        uploadedAt: application.appliedAt,
      ),
      candidateName: application.freelancerName,
      candidateHeadline: application.freelancerHeadline,
      candidateSkills: application.freelancerSkills,
      candidateBio: application.freelancerBio,
      candidateExperienceYears: application.freelancerExperienceYears,
      canDelete: false,
    );
  }

  @override
  State<CvDocumentViewerScreen> createState() => _CvDocumentViewerScreenState();
}

class _CvDocumentViewerScreenState extends State<CvDocumentViewerScreen> {
  final TransformationController _transformCtrl = TransformationController();
  double _scale = 1.0;
  bool _isDownloading = false;

  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.2).clamp(0.8, 2.5);
      _transformCtrl.value = Matrix4.diagonal3Values(_scale, _scale, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.2).clamp(0.8, 2.5);
      _transformCtrl.value = Matrix4.diagonal3Values(_scale, _scale, 1.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _transformCtrl.value = Matrix4.identity();
    });
  }

  void _downloadDocument() async {
    setState(() => _isDownloading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final bytes = await DocumentService.downloadCv(widget.document.documentId);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Đã tải xuống "${widget.document.originalFileName}" (${CurrencyFormatter.formatFileSize(bytes.length)}) thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        nav.pop(); // Tải thành công -> Quay lại trang quản lý CV
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Không thể tải tệp: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _shareDocument() {
    Clipboard.setData(ClipboardData(text: 'Hồ sơ CV HireFlow: ${widget.document.originalFileName} (Mã: #HF-${widget.document.documentId})'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết tài liệu CV vào bộ nhớ tạm!')),
    );
  }

  void _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa CV này?'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn "${widget.document.originalFileName}" khỏi hệ thống HireFlow?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final docProvider = context.read<DocumentProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      final success = await docProvider.deleteCv(widget.document.documentId);
      if (mounted) {
        if (success) {
          nav.pop(); // Close viewer
          messenger.showSnackBar(
            SnackBar(
              content: Text('Đã xóa thành công "${widget.document.originalFileName}"!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(docProvider.errorMessage ?? 'Không thể xóa CV này'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.candidateName != null && widget.candidateName!.isNotEmpty)
        ? widget.candidateName!
        : 'Nguyễn Văn An';
    final headline = (widget.candidateHeadline != null && widget.candidateHeadline!.isNotEmpty)
        ? widget.candidateHeadline!
        : 'Senior Mobile & Fullstack Engineer (Flutter / .NET)';
    final email = widget.candidateEmail ?? 'freelancer@hireflow.com';
    final phone = widget.candidatePhone ?? '0909 123 456';
    final expYears = widget.candidateExperienceYears ?? 5;
    final skills = (widget.candidateSkills != null && widget.candidateSkills!.isNotEmpty)
        ? widget.candidateSkills!
        : ['Flutter', 'Dart', 'C#', '.NET 8', 'SQL Server', 'Docker', 'Azure', 'RESTful API', 'Git'];

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.document.originalFileName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${CurrencyFormatter.formatFileSize(widget.document.fileSize)} • HireFlow',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: _isDownloading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'Tải về máy',
            onPressed: _isDownloading ? null : _downloadDocument,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
            tooltip: 'Chia sẻ',
            onPressed: _shareDocument,
          ),
          if (widget.canDelete)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
              tooltip: 'Xóa CV này',
              onPressed: _deleteDocument,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Notice banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFE8F8EE),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Đang xem hồ sơ CV trực tiếp trên HireFlow (Chế độ xem A4 chuẩn).',
                    style: TextStyle(color: Color(0xFF065F46), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${(_scale * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),

          // Zoomable Document Canvas
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.8,
              maxScale: 2.5,
              onInteractionEnd: (_) {
                setState(() {
                  _scale = _transformCtrl.value.getMaxScaleOnAxis();
                });
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 620),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 6)),
                      ],
                    ),
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TopCV Header
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, size: 12, color: Colors.white),
                                        SizedBox(width: 3),
                                        Text('VERIFIED CV', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                headline,
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFF334155)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 14,
                                runSpacing: 4,
                                children: [
                                  _buildContactItem(Icons.email_outlined, email),
                                  _buildContactItem(Icons.phone_outlined, phone),
                                  _buildContactItem(Icons.location_on_outlined, 'Việt Nam • Sẵn sàng Remote / Hybrid'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Objective
                        _buildSectionHeader('MỤC TIÊU NGHỀ NGHIỆP', Icons.flag_rounded),
                        const SizedBox(height: 6),
                        Text(
                          widget.candidateBio ??
                              'Lập trình viên với hơn $expYears năm kinh nghiệm thực chiến phát triển phần mềm di động và dịch vụ đám mây. Đam mê xây dựng ứng dụng với Clean Architecture, tối ưu hóa trải nghiệm người dùng, độ trễ thấp và bảo mật cao. Mong muốn cống hiến giá trị công nghệ vượt trội cho các dự án quy mô lớn.',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.55),
                        ),
                        const SizedBox(height: 18),

                        // Section 2: Work Experience
                        _buildSectionHeader('KINH NGHIỆM LÀM VIỆC & DỰ ÁN', Icons.work_rounded),
                        const SizedBox(height: 10),
                        _buildExperienceItem(
                          role: 'Senior Mobile & Fullstack Engineer',
                          company: 'TechNova Solutions VN',
                          period: '06/2022 - Hiện tại',
                          bullets: [
                            'Chủ trì kiến trúc ứng dụng Mobile đa nền tảng Flutter & Dart với hơn 300,000 người dùng hàng tháng.',
                            'Tích hợp Microservices backend trên .NET 8, SQL Server, Redis Cache và Docker.',
                            'Tích hợp các cổng thanh toán điện tử (MoMo, VietQR SepPay) với tỷ lệ giao dịch thành công 99.9%.',
                            'Tối ưu hóa thời gian khởi động app giảm 40%, áp dụng BLoC / Provider và CI/CD tự động.',
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExperienceItem(
                          role: 'Mobile Software Developer',
                          company: 'Global IT Innovations JSC',
                          period: '01/2020 - 05/2022',
                          bullets: [
                            'Phát triển ứng dụng thương mại điện tử và logistics trên nền tảng Flutter (Android & iOS).',
                            'Xây dựng RESTful API kết nối cơ sở dữ liệu quan hệ SQL Server và thông báo thời gian thực.',
                            'Đạt giải thưởng Nhân viên xuất sắc năm 2021 nhờ hoàn thành dự án trước hạn 2 tuần.',
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 3: Technical Skills
                        _buildSectionHeader('KỸ NĂNG CHUYÊN MÔN', Icons.code_rounded),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: skills.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Section 4: Education & Certifications
                        _buildSectionHeader('HỌC VẤN & CHỨNG CHỈ', Icons.school_rounded),
                        const SizedBox(height: 8),
                        const Text(
                          '• Đại học Bách Khoa - Chuyên ngành Kỹ thuật Phần mềm (Tốt nghiệp loại Giỏi, GPA 3.6/4.0)',
                          style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Chứng chỉ quốc tế: Microsoft Certified - Azure Solutions Associate',
                          style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Chứng chỉ chuyên sâu: Flutter & Mobile Architecture Professional',
                          style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        // Verification Seal Footer
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_outlined, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hồ sơ CV số hóa xác minh bởi HireFlow • Mã tài liệu: HF-DOC-${widget.document.documentId} • Ngày cấp: ${CurrencyFormatter.formatDate(widget.document.uploadedAt)}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Zoom Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF475569)),
                      onPressed: _zoomOut,
                      tooltip: 'Thu nhỏ',
                    ),
                    InkWell(
                      onTap: _resetZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${(_scale * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF475569)),
                      onPressed: _zoomIn,
                      tooltip: 'Phóng to',
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadDocument,
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Tải bản PDF', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(height: 1.5, width: 40, color: AppColors.primary),
      ],
    );
  }

  Widget _buildExperienceItem({
    required String role,
    required String company,
    required String period,
    required List<String> bullets,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                role,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            Text(period, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
        Text(
          company,
          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        ...bullets.map((b) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                Expanded(
                  child: Text(b, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
