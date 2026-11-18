import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_spacing.dart';
import 'core/constants/app_typography.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/reminder_provider.dart';
import 'data/models/reminder_config.dart';
import 'notifications/foreground_reminder_ticker.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/signup_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/onboarding/onboarding_flow.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/history/history_screen.dart';
import 'presentation/stats/stats_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/profile/settings_screen.dart';
import 'presentation/reminders/reminder_settings_screen.dart';
import 'presentation/reminders/save_success_card.dart';
import 'presentation/widgets/neu_modal.dart';
import 'notifications/notification_models.dart';

import 'presentation/profile/avatar_selection_screen.dart';
import 'presentation/debug/notification_debug_screen.dart';
import 'presentation/debug/notification_test_lab_screen.dart';
import 'presentation/debug/notification_diagnostics_screen.dart';
import 'presentation/debug/developer_mode_screen.dart';
import 'presentation/history/notification_history_screen.dart';

import 'presentation/developer/developer_dashboard_screen.dart';
import 'presentation/developer/notification_center_screen.dart';
import 'presentation/developer/firebase_center_screen.dart';
import 'presentation/developer/supabase_center_screen.dart';
import 'presentation/developer/diagnostics_center_screen.dart';
import 'presentation/developer/log_center_screen.dart';
import 'presentation/developer/developer_utilities_screen.dart';
import 'presentation/profile/about_screen.dart';


/// Global navigator key used by both GoRouter and ForegroundReminderTicker.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = ref.read(authRepositoryProvider).currentUser != null;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isOnAuth) return '/login';

      if (isLoggedIn) {
        final profile = ref.read(profileProvider);
        
        // If profile is still loading, send user to /home (it shows its own loading state)
        if (profile.isLoading) {
          if (isOnAuth) return '/home';
          return null;
        }

        final profileData = profile.valueOrNull;
        final hasNameOrData = profileData?.name != null && (profileData?.name?.trim().isNotEmpty ?? false);
        final needsOnboarding = profileData == null || (!profileData.onboardingCompleted && !hasNameOrData);

        if (needsOnboarding && state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }

        if (isOnAuth) {
          return needsOnboarding ? '/onboarding' : '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onSignUp: () => context.go('/signup'),
          onForgotPassword: () => context.go('/forgot-password'),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignupScreen(
          onLogin: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          onBack: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      // Single route for the main shell — PageView handles tab content
      GoRoute(
        path: '/home',
        builder: (context, state) => const _MainShell(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsScreen(
          onBack: () => context.pop(),
          onReminderSettings: () async {
            final result = await context.push('/reminder-settings');
            if (result is SaveResult && result.success && context.mounted) {
              NeuModal.show(
                context,
                title: 'Schedule Updated',
                child: SaveSuccessCard(result: result),
              );
            }
          },
        ),
      ),
      GoRoute(
        path: '/avatar-selection',
        builder: (context, state) => const AvatarSelectionScreen(),
      ),
      GoRoute(
        path: '/reminder-settings',
        builder: (context, state) => ReminderSettingsScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/notification-debug',
        builder: (context, state) => NotificationDebugScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/notification-history',
        builder: (context, state) => NotificationHistoryScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/notification-test-lab',
        builder: (context, state) => NotificationTestLabScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/notification-diagnostics',
        builder: (context, state) => NotificationDiagnosticsScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-mode',
        builder: (context, state) => DeveloperModeScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard',
        builder: (context, state) => DeveloperDashboardScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/system',
        builder: (context, state) => DiagnosticsCenterScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/notification-center',
        builder: (context, state) => NotificationCenterScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/firebase-center',
        builder: (context, state) => FirebaseCenterScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/supabase-center',
        builder: (context, state) => SupabaseCenterScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/diagnostics-center',
        builder: (context, state) => DiagnosticsCenterScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/log-center',
        builder: (context, state) => LogCenterScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard/utilities',
        builder: (context, state) => DeveloperUtilitiesScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => AboutScreen(
          onBack: () => context.pop(),
        ),
      ),
    ],
  );

  ref.listen(authStateProvider, (_, _) {
    router.refresh();
  });

  ref.listen(profileProvider, (_, _) {
    router.refresh();
  });

  return router;
});

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _onNavTap(0);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const ClampingScrollPhysics(),
          children: [
            HomeScreen(onNavigateToProfile: () => _onNavTap(3)),
            const HistoryScreen(),
            const StatsScreen(),
            ProfileScreen(
              onSettings: () => context.push('/settings'),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.black,
                width: AppSpacing.borderWidth,
              ),
            ),
            color: AppColors.surfaceContainerLowest,
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _navItem(0, Icons.home_outlined, Icons.home, 'HOME'),
                  _navItem(1, Icons.history_outlined, Icons.history, 'HISTORY'),
                  _navItem(2, Icons.bar_chart_outlined, Icons.bar_chart, 'STATS'),
                  _navItem(3, Icons.person_outline, Icons.person, 'PROFILE'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.secondaryContainer
                      : Colors.transparent,
                  border: isActive
                      ? Border.all(color: AppColors.black, width: 2)
                      : null,
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: AppColors.onSurface,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: isActive
                      ? AppColors.onSurface
                      : AppColors.outline,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SiplyApp extends ConsumerStatefulWidget {
  const SiplyApp({super.key});

  @override
  ConsumerState<SiplyApp> createState() => _SiplyAppState();
}

class _SiplyAppState extends ConsumerState<SiplyApp> {
  bool _tickerStarted = false;

  @override
  void dispose() {
    ForegroundReminderTicker.stop();
    super.dispose();
  }

  void _startTickerIfReady() {
    if (_tickerStarted) return;

    _tickerStarted = true;
    ForegroundReminderTicker.start(
      navigatorKey: rootNavigatorKey,
      getCurrentConfig: () {
        final currentSettings =
            ref.read(reminderSettingsProvider).valueOrNull;
        if (currentSettings != null) {
          return ReminderConfig.fromSettings(
            enabled: currentSettings.enabled,
            mode: currentSettings.mode,
            intervalMinutes: currentSettings.computedIntervalMinutes,
            fixedTimes: currentSettings.fixedTimes,
            dndStart: currentSettings.dndStart,
            dndEnd: currentSettings.dndEnd,
            snoozeDefaultMinutes: currentSettings.snoozeDefaultMinutes,
            deletedTimes: currentSettings.deletedTimes,
          );
        }
        // Default config if settings aren't loaded yet
        return const ReminderConfig(
          enabled: true,
          mode: ReminderMode.both,
          intervalMinutes: 60,
          fixedTimes: [],
          dndStart: '23:00',
          dndEnd: '07:00',
          snoozeMinutesDefault: 5,
          deletedTimes: [],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Watch reminder settings to start ticker once loaded
    final settingsAsync = ref.watch(reminderSettingsProvider);
    settingsAsync.whenData((_) {
      // Start the foreground ticker once settings are available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTickerIfReady();
      });
    });

    return MaterialApp.router(
      title: 'Siply',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
