import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/site/presentation/site_select_screen.dart';
import '../../features/site/presentation/site_screen.dart';
import '../../features/site/presentation/site_detail_screen.dart';
import '../../features/facility/presentation/facility_screen.dart';
import '../../features/media/presentation/media_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/company_management_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/incident/presentation/incident_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// RouterNotifier
// ─────────────────────────────────────────────
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: notifier,

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final currentPath = state.uri.path;

      final isInitial = status == AuthStatus.initial;
      final isLoggedIn = status == AuthStatus.authenticated;

      final isGoingToLogin = currentPath == '/login';
      final isGoingToLoading = currentPath == '/loading';

      // 1. 토큰 검증 중
      if (isInitial) {
        return isGoingToLoading ? null : '/loading';
      }

      // 2. 로그인 안 됨
      if (!isLoggedIn) {
        return isGoingToLogin ? null : '/login';
      }

      // 3. 로그인 완료 → site-select로
      if (isLoggedIn) {
        if (isGoingToLogin || isGoingToLoading) {
          return '/site-select';
        }
      }

      return null;
    },

    routes: [
      // 로딩 화면
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),

      // 로그인 화면
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── 사이트 상세 화면 (현장 클릭 후, Shell 바깥 - 풀스크린) ──
      GoRoute(
        path: '/site-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SiteDetailScreen(
            siteId: extra['siteId'] as int,
            siteName: extra['siteName'] as String,
            dashboardId: extra['dashboardId'] as int,
            dashboardName: extra['dashboardName'] as String,
          );
        },
      ),

      // ── 메인 탭 Shell (하단 탭바 포함) ──
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // ✅ site-select를 Shell 안으로 이동 → 하단 탭바 표시됨
          GoRoute(path: '/site-select', builder: (context, state) => const SiteSelectScreen()),
          GoRoute(path: '/site', builder: (context, state) => const SiteScreen()),
          GoRoute(path: '/facility', builder: (context, state) => const FacilityScreen()),
          GoRoute(path: '/media', builder: (context, state) => const MediaScreen()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'company', builder: (context, state) => const CompanyManagementScreen()),
              GoRoute(path: 'history', builder: (context, state) => const HistoryScreen()),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/incident',
        builder: (context, state) => const IncidentScreen(),
      ),
    ],
  );
});

// ─────────────────────────────────────────────
// Camera Placeholder (임시)
// ─────────────────────────────────────────────
class _CameraPlaceholderScreen extends StatelessWidget {
  const _CameraPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Camera', style: TextStyle(color: Colors.white38, fontSize: 18)),
            SizedBox(height: 8),
            Text('준비 중입니다', style: TextStyle(color: Colors.white24, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LoadingScreen
// ─────────────────────────────────────────────
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_moon, size: 100, color: AppTheme.primary),
            const SizedBox(height: 24),
            const Text(
              'InnoSafe',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              '토큰 확인 중...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}