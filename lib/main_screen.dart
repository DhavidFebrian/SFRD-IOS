import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'core/state/app_state_provider.dart';
import 'core/widgets/app_drawer.dart';
import 'features/weekly_meeting/screens/weekly_meeting_screen.dart';
import 'features/media/screens/media_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/tasks/screens/task_dashboard_screen.dart';
import 'features/marketing/screens/instagram_mockup_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Default to Dashboard tab

  final List<String> _titles = [
    'Weekly Meeting',
    'Jadwal Media',
    'Dashboard',
    'Edit Foto Task',
    'Instagram Publisher',
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE600),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  state.selectedMonth,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(CupertinoIcons.arrow_clockwise),
            tooltip: 'Segarkan Data',
            onPressed: state.isLoading ? null : () => state.refreshData(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const WeeklyMeetingScreen(),
          const MediaScreen(),
          DashboardScreen(onNavigateTab: _onTabSelected),
          const TaskDashboardScreen(),
          const InstagramMockupScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2B2D42),
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_3_fill),
            label: 'MEETING',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.camera_fill),
            label: 'MEDIA',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.paintbrush_fill),
            label: 'CONTENT',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.share_up),
            label: 'PUBLISH',
          ),
        ],
      ),
    );
  }
}
