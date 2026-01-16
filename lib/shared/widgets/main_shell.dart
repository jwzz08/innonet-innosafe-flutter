import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 화면 방향 감지
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          // 가로 모드일 때 키보드 등에 의해 화면이 찌그러지는 것 방지
          resizeToAvoidBottomInset: false,

          body: child,

          // 가로 모드이면 하단 네비게이션 바를 숨김 (null)
          bottomNavigationBar: isLandscape
              ? null
              : BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (int index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Site'),
              BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Facility'),
              BottomNavigationBarItem(icon: Icon(Icons.video_camera_front), label: 'Media'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/site')) return 1;
    if (location.startsWith('/facility')) return 2;
    if (location.startsWith('/media')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/site'); break;
      case 2: context.go('/facility'); break;
      case 3: context.go('/media'); break;
      case 4: context.go('/settings'); break;
    }
  }
}