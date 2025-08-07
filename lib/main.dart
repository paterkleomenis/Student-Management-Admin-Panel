import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'db_client.dart';
import 'screens/dashboard_screen.dart';
import 'screens/error_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/student_form_screen.dart';
import 'screens/students_screen.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize secure configuration
    await AppConfig.initialize();
    AppConfig.validate();

    // Initialize EasyLocalization
    await EasyLocalization.ensureInitialized();

    // Initialize database with secure config
    await DatabaseClient.initialize();

    // Initialize AuthService
    final authService = AuthService();
    await authService.initialize();

    // Initialize LanguageService
    final languageService = LanguageService();
    await languageService.initialize();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('el')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: AdminPanelApp(
          authService: authService,
          languageService: languageService,
        ),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your .env file configuration.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const ElevatedButton(onPressed: main, child: Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({
    required this.authService, required this.languageService, super.key,
  });

  final AuthService authService;
  final LanguageService languageService;

  @override
  Widget build(BuildContext context) => MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
      ],
      child: Consumer<LanguageService>(
        builder: (context, langService, child) => MaterialApp.router(
            title: langService.appTitle,
            debugShowCheckedModeBanner: false,
            locale: langService.currentLocale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
              ),
              textTheme: GoogleFonts.interTextTheme(),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[800],
                elevation: 0,
                centerTitle: false,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            routerConfig: _createRouter(authService),
          ),
      ),
    );
}

GoRouter _createRouter(AuthService authService) => GoRouter(
    initialLocation: authService.isLoggedIn ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn && authService.isAdmin;
      final isLoginRoute = state.fullPath == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsScreen(),
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const StudentFormScreen(),
              ),
              GoRoute(
                path: '/edit/:id',
                builder: (context, state) {
                  final studentId = state.pathParameters['id'];
                  return StudentFormScreen(studentId: studentId);
                },
              ),
              GoRoute(
                path: '/view/:id',
                builder: (context, state) {
                  final studentId = state.pathParameters['id'];
                  return StudentDetailScreen(studentId: studentId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );
