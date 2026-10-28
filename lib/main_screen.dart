import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/state/app_state_provider.dart';
import 'core/widgets/app_drawer.dart';
import 'core/widgets/detail_pager_screen.dart';
import 'core/widgets/glow_nav_bar.dart';
import 'features/analytic/screens/analytic_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/media/screens/media_screen.dart';
import 'features/media/widgets/add_schedule_dialog.dart';
import 'features/publish/screens/publish_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/tasks/screens/task_dashboard_screen.dart';
import 'features/weekly_meeting/screens/weekly_meeting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final palette = AppColors.paletteFor(state.selectedThemeStyle);

    // 1. Fullscreen Team Chat Overlay
    if (state.isInChatScreen) {
      return const ChatScreen();
    }

    // 2. Fullscreen 3-Page Schedule Detail Pager Overlay
    if (state.selectedScheduleForDetail != null) {
      return DetailPagerScreen(
        schedule: state.selectedScheduleForDetail!,
        initialPage: state.detailInitialPage,
      );
    }

    // 3. Hidden Drawer Screens (Analytic, Tambah Jadwal, Setting)
    if (state.activeDrawerPage == 'ANALYTIC') {
      return const AnalyticScreen();
    }
    if (state.activeDrawerPage == 'SETTING') {
      return const SettingsScreen();
    }
    if (state.activeDrawerPage == 'TAMBAH') {
      return const InputFormScreen();
    }

    // 4. Main 5-Tab Shell with Floating Glassmorphic GlowNavBar
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.backgroundColor,
      drawer: const AppDrawer(),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: palette.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu Navigasi',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'RWC',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (state.currentTabIndex) {
                      0 => 'Weekly Meeting & Absensi',
                      1 => 'Schedule Foto RWC David',
                      2 => 'Workflow Monitor',
                      3 => 'Content & Edit Foto',
                      4 => 'Instagram Publisher',
                      _ => 'RWC Media Production',
                    },
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: palette.secondaryAccentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${state.selectedMonth} • v8.9.15',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Unread Chat Badge Button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
                tooltip: 'Team Chat',
                onPressed: () => state.openChatScreen(true),
              ),
              if (state.unreadChatCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusUrgent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.unreadChatCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Sync Button
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandYellow,
                    ),
                  )
                : const Icon(Icons.sync_rounded, size: 22),
            tooltip: 'Sinkronisasi Data Sheets',
            onPressed: state.isLoading ? null : () => state.refreshData(),
          ),
        ],
      ),
      body: IndexedStack(
        index: state.currentTabIndex,
        children: const [
          WeeklyMeetingScreen(),
          MediaScreen(),
          DashboardScreen(),
          TaskDashboardScreen(),
          PublishScreen(),
        ],
      ),
      bottomNavigationBar: GlowNavBar(
        currentIndex: state.currentTabIndex,
        onTap: state.setTabIndex,
      ),
    );
  }
}
