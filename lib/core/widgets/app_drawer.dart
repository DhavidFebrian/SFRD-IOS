import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../state/app_state_provider.dart';
import '../../features/media/widgets/add_schedule_dialog.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B2D42), Color(0xFF1E202C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE600),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera_fill,
                    color: Color(0xFF2B2D42),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SFRD Media Production',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ray White Cipete',
                  style: TextStyle(
                    color: Color(0xFFFFE600),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.calendar, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Sheet: ${state.selectedMonth}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Drawer Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Quick Actions
                ListTile(
                  leading: const Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFFE53935)),
                  title: const Text('Tambah Jadwal Baru', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => const AddScheduleDialog(),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.arrow_clockwise, color: Color(0xFF1E88E5)),
                  title: const Text('Segarkan Data'),
                  onTap: () {
                    Navigator.pop(context);
                    state.refreshData();
                  },
                ),
                const Divider(),

                // Month Selector Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.layers_alt, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'PILIH BULAN / LEMBAR KERJA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                ...AppStateProvider.availableMonths.map((month) {
                  final isSelected = state.selectedMonth == month;
                  final isFotoUlang = month.toLowerCase().contains('foto ulang');

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: isSelected
                          ? (isFotoUlang ? Colors.deepOrange : const Color(0xFF2B2D42))
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                    title: Text(
                      month,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? (isFotoUlang ? Colors.deepOrange : const Color(0xFF2B2D42))
                            : Colors.black87,
                      ),
                    ),
                    tileColor: isSelected
                        ? (isFotoUlang
                            ? Colors.deepOrange.withOpacity(0.08)
                            : Colors.amber.withOpacity(0.12))
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      state.setSelectedMonth(month);
                    },
                  );
                }).toList(),

                const Divider(),

                // Settings
                ListTile(
                  leading: const Icon(CupertinoIcons.settings),
                  title: const Text('Pengaturan API & Template'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'SFRD iOS v8.8.11 • Sync with Sheets API',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
