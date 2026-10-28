import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class GlowNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const GlowNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class GlowNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<GlowNavItem> items = [
    GlowNavItem(
      label: 'Meeting',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    GlowNavItem(
      label: 'Media',
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt_rounded,
    ),
    GlowNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    GlowNavItem(
      label: 'Content',
      icon: Icons.auto_fix_high_outlined,
      activeIcon: Icons.auto_fix_high_rounded,
    ),
    GlowNavItem(
      label: 'Publish',
      icon: Icons.send_outlined,
      activeIcon: Icons.send_rounded,
    ),
  ];

  const GlowNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding : 14,
        top: 6,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.glowPillMid.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glowBarBackground.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.glowBarBorder.withValues(alpha: 0.8),
                  width: 1.1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / items.length;
                  return Stack(
                    children: [
                      // Radial top light leak following active tab
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutBack,
                        left: (currentIndex * itemWidth) + (itemWidth * 0.1),
                        top: -12,
                        child: Container(
                          width: itemWidth * 0.8,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.glowPillStart
                                    .withValues(alpha: 0.55),
                                blurRadius: 22,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sliding neon gradient pill
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 340),
                        curve: Curves.easeOutCubic,
                        left: (currentIndex * itemWidth) + 6,
                        top: 7,
                        bottom: 7,
                        width: itemWidth - 12,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.glowPillStart,
                                AppColors.glowPillMid,
                                AppColors.glowPillEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.glowPillMid
                                    .withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Interactive tab items
                      Row(
                        children: List.generate(items.length, (idx) {
                          final item = items[idx];
                          final isSelected = idx == currentIndex;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onTap(idx);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.12 : 1.0,
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      size: 22,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.glowInactiveIcon,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.glowInactiveIcon,
                                      letterSpacing: isSelected ? 0.2 : 0,
                                    ),
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
