import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/agent_contact.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/state/app_state_provider.dart';
import '../../publish/models/publish_item.dart';
import '../../weekly_meeting/models/meeting_listing.dart';
import '../models/edit_foto_task.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  static const List<String> _taskFilters = [
    'Semua',
    'Up Foto',
    'Edit Video',
    'Garis Tanah',
    'Pending',
    'Selesai',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTaskFilter = 'Semua';

  // For Sub-tab 1 (Edit Foto Meeting): 0 = Belum Diedit (!l.meHighlighted), 1 = Sudah Diedit (l.meHighlighted)
  int _meetingEditSegment = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEditTaskModal(
    BuildContext context,
    AppStateProvider state,
    EditFotoTask task,
  ) async {
    final notesController = TextEditingController(text: task.editNotes);
    final scheduleController = TextEditingController(text: task.jadwalPosting);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.borderDark, width: 1.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${task.cleanId}',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Edit Catatan & Jadwal (${task.namaMe})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jadwal Posting IG:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: scheduleController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Contoh: 18 Juni 2026',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondaryDark,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.calendar,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: AppColors.cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.borderDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.cardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.borderDark),
                            ),
                          ),
                          onPressed: () async {
                            final initial =
                                parseIndonesianDate(scheduleController.text) ??
                                    DateTime.now();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: initial,
                              firstDate: DateTime(2025, 1, 1),
                              lastDate: DateTime(2027, 12, 31),
                            );
                            if (picked != null) {
                              setModalState(() {
                                scheduleController.text =
                                    '${picked.day.toString().padLeft(2, '0')} ${kIndonesianMonths[picked.month - 1]} ${picked.year}';
                              });
                            }
                          },
                          icon: const Icon(
                            CupertinoIcons.calendar_badge_plus,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Catatan Edit Foto / Video:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Masukkan catatan edit foto/video...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondaryDark,
                        ),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final newNotes = notesController.text.trim();
                          final newDate = scheduleController.text.trim();
                          if (newNotes != task.editNotes) {
                            await state.updateEditNotes(task, newNotes);
                          }
                          if (newDate != task.jadwalPosting) {
                            await state.updateEditFotoScheduleDate(task, newDate);
                          }
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                        icon: const Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          size: 18,
                        ),
                        label: const Text(
                          'Simpan Perubahan Task',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeSubTab = state.selectedTaskSubTab;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top 2 Sub-tabs bound to state.selectedTaskSubTab
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => state.setSelectedTaskSubTab(0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: activeSubTab == 0
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.layers_alt_fill,
                                size: 16,
                                color: activeSubTab == 0
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Content Task',
                                style: TextStyle(
                                  color: activeSubTab == 0
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => state.setSelectedTaskSubTab(1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: activeSubTab == 1
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.wand_stars,
                                size: 16,
                                color: activeSubTab == 1
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Edit Foto Meeting',
                                style: TextStyle(
                                  color: activeSubTab == 1
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: activeSubTab == 0
                      ? 'Cari ID Listing, Judul, ME, atau Catatan Edit...'
                      : 'Cari listing IG Meeting yang perlu diedit...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12.5,
                  ),
                  prefixIcon: const Icon(
                    CupertinoIcons.search,
                    color: AppColors.textSecondaryDark,
                    size: 18,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: Colors.white54,
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardDark,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderDark),
                  ),
                ),
              ),
            ),

            // Body for Sub-tab 0 vs Sub-tab 1
            Expanded(
              child: activeSubTab == 0
                  ? _buildContentTaskSubTab(context, state)
                  : _buildEditFotoMeetingSubTab(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTaskSubTab(BuildContext context, AppStateProvider state) {
    final filteredTasks = state.editFotoTasks.where((t) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.idListing.toLowerCase().contains(q) ||
          t.namaMe.toLowerCase().contains(q) ||
          t.judul.toLowerCase().contains(q) ||
          t.editNotes.toLowerCase().contains(q);

      final matchesFilter = switch (_selectedTaskFilter) {
        'Up Foto' => t.isUpFoto,
        'Edit Video' => t.isEditVideo,
        'Garis Tanah' => t.isGarisTanah,
        'Pending' => !t.done,
        'Selesai' => t.done,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        // Filter Chips ('Semua', 'Up Foto', 'Edit Video', 'Garis Tanah', 'Pending', 'Selesai')
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _taskFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final f = _taskFilters[index];
              final selected = _selectedTaskFilter == f;
              return ChoiceChip(
                label: Text(
                  f,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.cardDark,
                side: BorderSide(
                  color: selected ? AppColors.accent : AppColors.borderDark,
                ),
                onSelected: (_) => setState(() => _selectedTaskFilter = f),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // 2-Column Grid of EditFotoTask Cards
        Expanded(
          child: filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Colors.white.withOpacity(0.24),
                        size: 52,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tidak ada Content Task yang sesuai filter.',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    final detail = state.getListingDetail(task.idListing);
                    return _EditFotoTaskCard(
                      task: task,
                      detail: detail,
                      onTapCard: () => _showEditTaskModal(context, state, task),
                      onToggleDone: () => state.toggleEditFotoDone(task),
                      onTogglePostingIg: () =>
                          state.toggleEditFotoPostingIg(task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEditFotoMeetingSubTab(
    BuildContext context,
    AppStateProvider state,
  ) {
    final allIgMeetings = state.meetingListings.where((l) {
      if (!l.keterangan.toUpperCase().contains('IG')) return false;
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return l.idListing.toLowerCase().contains(q) ||
          l.namaMe.toLowerCase().contains(q) ||
          l.lokasi.toLowerCase().contains(q) ||
          l.catatan.toLowerCase().contains(q);
    }).toList();

    final belumEdited = allIgMeetings.where((l) => !l.meHighlighted).toList();
    final sudahEdited = allIgMeetings.where((l) => l.meHighlighted).toList();
    final activeList = _meetingEditSegment == 0 ? belumEdited : sudahEdited;

    // Sort chronologically by jadwalPosting
    activeList.sort((a, b) {
      final cmp = parseIndonesianDateToComparable(a.jadwalPosting)
          .compareTo(parseIndonesianDateToComparable(b.jadwalPosting));
      if (cmp != 0) return cmp;
      return a.row.compareTo(b.row);
    });

    // Group by formatIndonesianDateHeader(jadwalPosting)
    final grouped = <String, List<MeetingListing>>{};
    for (final item in activeList) {
      final header = formatIndonesianDateHeader(item.jadwalPosting);
      grouped.putIfAbsent(header, () => []).add(item);
    }

    return Column(
      children: [
        // Toggle: Belum Diedit vs Sudah Diedit
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: _meetingEditSegment == 0,
                  selectedColor: AppColors.warning.withOpacity(0.25),
                  backgroundColor: AppColors.cardDark,
                  side: BorderSide(
                    color: _meetingEditSegment == 0
                        ? AppColors.warning
                        : AppColors.borderDark,
                  ),
                  label: Center(
                    child: Text(
                      'Belum Diedit (${belumEdited.length})',
                      style: TextStyle(
                        color: _meetingEditSegment == 0
                            ? AppColors.warning
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (_) => setState(() => _meetingEditSegment = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  selected: _meetingEditSegment == 1,
                  selectedColor: AppColors.success.withOpacity(0.25),
                  backgroundColor: AppColors.cardDark,
                  side: BorderSide(
                    color: _meetingEditSegment == 1
                        ? AppColors.success
                        : AppColors.borderDark,
                  ),
                  label: Center(
                    child: Text(
                      'Sudah Diedit (${sudahEdited.length})',
                      style: TextStyle(
                        color: _meetingEditSegment == 1
                            ? AppColors.success
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (_) => setState(() => _meetingEditSegment = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: grouped.isEmpty
              ? Center(
                  child: Text(
                    _meetingEditSegment == 0
                        ? 'Semua listing IG Meeting sudah selesai diedit!'
                        : 'Belum ada listing IG Meeting yang ditandai selesai edit.',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  itemCount: grouped.entries.length,
                  itemBuilder: (context, sectionIndex) {
                    final entry = grouped.entries.elementAt(sectionIndex);
                    final dateHeader = entry.key;
                    final items = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryLight.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.calendar,
                                color: AppColors.primaryLight,
                                size: 15,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateHeader,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              Text(
                                '${items.length} Listing',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final detail = state.getListingDetail(item.idListing);
                            final extractedJudul =
                                extractJudulFromNotes(item.catatan) ??
                                    (item.judul.isNotEmpty
                                        ? item.judul
                                        : (detail?.title ?? ''));

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.meHighlighted
                                      ? AppColors.success.withOpacity(0.7)
                                      : AppColors.borderDark,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 104,
                                    width: double.infinity,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (detail?.primaryImageUrl != null &&
                                            detail!.primaryImageUrl!.isNotEmpty)
                                          CachedNetworkImage(
                                            imageUrl: detail.primaryImageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        else
                                          Container(
                                            color: AppColors.surfaceDark,
                                            child: const Icon(
                                              CupertinoIcons.photo,
                                              color: Colors.white24,
                                            ),
                                          ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#${item.cleanId}',
                                              style: const TextStyle(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.namaMe,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          if (extractedJudul.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              extractedJudul,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              item.catatan.isNotEmpty
                                                  ? item.catatan
                                                  : 'Tidak ada catatan edit',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    item.meHighlighted
                                                        ? AppColors.surfaceDark
                                                        : AppColors.success,
                                                foregroundColor:
                                                    item.meHighlighted
                                                        ? AppColors.success
                                                        : Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 7,
                                                ),
                                                side: BorderSide(
                                                  color: AppColors.success
                                                      .withOpacity(0.6),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () => state
                                                  .toggleMeetingMeHighlight(item),
                                              icon: Icon(
                                                item.meHighlighted
                                                    ? CupertinoIcons
                                                        .checkmark_seal_fill
                                                    : CupertinoIcons.wand_stars,
                                                size: 14,
                                              ),
                                              label: Text(
                                                item.meHighlighted
                                                    ? 'Sudah Diedit'
                                                    : 'Tandai Sudah Edit',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EditFotoTaskCard extends StatelessWidget {
  final EditFotoTask task;
  final ScrapedListingDetail? detail;
  final VoidCallback onTapCard;
  final VoidCallback onToggleDone;
  final VoidCallback onTogglePostingIg;

  const _EditFotoTaskCard({
    required this.task,
    required this.detail,
    required this.onTapCard,
    required this.onToggleDone,
    required this.onTogglePostingIg,
  });

  String get _categoryLabel {
    if (task.isEditVideo) return 'EDIT VIDEO';
    if (task.isGarisTanah) return 'GARIS TANAH';
    return 'UP FOTO';
  }

  Color get _categoryColor {
    if (task.isEditVideo) return AppColors.igPink;
    if (task.isGarisTanah) return AppColors.info;
    return AppColors.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = detail?.primaryImageUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.done
                ? AppColors.success.withOpacity(0.75)
                : AppColors.borderDark,
            width: task.done ? 1.4 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scraped Photo Header
            SizedBox(
              height: 106,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imgUrl != null && imgUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: Colors.white24,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceDark,
                      child: const Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Colors.white24,
                        size: 30,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${task.cleanId}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _categoryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _categoryLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (task.jadwalPosting.trim().isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.calendar,
                            color: AppColors.accent,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.jadwalPosting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Card Details & Controls
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.judul.isNotEmpty
                          ? task.judul
                          : (detail?.title.isNotEmpty == true
                              ? detail!.title
                              : 'Listing #${task.cleanId}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.namaMe.isNotEmpty ? task.namaMe : 'Ray White Cipete',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        task.editNotes.isNotEmpty
                            ? task.editNotes
                            : 'Ketuk kartu untuk menambah catatan edit...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.borderDark, height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Done Checkbox
                        InkWell(
                          onTap: onToggleDone,
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.done
                                    ? CupertinoIcons.checkmark_square_fill
                                    : CupertinoIcons.square,
                                color: task.done
                                    ? AppColors.success
                                    : Colors.white54,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  color: task.done
                                      ? AppColors.success
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Posting IG Switch
                        InkWell(
                          onTap: onTogglePostingIg,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: task.postingIg
                                  ? AppColors.igPink.withOpacity(0.2)
                                  : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: task.postingIg
                                    ? AppColors.igPink
                                    : AppColors.borderDark,
                              ),
                            ),
                            child: Text(
                              task.postingIg ? 'IG: ON' : 'IG: OFF',
                              style: TextStyle(
                                color: task.postingIg
                                    ? AppColors.igPink
                                    : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
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
}
