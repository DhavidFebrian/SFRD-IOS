import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../publish/models/publish_item.dart';
import '../models/schedule.dart';
import '../widgets/add_schedule_dialog.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCalendarView = false;
  bool _isFilterExpanded = false;
  DateTime? _selectedCalendarDay;
  String? _lastTrackedMonth;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _cycleMonth(AppStateProvider state, int delta) {
    const months = AppStateProvider.availableMonths;
    final currentIdx = months.indexOf(state.selectedMonth);
    if (currentIdx == -1) return;
    final nextIdx = (currentIdx + delta) % months.length;
    final resolvedIdx = nextIdx < 0 ? months.length - 1 : nextIdx;
    state.setSelectedMonth(months[resolvedIdx]);
  }

  Future<void> _pickDateRange(
    BuildContext context,
    AppStateProvider state, {
    required bool isStart,
  }) async {
    final initial = isStart
        ? (state.filterStartDate ?? DateTime.now())
        : (state.filterEndDate ?? state.filterStartDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.surfaceDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (isStart) {
        state.setDateRangeFilter(picked, state.filterEndDate);
      } else {
        state.setDateRangeFilter(state.filterStartDate, picked);
      }
    }
  }

  Future<void> _confirmDeleteSchedule(
    BuildContext context,
    AppStateProvider state,
    Schedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Row(
          children: [
            Icon(
              CupertinoIcons.trash_circle_fill,
              color: AppColors.error,
              size: 24,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hapus Jadwal Foto?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal #${schedule.cleanId} (${schedule.namaMe}) pada ${schedule.tanggal}?',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Hapus Permanen',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await state.deleteSchedule(schedule);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Jadwal #${schedule.cleanId} telah dihapus.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final themeStyle = state.selectedThemeStyle;

    if (_lastTrackedMonth != state.selectedMonth) {
      _lastTrackedMonth = state.selectedMonth;
      _selectedCalendarDay = null;
    }

    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final allSchedules = state.schedules;
    final totalCount = allSchedules.length;
    final activeCount = allSchedules.where((s) => s.isActive).length;
    final nonActiveCount = allSchedules.where((s) => s.isNonActive).length;
    final doneCount = allSchedules.where((s) => s.isDone).length;

    List<Schedule> filteredSchedules = state.filteredSchedules;
    if (_isCalendarView && _selectedCalendarDay != null) {
      filteredSchedules = filteredSchedules.where((s) {
        final dt = parseIndonesianDate(s.tanggal);
        return dt != null && _isSameDay(dt, _selectedCalendarDay!);
      }).toList();
    }

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
              // 1. Header Bar
              SliverToBoxAdapter(
                child: _buildHeaderBar(context, state, themeStyle),
              ),

              // 2. Month Switcher < Bulan > + Tambah Button + Daftar/Kalender Toggle
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildMonthAndViewControls(context, state, themeStyle),
                ),
              ),

              // 3. 4 Clickable CompactStatCards (Total, Aktif, Non-Aktif, Selesai)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: CompactStatCard(
                          label: 'Total',
                          count: totalCount,
                          color: AppColors.glowBlue,
                          icon: CupertinoIcons.square_stack_3d_up_fill,
                          isSelected: state.mediaFilter == 'Semua',
                          onTap: () => state.setMediaFilter('Semua'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CompactStatCard(
                          label: 'Aktif',
                          count: activeCount,
                          color: AppColors.warning,
                          icon: CupertinoIcons.flame_fill,
                          isSelected: state.mediaFilter == 'Aktif',
                          onTap: () => state.setMediaFilter('Aktif'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CompactStatCard(
                          label: 'Non-Aktif',
                          count: nonActiveCount,
                          color: AppColors.error,
                          icon: CupertinoIcons.pause_circle_fill,
                          isSelected: state.mediaFilter == 'Non-Aktif',
                          onTap: () => state.setMediaFilter('Non-Aktif'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CompactStatCard(
                          label: 'Selesai',
                          count: doneCount,
                          color: AppColors.success,
                          icon: CupertinoIcons.checkmark_seal_fill,
                          isSelected: state.mediaFilter == 'Selesai',
                          onTap: () => state.setMediaFilter('Selesai'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Search Bar + Collapsible "Saring" Filter Panel
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildSearchAndFilterPanel(context, state, themeStyle),
                ),
              ),

              // 5. Optional Interactive Calendar Strip/Grid when in Kalender View
              if (_isCalendarView)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildMediaCalendarPanel(state, themeStyle),
                  ),
                ),

              // 6. 2-Column Grid of MediaScheduleCard
              if (state.isLoading && allSchedules.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (filteredSchedules.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: _buildEmptyState(state, themeStyle),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.67,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final s = filteredSchedules[index];
                        return MediaScheduleCard(
                          schedule: s,
                          imageUrl: state.getListingImage(s.idListing),
                          price: state.getListingPrice(s.idListing),
                          themeStyle: themeStyle,
                          onTapCard: () =>
                              state.openScheduleDetail(s, initialPage: 1),
                          onEdit: () =>
                              state.openScheduleDetail(s, initialPage: 0),
                          onFollowUpWa: () =>
                              state.openScheduleDetail(s, initialPage: 2),
                          onDelete: () =>
                              _confirmDeleteSchedule(context, state, s),
                        );
                      },
                      childCount: filteredSchedules.length,
                    ),
                  ),
                ),

              // 7. MonthlyAnalysisCard at Bottom with Custom Painted Donut Chart
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                sliver: SliverToBoxAdapter(
                  child: MonthlyAnalysisCard(
                    monthLabel: state.selectedMonth,
                    doneCount: doneCount,
                    activeCount: activeCount,
                    nonActiveCount: nonActiveCount,
                    themeStyle: themeStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context,
    AppStateProvider state,
    AppThemeStyle themeStyle,
  ) {
    final unread = state.unreadChatCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: themeStyle.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderDark, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: themeStyle.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeStyle.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(
              CupertinoIcons.camera_viewfinder,
              color: themeStyle.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Foto RWC David',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Manajemen Jadwal Liputan • ${state.selectedMonth}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Chat Badge Icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => state.openChatScreen(true),
                style: IconButton.styleFrom(
                  backgroundColor: themeStyle.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                    side: const BorderSide(color: AppColors.borderDark),
                  ),
                ),
                icon: const Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  color: Colors.white,
                  size: 19,
                ),
                tooltip: 'Chat Tim',
              ),
              if (unread > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
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
          const SizedBox(width: 6),
          // Sync Icon
          IconButton(
            onPressed: state.isLoading ? null : () => state.refreshData(),
            style: IconButton.styleFrom(
              backgroundColor: themeStyle.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
                side: const BorderSide(color: AppColors.borderDark),
              ),
            ),
            icon: state.isLoading
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: themeStyle.primary,
                    ),
                  )
                : Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    color: themeStyle.primary,
                    size: 19,
                  ),
            tooltip: 'Sync Sheets',
          ),
          const SizedBox(width: 6),
          // MENU KILAT Popup Menu
          PopupMenuButton<String>(
            tooltip: 'MENU KILAT',
            color: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.borderDark),
            ),
            onSelected: (choice) {
              switch (choice) {
                case 'DASHBOARD':
                  state.setTabIndex(2);
                  break;
                case 'ANALYTIC':
                  state.openDrawerPage('ANALYTIC');
                  break;
                case 'MEETING':
                  state.setTabIndex(0);
                  break;
                case 'CONTENT':
                  state.setTabIndex(3);
                  break;
                case 'PUBLISH':
                  state.setTabIndex(4);
                  break;
                case 'SETTING':
                  state.openDrawerPage('SETTING');
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem<String>(
                enabled: false,
                height: 30,
                child: Text(
                  '⚡ MENU KILAT',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              _buildQuickMenuItem(
                'DASHBOARD',
                'Dashboard Utama',
                CupertinoIcons.chart_bar_alt_fill,
                AppColors.accent,
              ),
              _buildQuickMenuItem(
                'ANALYTIC',
                'Analytic',
                CupertinoIcons.graph_circle_fill,
                AppColors.info,
              ),
              _buildQuickMenuItem(
                'MEETING',
                'Weekly Meeting',
                CupertinoIcons.person_3_fill,
                AppColors.glowBlue,
              ),
              _buildQuickMenuItem(
                'CONTENT',
                'Content',
                CupertinoIcons.paintbrush_fill,
                AppColors.glowPurple,
              ),
              _buildQuickMenuItem(
                'PUBLISH',
                'Publish',
                CupertinoIcons.paperplane_fill,
                AppColors.igPink,
              ),
              const PopupMenuDivider(),
              _buildQuickMenuItem(
                'SETTING',
                'Setting',
                CupertinoIcons.gear_alt_fill,
                Colors.white70,
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: themeStyle.card,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.bolt_fill,
                    color: AppColors.accent,
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'MENU KILAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildQuickMenuItem(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthAndViewControls(
    BuildContext context,
    AppStateProvider state,
    AppThemeStyle themeStyle,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // Month Switcher < Bulan >
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: themeStyle.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _cycleMonth(state, -1),
                      icon: const Icon(
                        CupertinoIcons.chevron_left,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                    ),
                    Expanded(
                      child: PopupMenuButton<String>(
                        color: AppColors.cardDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.borderDark),
                        ),
                        onSelected: state.setSelectedMonth,
                        itemBuilder: (_) => AppStateProvider.availableMonths
                            .map(
                              (m) => PopupMenuItem<String>(
                                value: m,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    color: m == state.selectedMonth
                                        ? themeStyle.primary
                                        : Colors.white,
                                    fontWeight: m == state.selectedMonth
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.calendar,
                              color: AppColors.accent,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                state.selectedMonth,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _cycleMonth(state, 1),
                      icon: const Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // "Tambah" Button opening AddScheduleDialog.show(context)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => AddScheduleDialog.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeStyle.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(CupertinoIcons.add_circled_solid, size: 18),
                label: const Text(
                  'Tambah',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Daftar vs Kalender View Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeStyle.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildViewToggleButton(
                  label: 'Daftar Jadwal',
                  icon: CupertinoIcons.square_grid_2x2_fill,
                  isSelected: !_isCalendarView,
                  themeStyle: themeStyle,
                  onTap: () => setState(() {
                    _isCalendarView = false;
                    _selectedCalendarDay = null;
                  }),
                ),
              ),
              Expanded(
                child: _buildViewToggleButton(
                  label: 'Kalender',
                  icon: CupertinoIcons.calendar_today,
                  isSelected: _isCalendarView,
                  themeStyle: themeStyle,
                  onTap: () => setState(() => _isCalendarView = true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required AppThemeStyle themeStyle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeStyle.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.black : AppColors.textSecondaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondaryDark,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterPanel(
    BuildContext context,
    AppStateProvider state,
    AppThemeStyle themeStyle,
  ) {
    final hasActiveSubFilters = state.staffFilter != 'Semua' ||
        state.filterStartDate != null ||
        state.filterEndDate != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: state.setSearchQuery,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Cari ID Listing, Nama ME, Lokasi, Staff...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12.5,
                  ),
                  prefixIcon: const Icon(
                    CupertinoIcons.search,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            state.setSearchQuery('');
                          },
                          icon: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Colors.white38,
                            size: 17,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: themeStyle.card,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: themeStyle.primary,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Collapsible "Saring" Button
            InkWell(
              onTap: () =>
                  setState(() => _isFilterExpanded = !_isFilterExpanded),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: _isFilterExpanded || hasActiveSubFilters
                      ? themeStyle.primary.withValues(alpha: 0.2)
                      : themeStyle.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isFilterExpanded || hasActiveSubFilters
                        ? themeStyle.primary
                        : AppColors.borderDark,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: _isFilterExpanded || hasActiveSubFilters
                          ? themeStyle.primary
                          : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Saring',
                      style: TextStyle(
                        color: _isFilterExpanded || hasActiveSubFilters
                            ? themeStyle.primary
                            : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Collapsible Filter Content
        if (_isFilterExpanded) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: themeStyle.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Staff & Rentang Tanggal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hasActiveSubFilters)
                      TextButton.icon(
                        onPressed: () {
                          state.setStaffFilter('Semua');
                          state.setDateRangeFilter(null, null);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          CupertinoIcons.arrow_counterclockwise,
                          size: 13,
                        ),
                        label: const Text(
                          'Reset Filter',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Staff Chips: Semua, David, Alan
                Row(
                  children: ['Semua', 'David', 'Alan'].map((staff) {
                    final selected = state.staffFilter == staff;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: staff != 'Alan' ? 8 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () => state.setStaffFilter(staff),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? themeStyle.primary
                                  : themeStyle.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? themeStyle.primary
                                    : AppColors.borderDark,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                staff == 'Semua'
                                    ? 'Semua Staff'
                                    : 'Staff $staff',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.black
                                      : AppColors.textSecondaryDark,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Date Range Pickers: Dari Tanggal - Sampai Tanggal
                Row(
                  children: [
                    Expanded(
                      child: _buildDateRangeButton(
                        label: 'Dari Tanggal',
                        date: state.filterStartDate,
                        onTap: () =>
                            _pickDateRange(context, state, isStart: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateRangeButton(
                        label: 'Sampai Tanggal',
                        date: state.filterEndDate,
                        onTap: () =>
                            _pickDateRange(context, state, isStart: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateRangeButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final text = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : 'Pilih Tanggal';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null ? AppColors.accent : AppColors.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  size: 13,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.white38,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCalendarPanel(
    AppStateProvider state,
    AppThemeStyle themeStyle,
  ) {
    final monthDate = _resolveMonthYear(state.selectedMonth);
    final daysInMonth =
        DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final leadingEmpty = firstDay.weekday - 1;

    final Map<int, List<Schedule>> mapByDay = {};
    for (final s in state.schedules) {
      final dt = parseIndonesianDate(s.tanggal);
      if (dt != null &&
          dt.year == monthDate.year &&
          dt.month == monthDate.month) {
        mapByDay.putIfAbsent(dt.day, () => []).add(s);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kalender ${state.selectedMonth}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_selectedCalendarDay != null)
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedCalendarDay = null),
                  style: TextButton.styleFrom(
                    foregroundColor: themeStyle.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Tampilkan Semua Hari',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();
              final day = index - leadingEmpty + 1;
              final cellDate = DateTime(monthDate.year, monthDate.month, day);
              final list = mapByDay[day] ?? const [];
              final selected = _selectedCalendarDay != null &&
                  _isSameDay(_selectedCalendarDay!, cellDate);

              Color? dotColor;
              if (list.isNotEmpty) {
                if (list.every((s) => s.isDone)) {
                  dotColor = AppColors.success;
                } else if (list.any((s) => s.isActive)) {
                  dotColor = AppColors.warning;
                } else {
                  dotColor = AppColors.error;
                }
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCalendarDay = null;
                    } else {
                      _selectedCalendarDay = cellDate;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? themeStyle.primary
                        : (list.isNotEmpty
                            ? themeStyle.surface
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected
                          ? themeStyle.primary
                          : (list.isNotEmpty
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
                          color: selected
                              ? Colors.black
                              : (list.isNotEmpty
                                  ? Colors.white
                                  : Colors.white54),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (dotColor != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: selected ? Colors.black : dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStateProvider state, AppThemeStyle themeStyle) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.camera_on_rectangle,
            color: Colors.white30,
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text(
            'Tidak Ada Jadwal Ditemukan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada jadwal foto yang cocok dengan filter "${state.mediaFilter}" pada ${state.selectedMonth}.',
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPACT STAT CARD
// =============================================================================
class CompactStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CompactStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDark,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 15),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondaryDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2-COLUMN MEDIA SCHEDULE CARD
// =============================================================================
class MediaScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final String? imageUrl;
  final String? price;
  final AppThemeStyle themeStyle;
  final VoidCallback onTapCard;
  final VoidCallback onEdit;
  final VoidCallback onFollowUpWa;
  final VoidCallback onDelete;

  const MediaScheduleCard({
    super.key,
    required this.schedule,
    required this.imageUrl,
    required this.price,
    required this.themeStyle,
    required this.onTapCard,
    required this.onEdit,
    required this.onFollowUpWa,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = schedule.isDone;
    final isNonActive = schedule.isNonActive;

    final statusLabel =
        isDone ? 'DONE' : (isNonActive ? 'PENDING' : 'AKTIF');
    final statusColor = isDone
        ? AppColors.success
        : (isNonActive ? AppColors.error : AppColors.warning);

    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: themeStyle.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Thumbnail Banner with #cleanId + Status Badge
            SizedBox(
              height: 88,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceDark,
                        child: const Center(
                          child: CupertinoActivityIndicator(radius: 9),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _buildFallbackBanner(),
                    )
                  else
                    _buildFallbackBanner(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Top Row: #cleanId + Status Badge
                  Positioned(
                    top: 7,
                    left: 7,
                    right: 7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.rwcYellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${schedule.cleanId.isNotEmpty ? schedule.cleanId : "-"}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom Row: Time & Type Pill
                  Positioned(
                    bottom: 6,
                    left: 7,
                    right: 7,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.clock_fill,
                          size: 11,
                          color: AppColors.accentLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.formattedTime12Hour,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              schedule.type,
                              style: const TextStyle(
                                color: AppColors.accentLight,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Details Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama ME
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.person_fill,
                          size: 12,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Tanggal
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          size: 11.5,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.tanggal.isNotEmpty
                                ? schedule.tanggal
                                : 'Belum dijadwalkan',
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Lokasi
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 11.5,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.lokasi.isNotEmpty
                                ? schedule.lokasi
                                : 'Lokasi belum diisi',
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Staff
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.camera_fill,
                          size: 11,
                          color: AppColors.glowBlue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.staff.isNotEmpty
                                ? 'Staff: ${schedule.staff}'
                                : 'Staff: -',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    const Divider(
                      color: AppColors.borderDark,
                      height: 10,
                      thickness: 0.8,
                    ),

                    // Quick Action Row: Edit (0), WA Follow Up (2), Delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickActionIcon(
                          icon: CupertinoIcons.pencil,
                          label: 'Edit',
                          color: AppColors.info,
                          onTap: onEdit,
                        ),
                        _buildQuickActionIcon(
                          icon: CupertinoIcons.chat_bubble_text_fill,
                          label: 'WA',
                          color: const Color(0xFF25D366),
                          onTap: onFollowUpWa,
                        ),
                        _buildQuickActionIcon(
                          icon: CupertinoIcons.trash,
                          label: 'Hapus',
                          color: AppColors.error,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          CupertinoIcons.photo_on_rectangle,
          color: Colors.white24,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildQuickActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MONTHLY ANALYSIS CARD WITH DONUT CHART
// =============================================================================
class MonthlyAnalysisCard extends StatelessWidget {
  final String monthLabel;
  final int doneCount;
  final int activeCount;
  final int nonActiveCount;
  final AppThemeStyle themeStyle;

  const MonthlyAnalysisCard({
    super.key,
    required this.monthLabel,
    required this.doneCount,
    required this.activeCount,
    required this.nonActiveCount,
    required this.themeStyle,
  });

  @override
  Widget build(BuildContext context) {
    final total = doneCount + activeCount + nonActiveCount;
    final donePercent = total > 0 ? ((doneCount / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: themeStyle.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_pie_fill,
                color: themeStyle.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analisis Bulanan • $monthLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$donePercent% Selesai',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _ScheduleDonutChartPainter(
                    done: doneCount,
                    active: activeCount,
                    nonActive: nonActiveCount,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Jadwal',
                          style: TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
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
                    _buildBreakdownRow(
                      label: 'Selesai (Done)',
                      count: doneCount,
                      total: total,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 10),
                    _buildBreakdownRow(
                      label: 'Aktif (On Progress)',
                      count: activeCount,
                      total: total,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 10),
                    _buildBreakdownRow(
                      label: 'Non-Aktif / Pending',
                      count: nonActiveCount,
                      total: total,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ScheduleDonutChartPainter extends CustomPainter {
  final int done;
  final int active;
  final int nonActive;

  _ScheduleDonutChartPainter({
    required this.done,
    required this.active,
    required this.nonActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 8;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final total = done + active + nonActive;
    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    final segments = [
      (done, AppColors.success),
      (active, AppColors.warning),
      (nonActive, AppColors.error),
    ];

    for (final seg in segments) {
      if (seg.$1 <= 0) continue;
      final sweepAngle = (seg.$1 / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ScheduleDonutChartPainter oldDelegate) {
    return oldDelegate.done != done ||
        oldDelegate.active != active ||
        oldDelegate.nonActive != nonActive;
  }
}
