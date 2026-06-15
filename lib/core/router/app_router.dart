import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/director/screens/add_supervisor_screen.dart';
import '../../features/director/screens/add_tea_entry_screen.dart';
import '../../features/director/screens/add_worker_screen.dart';
import '../../features/director/screens/director_dashboard_screen.dart';
import '../../features/director/screens/estate_selection_screen.dart';
import '../../features/director/screens/profile_screen.dart';
import '../../features/director/screens/supervisors_screen.dart';
import '../../features/supervisor/screens/supervisor_dashboard_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  // Post-login flow
  static const String estateSelection = '/estate-selection';
  // Role dashboards
  static const String home = '/home';
  static const String directorDashboard = '/director';
  static const String supervisorDashboard = '/supervisor'; // future
  // Director routes
  static const String supervisors = '/supervisors';
  static const String addSupervisor = '/add-supervisor';
  static const String addWorker = '/add-worker';
  static const String addTeaEntry = '/add-tea-entry';
  static const String profile = '/profile';
  // Future deep routes
  static const String estates = '/estates';
  static const String reports = '/reports';
  static const String settings = '/settings';
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.estateSelection,
        name: 'estate-selection',
        builder: (context, state) => const EstateSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const DirectorDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.directorDashboard,
        name: 'director',
        builder: (context, state) => const DirectorDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.supervisors,
        name: 'supervisors',
        builder: (context, state) => const SupervisorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addSupervisor,
        name: 'add-supervisor',
        builder: (context, state) => const AddSupervisorScreen(),
      ),
      GoRoute(
        path: AppRoutes.addWorker,
        name: 'add-worker',
        builder: (context, state) => const AddWorkerScreen(),
      ),
      GoRoute(
        path: AppRoutes.addTeaEntry,
        name: 'add-tea-entry',
        builder: (context, state) => const AddTeaEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.supervisorDashboard,
        name: 'supervisor',
        builder: (context, state) => const SupervisorDashboardScreen(),
      ),
    ],
  );
}
