import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/widgets/add_donation_sheet.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String userRole;

  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.userRole,
  });

  bool get _isNeedy => userRole.trim().toUpperCase() == 'NEEDY';

  Future<void> _openAddDonationSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDonationSheet(userRole: userRole),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Convert branch index to UI tab index
    int displayIndex = navigationShell.currentIndex;
    if (!_isNeedy && displayIndex >= 2) {
      displayIndex = displayIndex + 1;
    }

    final navTheme = NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: isDark
          ? Colors.white.withValues(alpha: 0.22)
          : AppShell.kGreen.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: isDark ? Colors.white : AppShell.kInk,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        if (isDark) {
          return IconThemeData(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.65),
            size: 24,
          );
        }
        return IconThemeData(
          color: selected ? AppShell.kGreen : AppShell.kInk.withValues(alpha: 0.55),
          size: 24,
        );
      }),
    );

    final List<NavigationDestination> destinations = _isNeedy
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Akış',
            ),
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen_rounded),
              label: 'Buzdolabım',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Harita',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Akış',
            ),
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen_rounded),
              label: 'Buzdolabım',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded),
              label: 'Bağış',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Harita',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ];

    return AppShell(
      safeArea: false,
      body: navigationShell,
      bottomNavigationBar: GlassBar(
        child: NavigationBarTheme(
          data: navTheme,
          child: NavigationBar(
            selectedIndex: displayIndex,
            animationDuration: const Duration(milliseconds: 300),
            onDestinationSelected: (i) async {
              // NEEDY: 4 tabs (feed, fridges, map, profile → branches 0,1,2,3)
              // PERSONAL/CORP: 5 tabs (feed, fridges, +sheet, map, profile)
              if (!_isNeedy) {
                if (i == 2) {
                  await _openAddDonationSheet(context);
                  return;
                }
                // map=3→branch2, profile=4→branch3
                final branchIndex = i > 2 ? i - 1 : i;
                navigationShell.goBranch(
                  branchIndex,
                  initialLocation: branchIndex == navigationShell.currentIndex,
                );
              } else {
                navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                );
              }
            },
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
