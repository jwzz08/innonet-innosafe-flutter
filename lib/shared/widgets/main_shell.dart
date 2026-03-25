import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex(String location) {
    if (location.startsWith('/facility')) return 0;
    if (location.startsWith('/media')) return 1;
    if (location.startsWith('/camera')) return 3;
    if (location.startsWith('/settings')) return 4;
    // site-select, site, site-detail 모두 가운데(2)
    if (location.startsWith('/site')) return 2;
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/facility'); break;
      case 1: context.go('/media'); break;
      case 2: context.go('/site-select'); break;
      case 3: context.go('/camera'); break;
      case 4: context.go('/settings'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _selectedIndex(location);

    return OrientationBuilder(
      builder: (_, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: widget.child,
          bottomNavigationBar: isLandscape
              ? null
              : _FloatingCenterNavBar(
            currentIndex: currentIndex,
            onTap: (i) => _onTap(i, context),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// Custom Bottom Nav Bar with Floating Center Button
// ─────────────────────────────────────────────────────
class _FloatingCenterNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingCenterNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.business_outlined,    activeIcon: Icons.business,    label: 'Facility'),
    _NavItem(icon: Icons.perm_media_outlined,  activeIcon: Icons.perm_media,  label: 'Media'),
    _NavItem(icon: Icons.map,                  activeIcon: Icons.map,         label: 'Site',    isCenter: true),
    _NavItem(icon: Icons.camera_alt_outlined,  activeIcon: Icons.camera_alt,  label: 'Camera'),
    _NavItem(icon: Icons.settings_outlined,    activeIcon: Icons.settings,    label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    const barHeight = 68.0;
    const centerSize = 62.0;
    const centerElevation = 28.0; // 얼마나 위로 띄울지

    final primaryColor = const Color(0xFF6495ED);
    final barColor = const Color(0xFF161B22);
    final borderColor = Colors.white.withOpacity(0.08);

    return SizedBox(
      height: barHeight + centerElevation / 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── 바 배경 ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: List.generate(_items.length, (i) {
                  if (_items[i].isCenter) {
                    // 가운데 자리는 빈 공간
                    return const Expanded(child: SizedBox());
                  }
                  final isActive = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? _items[i].activeIcon : _items[i].icon,
                            size: 22,
                            color: isActive
                                ? primaryColor
                                : Colors.white.withOpacity(0.45),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _items[i].label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isActive
                                  ? primaryColor
                                  : Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── 가운데 돌출 버튼 ─────────────────────────
          Positioned(
            bottom: barHeight / 2 - centerSize / 2 + centerElevation,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentIndex == 2 ? primaryColor : primaryColor.withOpacity(0.85),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.map,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}