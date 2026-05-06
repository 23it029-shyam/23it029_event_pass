import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/event_setup_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/logs_screen.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 150),
  );
}

class EventPassApp extends StatefulWidget {
  const EventPassApp({super.key});

  @override
  State<EventPassApp> createState() => _EventPassAppState();
}

class _EventPassAppState extends State<EventPassApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    SyncService().initialize(context);
    SyncService().onSyncComplete = (count) {
      if (_rootNavigatorKey.currentContext != null) {
        ScaffoldMessenger.of(_rootNavigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('☁ Synced $count records'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    };

    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/setup',
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => _ScaffoldWithNavBar(child: child),
          routes: [
            GoRoute(
              path: '/setup',
              pageBuilder: (context, state) => buildPageWithDefaultTransition(context: context, state: state, child: const EventSetupScreen()),
            ),
            GoRoute(
              path: '/checkin/:eventId',
              pageBuilder: (context, state) {
                final eventId = state.pathParameters['eventId'];
                if (eventId == null || eventId.isEmpty || eventId == 'null') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showSelectEventSnackBar(context);
                    context.go('/setup');
                  });
                  return buildPageWithDefaultTransition(context: context, state: state, child: const Scaffold(body: Center(child: CircularProgressIndicator())));
                }
                return buildPageWithDefaultTransition(context: context, state: state, child: CheckinScreen(eventId: eventId));
              },
            ),
            GoRoute(
              path: '/dashboard/:eventId',
              pageBuilder: (context, state) {
                final eventId = state.pathParameters['eventId'];
                if (eventId == null || eventId.isEmpty || eventId == 'null') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showSelectEventSnackBar(context);
                    context.go('/setup');
                  });
                  return buildPageWithDefaultTransition(context: context, state: state, child: const Scaffold(body: Center(child: CircularProgressIndicator())));
                }
                return buildPageWithDefaultTransition(context: context, state: state, child: DashboardScreen(eventId: eventId));
              },
            ),
            GoRoute(
              path: '/logs/:eventId',
              pageBuilder: (context, state) {
                final eventId = state.pathParameters['eventId'];
                if (eventId == null || eventId.isEmpty || eventId == 'null') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showSelectEventSnackBar(context);
                    context.go('/setup');
                  });
                  return buildPageWithDefaultTransition(context: context, state: state, child: const Scaffold(body: Center(child: CircularProgressIndicator())));
                }
                return buildPageWithDefaultTransition(context: context, state: state, child: LogsScreen(eventId: eventId));
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showSelectEventSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.arrow_right_alt, color: Colors.white),
            SizedBox(width: 12),
            Text('Select an event first'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    SyncService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EventPass',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.lightTheme,
    );
  }
}

class _ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const _ScaffoldWithNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    final String location = router.routerDelegate.currentConfiguration.uri.toString();
    
    String? currentEventId;
    final parts = location.split('/');
    if (parts.length > 2 && parts[1] != 'setup') {
      currentEventId = parts[2];
    }

    int currentIndex = 0;
    if (location.startsWith('/checkin')) currentIndex = 1;
    if (location.startsWith('/dashboard')) currentIndex = 2;
    if (location.startsWith('/logs')) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/setup');
          } else {
            if (currentEventId == null || currentEventId == 'null') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.arrow_right_alt, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Select an event first'),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            if (index == 1) context.go('/checkin/$currentEventId');
            if (index == 2) context.go('/dashboard/$currentEventId');
            if (index == 3) context.go('/logs/$currentEventId');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Check In'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Logs'),
        ],
      ),
    );
  }
}
