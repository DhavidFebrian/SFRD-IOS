import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/utils/whatsapp_formatter.dart';

class AnalyticScreen extends StatefulWidget {
  const AnalyticScreen({super.key});

  @override
  State<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends State<AnalyticScreen> {
  int _selectedTab = 0; // 0: Data Media, 1: Data Weekly Meeting

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final palette = AppColors.paletteFor(state.selectedThemeStyle);

    return Scaffold(
      backgroundColor: palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: palette.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => state.openDrawerPage(null),
        ),
        title: const Text(
          'Analytic Dashboard',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.selectedMonth,
              dropdownColor: palette.elevatedSurfaceColor,
              style: TextStyle(
                color: palette.secondaryAccentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              items: AppStateProvider.availableMonths
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) state.setSelectedMonth(v);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.elevatedSurfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderColor),
            ),
            child: Row(
              children: [
                _buildTabBtn(0, Icons.pie_chart_rounded, 'Data Media', palette),
                _buildTabBtn(
                  1,
                  Icons.groups_rounded,
                  'Data Weekly Meeting',
                  palette,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0
          ? _buildMediaAnalytics(state, palette)
          : _buildMeetingAnalytics(state, palette),
    );
  }

  Widget _buildTabBtn(
    int idx,
    IconData icon,
    String label,
    ThemePalette palette,
  ) {
    final selected = _selectedTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? palette.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.darkTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.darkTextSecondary,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaAnalytics(AppStateProvider state, ThemePalette palette) {
    final schedules = state.schedules;
    final total = schedules.length;
    final done = schedules.where((s) => s.isDone).length;
    final active = schedules.where((s) => s.isActive).length;
    final nonActive = schedules.where((s) => s.isNonActive).length;

    final davidCount = schedules
        .where((s) => s.staff.toLowerCase().contains('david'))
        .length;
    final alanCount = schedules
        .where((s) => s.staff.toLowerCase().contains('alan'))
        .length;

    final fotoCount = schedules
        .where((s) => s.type.toLowerCase().contains('foto'))
        .length;
    final videoCount = schedules
        .where((s) => s.type.toLowerCase().contains('video'))
        .length;
    final droneCount = schedules
        .where((s) => s.type.toLowerCase().contains('drone'))
        .length;
    final fotoUlangCount = schedules.where((s) => s.isFotoUlang).length;

    final reportText = WhatsAppFormatter.buildJadwalFotoReportText(
      month: state.selectedMonth,
      schedules: schedules,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Donut & KPI Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Jadwal Foto (${state.selectedMonth})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        done: done,
                        active: active,
                        nonActive: nonActive,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendRow(
                          'Selesai (Done)',
                          done,
                          total,
                          AppColors.statusDone,
                        ),
                        const SizedBox(height: 10),
                        _buildLegendRow(
                          'Jadwal Aktif',
                          active,
                          total,
                          AppColors.statusPending,
                        ),
                        const SizedBox(height: 10),
                        _buildLegendRow(
                          'Non-Aktif / Pending',
                          nonActive,
                          total,
                          AppColors.statusUrgent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Staff Workload Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi Staff Production',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _buildBarMetric(
                'David',
                davidCount,
                total > 0 ? total : 1,
                palette.accentColor,
              ),
              const SizedBox(height: 12),
              _buildBarMetric(
                'Alan',
                alanCount,
                total > 0 ? total : 1,
                palette.secondaryAccentColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Activity Breakdown
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Breakdown Tipe Kegiatan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      'Foto',
                      '$fotoCount',
                      Icons.camera_alt_rounded,
                      AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatBox(
                      'Video',
                      '$videoCount',
                      Icons.videocam_rounded,
                      AppColors.accentSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatBox(
                      'Drone',
                      '$droneCount',
                      Icons.flight_takeoff_rounded,
                      AppColors.brandYellow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatBox(
                      'Foto Ulang',
                      '$fotoUlangCount',
                      Icons.loop_rounded,
                      AppColors.statusPending,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // WhatsApp Report Generator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Generator Laporan Jadwal Foto (WA)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  reportText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Laporan'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: reportText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Laporan disalin ke clipboard!'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusDone,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Kirim ke WA'),
                      onPressed: () {
                        WhatsAppFormatter.openWhatsApp(message: reportText);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingAnalytics(AppStateProvider state, ThemePalette palette) {
    final listings = state.filteredMeetingListings;
    final total = listings.length;
    final hotCount = listings
        .where((l) => l.keterangan.toUpperCase().contains('HOT'))
        .length;
    final fotoUlangCount = listings
        .where((l) => l.keterangan.toUpperCase().contains('FOTO ULANG'))
        .length;
    final igList = listings
        .where((l) => l.keterangan.toUpperCase().contains('IG'))
        .toList();
    final igPosted = igList.where((l) => l.postingIg).length;
    final editedCount = igList.where((l) => l.meHighlighted).length;

    final reportText = WhatsAppFormatter.buildWeeklyReportText(
      month: state.selectedMonth,
      meetingDate: state.selectedMeetingDate ?? 'Semua Tanggal',
      listings: listings,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Selector Chips
        if (state.availableMeetingDates.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Semua Tanggal'),
                    selected: state.selectedMeetingDate == null ||
                        state.selectedMeetingDate!.isEmpty,
                    onSelected: (_) => state.setSelectedMeetingDate(null),
                  ),
                ),
                ...state.availableMeetingDates.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: state.selectedMeetingDate == d,
                      onSelected: (_) => state.setSelectedMeetingDate(d),
                    ),
                  );
                }),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Weekly Meeting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      'Total Listing',
                      '$total',
                      Icons.list_alt_rounded,
                      palette.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatBox(
                      'Hot Property',
                      '$hotCount',
                      Icons.local_fire_department_rounded,
                      AppColors.statusUrgent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatBox(
                      'Foto Ulang',
                      '$fotoUlangCount',
                      Icons.camera_enhance_rounded,
                      AppColors.statusPending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatBox(
                      'Target IG',
                      '${igList.length}',
                      Icons.photo_camera_rounded,
                      AppColors.accentSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBarMetric(
                'Sudah Diedit (Tandai ME)',
                editedCount,
                igList.isNotEmpty ? igList.length : 1,
                AppColors.brandYellow,
              ),
              const SizedBox(height: 10),
              _buildBarMetric(
                'Sudah Posting IG',
                igPosted,
                igList.isNotEmpty ? igList.length : 1,
                AppColors.statusDone,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Weekly Meeting Report Generator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Generator Laporan Weekly Meeting (WA)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  reportText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Laporan'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: reportText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Laporan disalin ke clipboard!'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusDone,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Kirim ke WA'),
                      onPressed: () {
                        WhatsAppFormatter.openWhatsApp(message: reportText);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBarMetric(String label, int value, int max, Color color) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              '$value Jadwal',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 9,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int done;
  final int active;
  final int nonActive;

  _DonutChartPainter({
    required this.done,
    required this.active,
    required this.nonActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = done + active + nonActive;
    final rect = Offset.zero & size;
    const strokeWidth = 16.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (total == 0) {
      paint.color = Colors.white12;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        0,
        math.pi * 2,
        false,
        paint,
      );
      return;
    }

    var startAngle = -math.pi / 2;
    void drawSlice(int count, Color color) {
      if (count <= 0) return;
      final sweep = (count / total) * math.pi * 2;
      paint.color = color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }

    drawSlice(done, AppColors.statusDone);
    drawSlice(active, AppColors.statusPending);
    drawSlice(nonActive, AppColors.statusUrgent);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.done != done ||
        oldDelegate.active != active ||
        oldDelegate.nonActive != nonActive;
  }
}
