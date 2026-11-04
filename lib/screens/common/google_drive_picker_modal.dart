import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_providers.dart';
import 'cv_document_viewer_screen.dart';

class DriveCvFile {
  final String name;
  final String size;
  final String modified;
  final String title;
  final List<int>? fileBytes;

  const DriveCvFile({
    required this.name,
    required this.size,
    required this.modified,
    required this.title,
    this.fileBytes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'modified': modified,
    'title': title,
    if (fileBytes != null && fileBytes!.isNotEmpty) 'base64': base64Encode(fileBytes!),
  };

  factory DriveCvFile.fromJson(Map<String, dynamic> json) => DriveCvFile(
    name: json['name'] ?? '',
    size: json['size'] ?? '120 KB',
    modified: json['modified'] ?? 'Hôm nay',
    title: json['title'] ?? 'CV Tài liệu ứng viên',
    fileBytes: json['base64'] != null ? base64Decode(json['base64']) : null,
  );
}

class GoogleDriveStorageService {
  static String _storageKey(String email) {
    final clean = email.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'hireflow_google_drive_files_$clean';
  }

  static Future<List<DriveCvFile>> getFiles(String email, String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(email));
    if (raw != null && raw.isNotEmpty) {
      try {
        final List list = jsonDecode(raw);
        return list.map((e) => DriveCvFile.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    final nameSlug = fullName.isNotEmpty ? fullName.replaceAll(' ', '_') : 'Nguyen_Van_An';
    final initial = [
      DriveCvFile(
        name: 'CV_Senior_Flutter_$nameSlug.pdf',
        size: '145 KB',
        modified: 'Hôm qua, 15:30',
        title: 'Senior Mobile Engineer (Flutter / Dart)',
      ),
      DriveCvFile(
        name: 'CV_Fullstack_DotNet_$nameSlug.pdf',
        size: '182 KB',
        modified: '28/10/2026',
        title: 'Fullstack .NET Core & Cloud Developer',
      ),
      const DriveCvFile(
        name: 'CV_TechLead_Mobile_2026.pdf',
        size: '160 KB',
        modified: '22/10/2026',
        title: 'Technical Lead / Solution Architect',
      ),
      DriveCvFile(
        name: 'Portfolio_Showcase_$nameSlug.pdf',
        size: '2.4 MB',
        modified: '15/10/2026',
        title: 'Hồ sơ dự án tiêu biểu & Thành tích thực chiến',
      ),
      DriveCvFile(
        name: 'HoSoNangLuc_Dev_$nameSlug.pdf',
        size: '98 KB',
        modified: '05/10/2026',
        title: 'Bản tóm tắt năng lực cốt lõi',
      ),
    ];
    await saveFiles(email, initial);
    return initial;
  }

  static Future<void> saveFiles(String email, List<DriveCvFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    final list = files.map((f) => f.toJson()).toList();
    await prefs.setString(_storageKey(email), jsonEncode(list));
  }

  static Future<void> addFile(String email, DriveCvFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(email));
    List<DriveCvFile> files = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final List list = jsonDecode(raw);
        files = list.map((e) => DriveCvFile.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }
    files.removeWhere((f) => f.name.toLowerCase() == file.name.toLowerCase());
    files.insert(0, file);
    await saveFiles(email, files);
  }

  static Future<void> deleteFile(String email, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(email));
    if (raw != null && raw.isNotEmpty) {
      try {
        final List list = jsonDecode(raw);
        final files = list.map((e) => DriveCvFile.fromJson(Map<String, dynamic>.from(e))).toList();
        files.removeWhere((f) => f.name.toLowerCase() == fileName.toLowerCase());
        await saveFiles(email, files);
      } catch (_) {}
    }
  }
}

class GoogleDrivePickerBottomSheet extends StatefulWidget {
  const GoogleDrivePickerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GoogleDrivePickerBottomSheet(),
    );
  }

  static void showDriveOfflineHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF1A73E8), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hướng dẫn chọn file Drive',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Màn hình mặc định của Android mở ở tab "Gần đây" (Recent files), nếu chưa mở file nào gần đây sẽ hiện "No items".',
              style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '2. Chọn trực tiếp từ Google Drive đám mây:\n'
              '   • Mở ứng dụng Google Drive trên máy\n'
              '   • Bấm ⋮ bên cạnh tệp PDF -> chọn "Tải xuống" (Download) hoặc bật "Cho phép truy cập khi không có mạng"\n'
              '   • File sẽ sẵn sàng cho Android đọc mà không bị lỗi mạng.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '3. Cách nhanh nhất:\n'
              '   Chọn trực tiếp các mẫu CV có sẵn trong cửa sổ này của HireFlow để tải lên & mở xem ngay lập tức!',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  State<GoogleDrivePickerBottomSheet> createState() => _GoogleDrivePickerBottomSheetState();
}

