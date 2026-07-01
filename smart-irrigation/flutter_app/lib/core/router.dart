import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/control_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',        builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/control', builder: (c, s) => const ControlScreen()),
    GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
    GoRoute(path: '/settings',builder: (c, s) => const SettingsScreen()),
  ],
);