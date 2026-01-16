import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/provider/auth_provider.dart';

// 화면들 임포트
import '../../features/home/presentation/home_screen.dart';
import '../../features/site/presentation/site_screen.dart';
import '../../features/facility/presentation/facility_screen.dart';
import '../../features/media/presentation/media_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/company_management_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/incident/presentation/incident_screen.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Auth 상태 구독 (상태가 변하면 라우터도 반응함)
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    // 디버그 로그 필요 시 true
    // debugLogDiagnostics: true,

    // 리다이렉트 로직
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.uri.toString() == '/login';

      // 1. 로그인이 안 된 상태에서 로그인 화면이 아니면 -> 로그인 화면으로 이동
      if (!isLoggedIn && !isLoggingIn) return '/login';

      // 2. 이미 로그인 된 상태에서 로그인 화면에 있다면 -> 홈으로 이동
      if (isLoggedIn && isLoggingIn) return '/home';

      // 그 외에는 원래 가려던 곳으로 이동
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/site', builder: (context, state) => const SiteScreen()),
          GoRoute(path: '/facility', builder: (context, state) => const FacilityScreen()),
          GoRoute(path: '/media', builder: (context, state) => const MediaScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'company', builder: (context, state) => const CompanyManagementScreen()),
                GoRoute(path: 'history', builder: (context, state) => const HistoryScreen()),
              ]
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