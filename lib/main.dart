import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/admin/admin_views.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/employer/employer_views.dart';
import 'screens/freelancer/freelancer_views.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HireFlowApp());
}

class HireFlowApp extends StatelessWidget {
  const HireFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => CreditProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'HireFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGatekeeper(),
      ),
    );
  }
}

class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Đang tải HireFlow...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isAuthenticated || auth.user == null) {
      return const LoginScreen();
    }

    final role = auth.user!.role.toLowerCase();
    switch (role) {
      case 'freelancer':
        return const FreelancerHomeScreen();
      case 'employer':
        return const EmployerHomeScreen();
      case 'admin':
        return const AdminHomeScreen();
      default:
        return const LoginScreen();
    }
  }
}
