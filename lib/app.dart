import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SafetyMonitorApp extends ConsumerWidget {
  const SafetyMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod을 통해 라우터 설정을 구독
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Safety Monitor',

      // 디자인 테마 적용
      theme: AppTheme.darkTheme,

      // GoRouter 연결
      routerConfig: router,

      // 디버그 배너 제거
      debugShowCheckedModeBanner: false,
    );
  }
}