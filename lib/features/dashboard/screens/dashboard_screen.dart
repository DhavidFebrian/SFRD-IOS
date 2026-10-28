import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../media/models/schedule.dart';
import '../../publish/models/publish_item.dart';
import '../../tasks/models/edit_foto_task.dart';
import '../../weekly_meeting/models/meeting_listing.dart';

typedef WorkflowDashboardScreen = DashboardScreen;

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _selectedCalendarDate;
  bool _showAllReviewItems = false;
  String? _lastTrackedMonth;

  DateTime _resolveMonthYear(String selectedMonth) {
    final lower = selectedMonth.toLowerCase();
    int year = 2026;
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(selectedMonth);
    if (yearMatch != null) {
      year = int.tryParse(yearMatch.group(1)!) ?? 2026;
    }
    for (int i = 0; i < kIndonesianMonths.length; i++) {
      if (lower.contains(kIndonesianMonths[i].toLowerCase())) {
        return DateTime(year, i + 1, 1);
      }
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _navigateToTab(AppStateProvider state, int index) {
    state.setTabIndex(index);
    widget.onNavigateTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final themeStyle = state.selectedThemeStyle;

    if (_lastTrackedMonth != state.selectedMonth) {
      _lastTrackedMonth = state.selectedMonth;
      _selectedCalendarDate = null;
      _showAllReviewItems = false;
    }

    final schedules = state.schedules;
    final tasks = state.editFotoTasks;
    final meetings = state.meetingListings;
    final feedItems = state.allPublishFeedItems;
    final reels = state.reelItems;

    // Date references
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // KPI counts
    final hariIniCount = schedules.where((s) {
      final d = parseIndonesianDate(s.tanggal);
      return d != null && _isSameDay(d, today);
    }).length;

    final fotoBesokCount = schedules.where((s) {
      final d = parseIndonesianDate(s.tanggal);
      return d != null && _isSameDay(d, tomorrow);
    }).length;

    final pendingCount = schedules.where((s) => s.isNonActive).length;

    final postHariIniCount = feedItems.where((item) {
      final d = parseIndonesianDate(item.jadwalPosting);
      return d != null && _isSameDay(d, today);
    }).length;

    final belumPostCount = feedItems.where((item) => !item.postingIg).length;

    // Overall completion calculation
    final doneSchedules = schedules.where((s) => s.isDone).length;
    final doneTasks = tasks.where((t) => t.done).length;
    final igTargetMeetings = meetings.where((m) => m.isIgTarget).toList();
    final postedMeetings = igTargetMeetings.where((m) => m.postingIg).length;

    final totalUnits =
        schedules.length + tasks.length + igTargetMeetings.length;
    final completedUnits = doneSchedules + doneTasks + postedMeetings;
    final overallPercent =
        totalUnits > 0 ? ((completedUnits / totalUnits) * 100).round() : 0;

    return Scaffold(
      backgroundColor: themeStyle.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: themeStyle.primary,
          backgroundColor: themeStyle.surface,
          onRefresh: state.refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Top Header & Month Selector Chips
              SliverToBoxAdapter(
                child: _buildTopHeader(context, state, themeStyle),
              ),

              // 2. OverallProgressCard with 5 KPI Metric Pills
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: OverallProgressCard(
                    overallPercent: overallPercent,
                    completedUnits: completedUnits,
                    totalUnits: totalUnits,
                    hariIniCount: hariIniCount,
                    fotoBesokCount: fotoBesokCount,
                    pendingCount: pendingCount,
                    postHariIniCount: postHariIniCount,
                    belumPostCount: belumPostCount,
                    themeStyle: themeStyle,
                  ),
                ),
              ),

              // 3. Interactive DashboardCalendarView + 2x2 DetailedScheduleReviewGridItem
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: DashboardCalendarView(
                    monthDate: _resolveMonthYear(state.selectedMonth),
                    selectedMonthLabel: state.selectedMonth,
                    schedules: schedules,
                    selectedDate: _selectedCalendarDate,
                    showAllItems: _showAllReviewItems,
                    themeStyle: themeStyle,
                    state: state,
                    onSelectDate: (dt) {
                      setState(() {
                        if (_selectedCalendarDate != null &&
                            dt != null &&
                            _isSameDay(_selectedCalendarDate!, dt)) {
                          _selectedCalendarDate = null;
                        } else {
                          _selectedCalendarDate = dt;
                        }
                        _showAllReviewItems = false;
                      });
                    },
                    onToggleShowAll: () {
                      setState(() {
                        _showAllReviewItems = !_showAllReviewItems;
                      });
                    },
                  ),
                ),
              ),

              // 4. Section Title: WORKFLOW PIPELINE CARDS
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: themeStyle.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MONITOR DIVISI PRODUKSI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      if (state.isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 5. Four Workflow Monitor Cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    MeetingWorkflowCard(
                      listings: meetings,
                      selectedMeetingDate: state.selectedMeetingDate,
                      themeStyle: themeStyle,
                      onSelectBarDate: (date) {
                        state.setSelectedMeetingDate(date);
                        _navigateToTab(state, 0);
                      },
                      onOpenMeeting: () => _navigateToTab(state, 0),
                    ),
                    const SizedBox(height: 14),
                    MediaWorkflowCard(
                      schedules: schedules,
                      themeStyle: themeStyle,
                      onOpenMedia: () => _navigateToTab(state, 1),
                    ),
                    const SizedBox(height: 14),
                    ContentWorkflowCard(
                      tasks: tasks,
                      meetings: meetings,
                      themeStyle: themeStyle,
                      onOpenSubTab: (subTab) {
                        state.setSelectedTaskSubTab(subTab);
                        _navigateToTab(state, 3);
                      },
                    ),
                    const SizedBox(height: 14),
                    PublishWorkflowCard(
                      feedItems: feedItems,
                      reelItems: reels,
                      themeStyle: themeStyle,
                      onOpenSubTab: (subTab) {
                        state.setSelectedPublishSubTab(subTab);
                        _navigateToTab(state, 4);
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    AppStateProvider state,
    AppThemeStyle themeStyle,
  ) {
    final unread = state.unreadChatCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: themeStyle.surface.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderDark, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeStyle.primary.withValues(alpha: 0.25),
                      themeStyle.secondary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: themeStyle.primary.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: themeStyle.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKFLOW MONITOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ray White Cipete Media Production',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat Icon Button with Unread Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => state.openChatScreen(true),
                    style: IconButton.styleFrom(
                      backgroundColor: themeStyle.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderDark),
                      ),
                    ),
                    icon: const Icon(
                      CupertinoIcons.chat_bubble_2_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Team Chat',
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: themeStyle.background,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
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
              const SizedBox(width: 8),
              // Refresh Button
              IconButton(
                onPressed: state.isLoading ? null : () => state.refreshData(),
                style: IconButton.styleFrom(
                  backgroundColor: themeStyle.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderDark),
                  ),
                ),
                icon: state.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: themeStyle.primary,
                        ),
                      )
                    : Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        color: themeStyle.primary,
                        size: 20,
                      ),
                tooltip: 'Sinkronisasi Data',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal Month Selector Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppStateProvider.availableMonths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final month = AppStateProvider.availableMonths[index];
                final isSelected = state.selectedMonth == month;
                final isFotoUlang = month == 'Foto Ulang';

                return GestureDetector(
                  onTap: () => state.setSelectedMonth(month),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isFotoUlang
                                  ? [
                                      AppColors.fotoUlangBlue,
                                      AppColors.glowBlue,
                                    ]
                                  : [
                                      themeStyle.primary,
                                      themeStyle.secondary,
                                    ],
                            )
                          : null,
                      color: isSelected ? null : themeStyle.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.borderDark,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    themeStyle.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFotoUlang) ...[
                          Icon(
                            CupertinoIcons.camera_rotate_fill,
                            size: 13,
                            color: isSelected
                                ? Colors.black
                                : AppColors.fotoUlangBlue,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          month,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : AppColors.textSecondaryDark,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// OVERALL PROGRESS CARD WITH 5 KPI PILLS
// =============================================================================
class OverallProgressCard extends StatelessWidget {
  final int overallPercent;
  final int completedUnits;
  final int totalUnits;
  final int hariIniCount;
  final int fotoBesokCount;
  final int pendingCount;
  final int postHariIniCount;
  final int belumPostCount;
  final AppThemeStyle themeStyle;

  const OverallProgressCard({
    super.key,
    required this.overallPercent,
    required this.completedUnits,
    required this.totalUnits,
    required this.hariIniCount,
    required this.fotoBesokCount,
    required this.pendingCount,
    required this.postHariIniCount,
    required this.belumPostCount,
    required this.themeStyle,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = (overallPercent / 100.0).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeStyle.card.withValues(alpha: 0.95),
                themeStyle.surface.withValues(alpha: 0.90),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeStyle.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    themeStyle.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'OVERALL PROGRESS',
                                style: TextStyle(
                                  color: themeStyle.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$completedUnits / $totalUnits selesai',
                              style: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Performa Produksi Bulanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeStyle.primary,
                          themeStyle.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$overallPercent%',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(themeStyle.primary),
                ),
              ),
              const SizedBox(height: 16),
              // 5 KPI Metric Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildKpiPill(
                      label: 'Hari Ini',
                      count: hariIniCount,
                      icon: CupertinoIcons.sun_max_fill,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiPill(
                      label: 'Foto Besok',
                      count: fotoBesokCount,
                      icon: CupertinoIcons.calendar_today,
                      color: AppColors.glowBlue,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiPill(
                      label: 'Pending',
                      count: pendingCount,
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiPill(
                      label: 'Post Hari Ini',
                      count: postHariIniCount,
                      icon: CupertinoIcons.paperplane_fill,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _buildKpiPill(
                      label: 'Belum Post',
                      count: belumPostCount,
                      icon: CupertinoIcons.clock_fill,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiPill({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.95),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// INTERACTIVE DASHBOARD CALENDAR VIEW + 2x2 DETAILED SCHEDULE REVIEW GRID
// =============================================================================
class DashboardCalendarView extends StatelessWidget {
  final DateTime monthDate;
  final String selectedMonthLabel;
  final List<Schedule> schedules;
  final DateTime? selectedDate;
  final bool showAllItems;
  final AppThemeStyle themeStyle;
  final AppStateProvider state;
  final ValueChanged<DateTime?> onSelectDate;
  final VoidCallback onToggleShowAll;

  const DashboardCalendarView({
    super.key,
    required this.monthDate,
    required this.selectedMonthLabel,
    required this.schedules,
    required this.selectedDate,
    required this.showAllItems,
    required this.themeStyle,
    required this.state,
    required this.onSelectDate,
    required this.onToggleShowAll,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    // Monday = 1 ... Sunday = 7 -> 0-based offset for Mon-Sun header
    final leadingEmptyDays = firstDayOfMonth.weekday - 1;

    // Group schedules by day of month
    final Map<int, List<Schedule>> schedulesByDay = {};
    for (final s in schedules) {
      final dt = parseIndonesianDate(s.tanggal);
      if (dt != null &&
          dt.year == monthDate.year &&
          dt.month == monthDate.month) {
        schedulesByDay.putIfAbsent(dt.day, () => []).add(s);
      }
    }

    // Filter schedules for the review grid below
    final List<Schedule> reviewSchedules;
    if (selectedDate != null) {
      reviewSchedules = schedules.where((s) {
        final dt = parseIndonesianDate(s.tanggal);
        return dt != null && _isSameDay(dt, selectedDate!);
      }).toList();
    } else {
      reviewSchedules = schedules;
    }

    final displayedSchedules = showAllItems
        ? reviewSchedules
        : reviewSchedules.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Header
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar_circle_fill,
                color: themeStyle.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KALENDER JADWAL • ${selectedMonthLabel.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Text(
                      'Ketuk tanggal untuk memfilter jadwal foto di bawah',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedDate != null)
                TextButton.icon(
                  onPressed: () => onSelectDate(null),
                  style: TextButton.styleFrom(
                    foregroundColor: themeStyle.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 14),
                  label: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            children: [
              _buildLegendDot(AppColors.success, 'Selesai'),
              const SizedBox(width: 14),
              _buildLegendDot(AppColors.warning, 'Aktif / On Progress'),
              const SizedBox(width: 14),
              _buildLegendDot(AppColors.error, 'Pending / Non-Aktif'),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Headers (Sen - Min)
          Row(
            children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyDays + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }
              final day = index - leadingEmptyDays + 1;
              final cellDate = DateTime(monthDate.year, monthDate.month, day);
              final daySchedules = schedulesByDay[day] ?? const [];
              final isSelected =
                  selectedDate != null && _isSameDay(selectedDate!, cellDate);

              Color? dotColor;
              if (daySchedules.isNotEmpty) {
                if (daySchedules.every((s) => s.isDone)) {
                  dotColor = AppColors.success;
                } else if (daySchedules.any((s) => s.isActive)) {
                  dotColor = AppColors.warning;
                } else {
                  dotColor = AppColors.error;
                }
              }

              return GestureDetector(
                onTap: () => onSelectDate(cellDate),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeStyle.primary
                        : (daySchedules.isNotEmpty
                            ? themeStyle.surface
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? themeStyle.primary
                          : (daySchedules.isNotEmpty
                              ? AppColors.borderDark
                              : Colors.white10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : (daySchedules.isNotEmpty
                                  ? Colors.white
                                  : Colors.white54),
                          fontSize: 12,
                          fontWeight: isSelected || daySchedules.isNotEmpty
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      if (dotColor != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (daySchedules.length > 1) ...[
                              const SizedBox(width: 2),
                              Text(
                                '${daySchedules.length}',
                                style: TextStyle(
                                  color: isSelected ? Colors.black87 : dotColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(color: AppColors.borderDark, height: 24),

          // Review Grid Header & Lihat Semua (N) Toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate != null
                      ? 'Jadwal ${selectedDate!.day} ${kIndonesianMonths[selectedDate!.month - 1]} (${reviewSchedules.length})'
                      : 'Review Jadwal Bulan Ini (${reviewSchedules.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (reviewSchedules.length > 4)
                TextButton(
                  onPressed: onToggleShowAll,
                  style: TextButton.styleFrom(
                    foregroundColor: themeStyle.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    showAllItems
                        ? 'Tampilkan Ringkas'
                        : 'Lihat Semua (${reviewSchedules.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (displayedSchedules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: themeStyle.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Column(
                children: [
                  Icon(
                    CupertinoIcons.calendar_badge_minus,
                    color: Colors.white30,
                    size: 26,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tidak ada jadwal foto pada tanggal ini',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedSchedules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.38,
              ),
              itemBuilder: (context, idx) {
                final s = displayedSchedules[idx];
                return DetailedScheduleReviewGridItem(
                  schedule: s,
                  imageUrl: state.getListingImage(s.idListing),
                  onTap: () => state.openScheduleDetail(s, initialPage: 1),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DetailedScheduleReviewGridItem extends StatelessWidget {
  final Schedule schedule;
  final String? imageUrl;
  final VoidCallback onTap;

  const DetailedScheduleReviewGridItem({
    super.key,
    required this.schedule,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = schedule.isDone
        ? AppColors.success
        : (schedule.isNonActive ? AppColors.error : AppColors.warning);
    final statusLabel = schedule.isDone
        ? 'DONE'
        : (schedule.isNonActive ? 'PENDING' : 'AKTIF');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Opacity(
                opacity: 0.28,
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceDark.withValues(alpha: 0.72),
                    AppColors.backgroundDark.withValues(alpha: 0.94),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rwcYellow,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '#${schedule.cleanId.isNotEmpty ? schedule.cleanId : "-"}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    schedule.namaMe.isNotEmpty
                        ? schedule.namaMe
                        : 'ME Belum Diisi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.lokasi.isNotEmpty
                        ? schedule.lokasi
                        : schedule.type,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.clock,
                        size: 11,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${schedule.formattedTime12Hour} • ${schedule.tanggal}',
                          style: const TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 1. MEETING WORKFLOW CARD + WEEKLY BAR CHART
// =============================================================================
class MeetingWorkflowCard extends StatelessWidget {
  final List<MeetingListing> listings;
  final String? selectedMeetingDate;
  final AppThemeStyle themeStyle;
  final ValueChanged<String> onSelectBarDate;
  final VoidCallback onOpenMeeting;

  const MeetingWorkflowCard({
    super.key,
    required this.listings,
    required this.selectedMeetingDate,
    required this.themeStyle,
    required this.onSelectBarDate,
    required this.onOpenMeeting,
  });

  @override
  Widget build(BuildContext context) {
    final totalListings = listings.length;
    final igTargets = listings.where((l) => l.isIgTarget).toList();
    final igPosted = igTargets.where((l) => l.postingIg).length;

    // Group by meeting date
    final Map<String, int> countsByDate = {};
    for (final l in listings) {
      final d = l.date.trim().isNotEmpty ? l.date.trim() : 'Lainnya';
      countsByDate[d] = (countsByDate[d] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.person_3_fill,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY MEETING MONITOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Total listing dibahas & target IG',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onOpenMeeting,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 15),
                label: const Text(
                  'Buka Meeting',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatBox(
                  label: 'Total Listing',
                  value: '$totalListings',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatBox(
                  label: 'Target IG',
                  value: '${igTargets.length}',
                  color: AppColors.igPink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatBox(
                  label: 'Sudah Post IG',
                  value: '$igPosted / ${igTargets.length}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          if (countsByDate.isNotEmpty) ...[
            const SizedBox(height: 14),
            MeetingWeeklyBarChart(
              countsByDate: countsByDate,
              selectedDate: selectedMeetingDate,
              onSelectDate: onSelectBarDate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingWeeklyBarChart extends StatelessWidget {
  final Map<String, int> countsByDate;
  final String? selectedDate;
  final ValueChanged<String> onSelectDate;

  const MeetingWeeklyBarChart({
    super.key,
    required this.countsByDate,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final entries = countsByDate.entries.toList();
    final maxCount = entries.fold<int>(
      1,
      (prev, e) => e.value > prev ? e.value : prev,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_square_fill,
                size: 14,
                color: AppColors.accent,
              ),
              SizedBox(width: 6),
              Text(
                'Distribusi Sesi Meeting (Ketuk bar untuk buka tanggal)',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final isSelected = selectedDate == entry.key;
                final ratio = (entry.value / maxCount).clamp(0.15, 1.0);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectDate(entry.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio,
                                widthFactor: 0.65,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [
                                              AppColors.accent,
                                              AppColors.rwcYellow,
                                            ]
                                          : [
                                              AppColors.glowBlue,
                                              AppColors.glowPurple,
                                            ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textSecondaryDark,
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. MEDIA WORKFLOW CARD
// =============================================================================
class MediaWorkflowCard extends StatelessWidget {
  final List<Schedule> schedules;
  final AppThemeStyle themeStyle;
  final VoidCallback onOpenMedia;

  const MediaWorkflowCard({
    super.key,
    required this.schedules,
    required this.themeStyle,
    required this.onOpenMedia,
  });

  @override
  Widget build(BuildContext context) {
    final total = schedules.length;
    final doneCount = schedules.where((s) => s.isDone).length;
    final activeCount = schedules.where((s) => s.isActive).length;
    final nonActiveCount = schedules.where((s) => s.isNonActive).length;
    final progress = total > 0 ? (doneCount / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.glowBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: AppColors.glowBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEDIA PRODUCTION MONITOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Progress liputan foto & video (${(progress * 100).round()}%)',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onOpenMedia,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.glowBlue,
                  backgroundColor: AppColors.glowBlue.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 15),
                label: const Text(
                  'Buka Media',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCountBadge(
                  label: 'Done',
                  count: doneCount,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountBadge(
                  label: 'Aktif',
                  count: activeCount,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountBadge(
                  label: 'Non-Aktif',
                  count: nonActiveCount,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. CONTENT WORKFLOW CARD
// =============================================================================
class ContentWorkflowCard extends StatelessWidget {
  final List<EditFotoTask> tasks;
  final List<MeetingListing> meetings;
  final AppThemeStyle themeStyle;
  final ValueChanged<int> onOpenSubTab;

  const ContentWorkflowCard({
    super.key,
    required this.tasks,
    required this.meetings,
    required this.themeStyle,
    required this.onOpenSubTab,
  });

  @override
  Widget build(BuildContext context) {
    final garisTanahTasks = tasks.where((t) => t.isGarisTanah).toList();
    final garisTanahDone = garisTanahTasks.where((t) => t.done).length;
    final totalTasksDone = tasks.where((t) => t.done).length;
    final taskRatio =
        tasks.isNotEmpty ? (totalTasksDone / tasks.length).clamp(0.0, 1.0) : 0.0;

    final igMeetings = meetings.where((l) => l.isIgTarget).toList();
    final editedMeetings = igMeetings.where((l) => l.meHighlighted).length;
    final meetingEditRatio = igMeetings.isNotEmpty
        ? (editedMeetings / igMeetings.length).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.glowPurple.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.paintbrush_fill,
                  color: AppColors.glowPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTENT & EDITING MONITOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Garis Tanah, Up Foto & Edit Foto Meeting',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress 1: Content / Garis Tanah
          _buildProgressRow(
            title:
                'Task Content & Garis Tanah ($garisTanahDone/${garisTanahTasks.length} Drone)',
            trailing: '$totalTasksDone / ${tasks.length} Done',
            progress: taskRatio,
            color: AppColors.glowPurple,
          ),
          const SizedBox(height: 12),
          // Progress 2: Edit Foto Meeting
          _buildProgressRow(
            title: 'Edit Foto Meeting (ME Highlight)',
            trailing: '$editedMeetings / ${igMeetings.length} Edited',
            progress: meetingEditRatio,
            color: AppColors.info,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onOpenSubTab(0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.glowPurple,
                    side: BorderSide(
                      color: AppColors.glowPurple.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.layers_alt_fill, size: 15),
                  label: const Text(
                    'Sub-Tab Content',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onOpenSubTab(1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: BorderSide(
                      color: AppColors.info.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, size: 15),
                  label: const Text(
                    'Edit Foto Meeting',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String title,
    required String trailing,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 4. PUBLISH WORKFLOW CARD
// =============================================================================
class PublishWorkflowCard extends StatelessWidget {
  final List<PublishFeedItem> feedItems;
  final List<ReelItem> reelItems;
  final AppThemeStyle themeStyle;
  final ValueChanged<int> onOpenSubTab;

  const PublishWorkflowCard({
    super.key,
    required this.feedItems,
    required this.reelItems,
    required this.themeStyle,
    required this.onOpenSubTab,
  });

  @override
  Widget build(BuildContext context) {
    final totalFeeds = feedItems.length;
    final postedFeeds = feedItems.where((f) => f.postingIg).length;
    final feedProgress =
        totalFeeds > 0 ? (postedFeeds / totalFeeds).clamp(0.0, 1.0) : 0.0;

    final totalReels = reelItems.length;
    final postedReels = reelItems.where((r) => r.isPublished).length;
    final reelProgress =
        totalReels > 0 ? (postedReels / totalReels).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.igPink.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.paperplane_fill,
                  color: AppColors.igPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTAGRAM PUBLISH MONITOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Status tayangan IG Feeds & Reels',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildPublishMetricTile(
                  title: 'IG Feeds',
                  posted: postedFeeds,
                  total: totalFeeds,
                  progress: feedProgress,
                  color: AppColors.igPink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPublishMetricTile(
                  title: 'IG Reels',
                  posted: postedReels,
                  total: totalReels,
                  progress: reelProgress,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onOpenSubTab(0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.igPink,
                    side: BorderSide(
                      color: AppColors.igPink.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.square_grid_2x2_fill, size: 15),
                  label: const Text(
                    'Buka IG Feeds',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onOpenSubTab(1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.play_rectangle_fill, size: 15),
                  label: const Text(
                    'Buka IG Reels',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublishMetricTile({
    required String title,
    required int posted,
    required int total,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$posted / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
