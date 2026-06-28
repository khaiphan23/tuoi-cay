import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/control_screen.dart';
import '../screens/auto_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

/// AppRouter — Cấu hình điều hướng với GoRouter
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/control', builder: (ctx, state) => const ControlScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/auto', builder: (ctx, state) => const AutoScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/history', builder: (ctx, state) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
}

/// ScaffoldWithNavBar — Bottom navigation bar dùng chung
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.bgBorder, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (idx) {
            navigationShell.goBranch(idx,
                initialLocation: idx == navigationShell.currentIndex);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded),
              label: 'Điều khiển',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_mode_rounded),
              label: 'Tự động',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Lịch sử',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}
