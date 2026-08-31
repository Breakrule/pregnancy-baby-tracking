import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/more/more_screen.dart';
import '../features/pregnancy/home/home_screen.dart';
import '../features/pregnancy/learn/danger_signs_screen.dart';
import '../features/pregnancy/learn/learn_screen.dart';
import '../features/pregnancy/learn/week_detail_screen.dart';
import '../features/pregnancy/setup/setup_wizard_screen.dart';
import '../features/pregnancy/symptoms/symptom_entry_screen.dart';
import '../features/pregnancy/symptoms/symptom_history_screen.dart';
import '../features/pregnancy/track/track_screen.dart';
import '../features/pregnancy/weight/weight_entry_screen.dart';
import '../features/pregnancy/weight/weight_history_screen.dart';
import '../features/pregnancy/appointments/appointments_screen.dart';
import '../features/pregnancy/medications/medications_screen.dart';
import '../features/shared/settings/settings_screen.dart';

/// Notifies GoRouter to re-evaluate redirects when the active pregnancy
/// changes (e.g. after setup completes). Subscribes to a stream directly
/// rather than using ref.listen inside a Provider (which would cause the
/// provider to rebuild and recreate the router on every emission).
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Stream<dynamic> source) {
    // Drift watch streams emit the current value immediately on subscribe;
    // skip(1) avoids a redundant redirect re-evaluation at construction.
    _sub = source.skip(1).listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter({
  required Future<bool> Function() hasPregnancy,
  ChangeNotifier? refreshListenable,
}) {
  // Navigator key is created per-call so multiple GoRouter instances in tests
  // don't collide via a shared module-level GlobalKey.
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final onSetup = state.matchedLocation == '/setup';
      final setupDone = await hasPregnancy();
      if (!setupDone && !onSetup) return '/setup';
      if (setupDone && onSetup) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupWizardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/track',
                builder: (context, state) => const TrackScreen(),
                routes: [
                  GoRoute(
                    path: 'weight',
                    builder: (c, s) => const WeightHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (c, s) => const WeightEntryScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'symptoms',
                    builder: (c, s) => const SymptomHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (c, s) => const SymptomEntryScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'appointments',
                    builder: (c, s) => const AppointmentsScreen(),
                  ),
                  GoRoute(
                    path: 'medications',
                    builder: (c, s) => const MedicationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const LearnScreen(),
                routes: [
                  GoRoute(
                    path: 'danger-signs',
                    builder: (c, s) => const DangerSignsScreen(),
                  ),
                  GoRoute(
                    path: 'week/:w',
                    redirect: (context, state) {
                      if (int.tryParse(state.pathParameters['w'] ?? '') ==
                          null) {
                        return '/learn';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final week = int.parse(state.pathParameters['w']!);
                      return WeekDetailScreen(week: week);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
