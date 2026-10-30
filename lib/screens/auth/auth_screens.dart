import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../services/app_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'freelancer@hireflow.com');
  final _passwordCtrl = TextEditingController(text: 'Freelancer@123!');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.disposeVelocity();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập không thành công'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _setDemoCredentials(String email, String password) {
    setState(() {
      _emailCtrl.text = email;
      _passwordCtrl.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.work_outline, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'HireFlow',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Đăng nhập tài khoản',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kết nối nhà tuyển dụng & nhân tài freelance',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Email input
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                          if (!v.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                          },
                          child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Submit button
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                            },
                            child: const Text('Đăng ký ngay', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick Demo Account Selection Pill Chips
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Tài khoản mẫu thử nghiệm:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.person, size: 16),
                            label: const Text('Freelancer', style: TextStyle(fontSize: 12)),
                            onPressed: () => _setDemoCredentials('freelancer@hireflow.com', 'Freelancer@123!'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.business, size: 16),
                            label: const Text('Employer', style: TextStyle(fontSize: 12)),
                            onPressed: () => _setDemoCredentials('employer@hireflow.com', 'Employer@123!'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.admin_panel_settings, size: 16),
                            label: const Text('Admin', style: TextStyle(fontSize: 12)),
                            onPressed: () => _setDemoCredentials('admin@hireflow.com', 'Admin@HireFlow2026!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on TextEditingController {
  void disposeVelocity() => dispose();
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _selectedRole = 'Freelancer'; // Freelancer or Employer only

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
    );
    if (success && mounted) {
      Navigator.pop(context); // Go back, user is logged in
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký không thành công'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đăng ký tài khoản'), elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tạo tài khoản mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nhận ngay 10 credit miễn phí khi kích hoạt tài khoản!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),

                      // Role Selection (AUTH-006: Admin cannot register)
                      const Text('Bạn muốn tham gia với vai trò:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Freelancer (Tìm việc)')),
                              selected: _selectedRole == 'Freelancer',
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                color: _selectedRole == 'Freelancer' ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedRole = 'Freelancer');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Employer (Tuyển dụng)')),
                              selected: _selectedRole == 'Employer',
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                color: _selectedRole == 'Employer' ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedRole = 'Employer');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: InputDecoration(
                          labelText: _selectedRole == 'Freelancer' ? 'Họ và tên' : 'Tên doanh nghiệp / Nhà tuyển dụng',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email liên hệ',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                          if (!v.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận lại mật khẩu',
                          prefixIcon: const Icon(Icons.lock_reset),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) {
                          if (v != _passwordCtrl.text) return 'Mật khẩu xác nhận không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Tạo tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  void _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msg = await AuthService.forgotPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(initialEmail: email)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset, size: 52, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('Khôi phục mật khẩu', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Nhập email của bạn để nhận mã xác nhận (OTP) 6 chữ số.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email tài khoản',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Gửi mã xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ResetPasswordScreen({super.key, required this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _emailCtrl;
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  void _reset() async {
    if (_codeCtrl.text.trim().isEmpty || _newPasswordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP và mật khẩu mới từ 6 ký tự'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msg = await AuthService.resetPassword(
        _emailCtrl.text.trim(),
        _codeCtrl.text.trim(),
        _newPasswordCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Nhập mã OTP và mật khẩu mới', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mã xác nhận OTP (6 chữ số)',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _newPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _reset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Cập nhật mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

