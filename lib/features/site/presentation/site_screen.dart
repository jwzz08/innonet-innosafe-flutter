/// NOTE: 이 파일은 MainShell 탭의 /site 경로용입니다.
/// 현장 선택은 SiteSelectScreen (/site-select) 에서 처리하므로,
/// 이 화면은 현재 사용하지 않거나 향후 "전체 현장 목록 뷰"로 활용 가능합니다.
///
/// 로그인 후 흐름:
///   /site-select → 현장 카드 클릭 → /site-detail (SiteDetailScreen)
///
/// 필요하다면 이 파일을 SiteSelectScreen으로 교체하거나 삭제하세요.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'site_select_screen.dart';

/// /site 탭 경로 → SiteSelectScreen을 재사용하거나
/// 별도의 "전체 현장 목록" UI를 여기에 구성
class SiteScreen extends ConsumerWidget {
  const SiteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 탭 내부에서도 동일한 현장 선택 화면 표시
    // (AppBar의 back 버튼 없이, Shell 탭 안에 임베드되는 형태)
    return const SiteSelectScreen();
  }
}