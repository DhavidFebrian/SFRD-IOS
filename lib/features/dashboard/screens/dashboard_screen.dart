import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_provider.dart';
import '../../media/models/schedule.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    // Metrics calculation
    final totalSchedules = state.schedules.length;
    final doneSchedules = state.schedules.where((s) => s.isDone).length;
    final pendingSchedules = totalSchedules - doneSchedules;

    final totalTasks = state.editFotoTasks.length;
    final doneTasks = state.editFotoTasks.where((t) => t.done).length;
    final pendingTasks = totalTasks - doneTasks;
    final postedIgTasks = state.editFotoTasks.where((t) => t.postingIg).length;

    final totalMeetings = state.meetingListings.length;

    final scheduleProgress = totalSchedules > 0 ? (doneSchedules / totalSchedules) : 0.0;
    final taskProgress = totalTasks > 0 ? (doneTasks / totalTasks) : 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: state.refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome & Sheet Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B2D42), Color(0xFF1E202C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ringkasan Operasional',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE600),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.selectedMonth,
                          style: const TextStyle(
                            color: Color(0xFF2B2D42),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pusat kontrol jadwal media, editing, dan rapat listing Ray White Cipete.',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Progress Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress Jadwal Foto: ${(scheduleProgress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: scheduleProgress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE600)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress Edit Foto: ${(taskProgress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: taskProgress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4 Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Jadwal Media',
                    value: '$totalSchedules',
                    subtitle: '$doneSchedules selesai • $pendingSchedules pending',
                    icon: CupertinoIcons.camera_fill,
                    color: Colors.blue.shade700,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Edit Foto Task',
                    value: '$totalTasks',
                    subtitle: '$doneTasks selesai • $pendingTasks pending',
                    icon: CupertinoIcons.paintbrush_fill,
                    color: Colors.deepPurple.shade600,
                    onTap: () => onNavigateTab?.call(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Posting IG',
                    value: '$postedIgTasks',
                    subtitle: 'dari $totalTasks listing foto',
                    icon: CupertinoIcons.photo_fill,
                    color: Colors.pink.shade600,
                    onTap: () => onNavigateTab?.call(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Weekly Meeting',
                    value: '$totalMeetings',
                    subtitle: 'listing terdaftar dalam agenda',
                    icon: CupertinoIcons.person_3_fill,
                    color: Colors.amber.shade800,
                    onTap: () => onNavigateTab?.call(0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section: Jadwal Terbaru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jadwal Terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => onNavigateTab?.call(1),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (state.schedules.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Belum ada jadwal pada lembar ini.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...state.schedules.take(5).map((sched) => _buildScheduleMiniTile(sched)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2D42),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleMiniTile(Schedule sched) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE600),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            sched.idListing.isNotEmpty ? sched.idListing : 'L-?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2B2D42)),
          ),
        ),
        title: Text(sched.namaMe.isNotEmpty ? sched.namaMe : 'ME Belum Ditentukan', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${sched.tanggal} • ${sched.jam} • ${sched.type}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: sched.isDone ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            sched.isDone ? 'Selesai' : 'Pending',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: sched.isDone ? Colors.green.shade900 : Colors.orange.shade900,
            ),
          ),
        ),
      ),
    );
  }
}
