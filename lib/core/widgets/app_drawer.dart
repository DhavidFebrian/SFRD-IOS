import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../state/app_state_provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _monthsExpanded = false;
  bool _mediaFiltersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final palette = AppColors.paletteFor(state.selectedThemeStyle);

    return Drawer(
      backgroundColor: palette.surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.elevatedSurfaceColor,
                    palette.surfaceColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: palette.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandYellow.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'RWC',
                      style: TextStyle(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RWC Media Production',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: palette.accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Sheet Aktif: ${state.selectedMonth}',
                            style: TextStyle(
                              color: palette.secondaryAccentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  _buildDrawerItem(
                    icon: Icons.insights_rounded,
                    label: 'Analytic Dashboard',
                    isSelected: state.activeDrawerPage == 'ANALYTIC',
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.openDrawerPage('ANALYTIC');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard Utama',
                    isSelected:
                        state.activeDrawerPage == null && state.currentTabIndex == 2,
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.setTabIndex(2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups_rounded,
                    label: 'Weekly Meeting & Absensi',
                    isSelected:
                        state.activeDrawerPage == null && state.currentTabIndex == 0,
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.setTabIndex(0);
                    },
                  ),

                  // Media + Sub-filters
                  _buildDrawerItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Media (Jadwal Foto)',
                    isSelected:
                        state.activeDrawerPage == null && state.currentTabIndex == 1,
                    accent: palette.accentColor,
                    trailing: IconButton(
                      icon: Icon(
                        _mediaFiltersExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.darkTextSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _mediaFiltersExpanded = !_mediaFiltersExpanded;
                        });
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      state.setMediaFilter('Semua');
                      state.setTabIndex(1);
                    },
                  ),
                  if (_mediaFiltersExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, bottom: 6),
                      child: Column(
                        children: [
                          _buildSubItem(
                            label: 'Jadwal Aktif',
                            selected: state.mediaFilter == 'Aktif' &&
                                state.currentTabIndex == 1,
                            color: AppColors.statusPending,
                            onTap: () {
                              Navigator.pop(context);
                              state.setMediaFilter('Aktif');
                              state.setTabIndex(1);
                            },
                          ),
                          _buildSubItem(
                            label: 'Jadwal Selesai (Done)',
                            selected: state.mediaFilter == 'Selesai' &&
                                state.currentTabIndex == 1,
                            color: AppColors.statusDone,
                            onTap: () {
                              Navigator.pop(context);
                              state.setMediaFilter('Selesai');
                              state.setTabIndex(1);
                            },
                          ),
                          _buildSubItem(
                            label: 'Jadwal Non-Aktif',
                            selected: state.mediaFilter == 'Non-Aktif' &&
                                state.currentTabIndex == 1,
                            color: AppColors.statusUrgent,
                            onTap: () {
                              Navigator.pop(context);
                              state.setMediaFilter('Non-Aktif');
                              state.setTabIndex(1);
                            },
                          ),
                        ],
                      ),
                    ),

                  _buildDrawerItem(
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Content (Task & Edit Foto)',
                    isSelected:
                        state.activeDrawerPage == null && state.currentTabIndex == 3,
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.setTabIndex(3);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.send_rounded,
                    label: 'Publish (Upload IG & Reels)',
                    isSelected:
                        state.activeDrawerPage == null && state.currentTabIndex == 4,
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.setTabIndex(4);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Divider(height: 1),
                  ),

                  // Expandable Month Selector
                  _buildDrawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Pilih Data Sheet (Bulan)',
                    isSelected: _monthsExpanded,
                    accent: palette.accentColor,
                    trailing: Icon(
                      _monthsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.darkTextSecondary,
                    ),
                    onTap: () {
                      setState(() {
                        _monthsExpanded = !_monthsExpanded;
                      });
                    },
                  ),
                  if (_monthsExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, bottom: 8),
                      child: Column(
                        children: AppStateProvider.availableMonths.map((m) {
                          final isCurrent = state.selectedMonth == m;
                          return _buildSubItem(
                            label: m,
                            selected: isCurrent,
                            color: palette.secondaryAccentColor,
                            onTap: () {
                              Navigator.pop(context);
                              state.setSelectedMonth(m);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  _buildDrawerItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Tambah Jadwal Baru',
                    isSelected: state.activeDrawerPage == 'TAMBAH',
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.openDrawerPage('TAMBAH');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Team Chat (Alan & David)',
                    isSelected: state.isInChatScreen,
                    accent: palette.accentColor,
                    trailing: state.unreadChatCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusUrgent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.unreadChatCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      state.openChatScreen(true);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Setting API Sheets & Tema',
                    isSelected: state.activeDrawerPage == 'SETTING',
                    accent: palette.accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      state.openDrawerPage('SETTING');
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Divider(height: 1),
                  ),

                  // Notification toggle
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: palette.elevatedSurfaceColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.isNotificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          color: state.isNotificationsEnabled
                              ? AppColors.brandYellow
                              : AppColors.darkTextTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Notifikasi Aplikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: state.isNotificationsEnabled,
                          activeColor: palette.accentColor,
                          onChanged: (v) => state.setNotificationsEnabled(v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: palette.borderColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Versi V8.9.15',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    state.selectedThemeStyle.displayName,
                    style: TextStyle(
                      color: palette.secondaryAccentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accent,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: accent.withValues(alpha: 0.45))
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: isSelected ? accent : AppColors.darkTextSecondary,
          size: 21,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkTextPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubItem({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : AppColors.darkTextTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.darkTextSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 15, color: color),
          ],
        ),
      ),
    );
  }
}