class _GoogleDrivePickerBottomSheetState extends State<GoogleDrivePickerBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _uploadingFileName;
  List<DriveCvFile> _driveFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDriveFiles());
  }

  void _loadDriveFiles() async {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email ?? 'freelancer@hireflow.com';
    final name = auth.user?.fullName ?? 'Nguyen Van An';
    final files = await GoogleDriveStorageService.getFiles(email, name);
    if (mounted) {
      setState(() {
        _driveFiles = files;
        _isLoading = false;
      });
    }
  }

  List<int> _generatePdfBytes({
    required String candidateName,
    required String headline,
    required String email,
    required String fileName,
  }) {
    final safeName = candidateName.replaceAll(RegExp(r'[^\x00-\x7F]'), ' ');
    final safeHeadline = headline.replaceAll(RegExp(r'[^\x00-\x7F]'), ' ');

    final content = '''%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
endobj
4 0 obj
<< /Length 300 >>
stream
BT
/F1 18 Tf
50 790 Td
(CV - $safeName) Tj
/F1 12 Tf
0 -26 Td
(Position: $safeHeadline) Tj
0 -20 Td
(Email: $email) Tj
0 -30 Td
(HireFlow Verified Digital Document - Standard PDF 1.4) Tj
ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000224 00000 n 
0000000574 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
647
%%EOF
''';
    return content.codeUnits;
  }

  void _uploadFromDrive(DriveCvFile file) async {
    setState(() => _uploadingFileName = file.name);
    final auth = context.read<AuthProvider>();
    final docProvider = context.read<DocumentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final bytes = (file.fileBytes != null && file.fileBytes!.isNotEmpty)
        ? file.fileBytes!
        : _generatePdfBytes(
            candidateName: auth.user?.fullName ?? 'Freelancer',
            headline: file.title,
            email: auth.user?.email ?? 'freelancer@hireflow.com',
            fileName: file.name,
          );

    final createdDoc = await docProvider.uploadCvAndReturn(bytes, file.name, isDefault: true);

    if (mounted) {
      setState(() => _uploadingFileName = null);
      if (createdDoc != null) {
        nav.pop(); // Close bottom sheet
        messenger.showSnackBar(
          SnackBar(
            content: Text('Tải lên "${file.name}" từ Google Drive thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Automatically open the CV viewer!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CvDocumentViewerScreen(
              document: createdDoc,
              candidateName: auth.user?.fullName,
              candidateHeadline: file.title,
              candidateEmail: auth.user?.email,
              candidateSkills: auth.freelancerProfile?.skills,
              candidateBio: auth.freelancerProfile?.bio,
              candidateExperienceYears: auth.freelancerProfile?.experienceYears,
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(docProvider.errorMessage ?? 'Tải file từ Drive thất bại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _deleteFromDrive(DriveCvFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa khỏi Google Drive?'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa "${file.name}" khỏi Google Drive của tài khoản này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa tệp'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = context.read<AuthProvider>();
      final email = auth.user?.email ?? 'freelancer@hireflow.com';
      await GoogleDriveStorageService.deleteFile(email, file.name);
      if (mounted) {
        setState(() {
          _driveFiles.removeWhere((f) => f.name == file.name);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${file.name}" khỏi Google Drive của bạn!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _pickFromDevice() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty && mounted) {
        final file = files.first;
        setState(() => _uploadingFileName = file.name);

        final bytes = await file.xFile.readAsBytes();
        if (!mounted) return;

        final auth = context.read<AuthProvider>();
        final docProvider = context.read<DocumentProvider>();
        final messenger = ScaffoldMessenger.of(context);
        final nav = Navigator.of(context);
        final email = auth.user?.email ?? 'freelancer@hireflow.com';

        // Automatically add/sync to user's Google Drive storage for this email!
        final newDriveFile = DriveCvFile(
          name: file.name,
          size: CurrencyFormatter.formatFileSize(bytes.length),
          modified: 'Hôm nay',
          title: 'CV Đã đồng bộ từ thiết bị',
          fileBytes: bytes,
        );
        await GoogleDriveStorageService.addFile(email, newDriveFile);

        final createdDoc = await docProvider.uploadCvAndReturn(bytes, file.name, isDefault: true);

        if (mounted) {
          setState(() => _uploadingFileName = null);
          if (createdDoc != null) {
            nav.pop(); // Close bottom sheet
            messenger.showSnackBar(
              SnackBar(
                content: Text('Đã thêm "${file.name}" vào Google Drive & tải lên thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Automatically open the CV viewer!
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CvDocumentViewerScreen(
                  document: createdDoc,
                  candidateName: auth.user?.fullName,
                  candidateHeadline: auth.freelancerProfile?.headline,
                  candidateEmail: auth.user?.email,
                  candidateSkills: auth.freelancerProfile?.skills,
                  candidateBio: auth.freelancerProfile?.bio,
                  candidateExperienceYears: auth.freelancerProfile?.experienceYears,
                ),
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text(docProvider.errorMessage ?? 'Tải file từ thiết bị thất bại'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() => _uploadingFileName = null);
        GoogleDrivePickerBottomSheet.showDriveOfflineHelp(context);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final filtered = _searchQuery.isEmpty
        ? _driveFiles
        : _driveFiles
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                f.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.68,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Google Drive Header with Account
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_to_drive_rounded, color: Color(0xFF1A73E8), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Drive của tôi',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${auth.user?.email ?? "freelancer@hireflow.com"} • 4.8 / 15 GB',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, size: 20, color: Color(0xFF64748B)),
                  tooltip: 'Hướng dẫn',
                  onPressed: () => GoogleDrivePickerBottomSheet.showDriveOfflineHelp(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Search in Drive Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tệp CV trong Google Drive...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Không tìm thấy tệp "$_searchQuery" trong Drive'
                                  : 'Chưa có CV nào trong Google Drive',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _pickFromDevice,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Thêm CV từ thiết bị vào Drive'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final file = filtered[index];
                          final isUploadingThis = _uploadingFileName == file.name;

                          return Container(
                            decoration: BoxDecoration(
                              color: isUploadingThis ? AppColors.primaryLight : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isUploadingThis ? AppColors.primary : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListTile(
                              onTap: _uploadingFileName != null ? null : () => _uploadFromDrive(file),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                              ),
                              title: Text(
                                file.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(file.title, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${file.size} • Sửa đổi: ${file.modified}',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isUploadingThis)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  else
                                    InkWell(
                                      onTap: () => _uploadFromDrive(file),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.primary),
                                            SizedBox(width: 4),
                                            Text(
                                              'Chọn',
                                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                    tooltip: 'Xóa khỏi Drive',
                                    onPressed: () => _deleteFromDrive(file),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Device Picker Option
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadingFileName != null ? null : _pickFromDevice,
                    icon: const Icon(Icons.add_to_drive_rounded, size: 17, color: Color(0xFF1A73E8)),
                    label: const Text('Thêm tệp từ thiết bị vào Google Drive', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
