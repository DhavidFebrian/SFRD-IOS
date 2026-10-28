import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/utils/whatsapp_formatter.dart';
import '../../marketing/screens/instagram_mockup_screen.dart';
import '../models/publish_item.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sub-tab 0 (Feeds): false = Unpublished, true = Published
  bool _feedsShowPublished = false;

  // Sub-tab 1 (Reels): false = Unpublished, true = Published
  bool _reelsShowPublished = false;

  // Sub-tab 2 (Scheduling): false = Unscheduled, true = Scheduled
  bool _schedulingShowScheduled = false;

  // Collapsible section states in Scheduling tab
  bool _expandTurunHarga = true;
  bool _expandJaksel = true;
  bool _expandLainnya = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpdateFeedSchedule(
    BuildContext context,
    AppStateProvider state,
    PublishFeedItem item,
  ) async {
    final initial = parseIndonesianDate(item.jadwalPosting) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked == null) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')} ${kIndonesianMonths[picked.month - 1]} ${picked.year}';

    if (item.isFromMeeting && item.sourceMeeting != null) {
      await state.updateMeetingScheduleDate(item.sourceMeeting!, formatted);
    } else if (item.sourceTask != null) {
      await state.updateEditFotoScheduleDate(item.sourceTask!, formatted);
    }
  }

  Future<void> _toggleFeedPosted(
    AppStateProvider state,
    PublishFeedItem item,
  ) async {
    if (item.isFromMeeting && item.sourceMeeting != null) {
      await state.toggleMeetingListingPostingIg(item.sourceMeeting!);
    } else if (item.sourceTask != null) {
      await state.toggleEditFotoPostingIg(item.sourceTask!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeSubTab = state.selectedPublishSubTab;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top 3 Sub-tabs bound to state.selectedPublishSubTab
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
                    _PublishSubTabChip(
                      label: 'Feeds',
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      selected: activeSubTab == 0,
                      onTap: () => state.setSelectedPublishSubTab(0),
                    ),
                    _PublishSubTabChip(
                      label: 'Reels',
                      icon: CupertinoIcons.film_fill,
                      selected: activeSubTab == 1,
                      onTap: () => state.setSelectedPublishSubTab(1),
                    ),
                    _PublishSubTabChip(
                      label: 'Scheduling',
                      icon: CupertinoIcons.calendar_badge_plus,
                      selected: activeSubTab == 2,
                      onTap: () => state.setSelectedPublishSubTab(2),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: activeSubTab == 1
                      ? 'Cari ID Listing Reels, Lokasi, atau Nama ME...'
                      : 'Cari ID Listing, Nama ME, Judul, atau Lokasi...',
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

            Expanded(
              child: switch (activeSubTab) {
                0 => _buildFeedsSubTab(context, state),
                1 => _buildReelsSubTab(context, state),
                _ => _buildSchedulingSubTab(context, state),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SUB-TAB 0: FEEDS
  // ===========================================================================
  Widget _buildFeedsSubTab(BuildContext context, AppStateProvider state) {
    final monthOptions = ['Semua Bulan', ...AppStateProvider.regularMonths];
    final allFeeds = state.allPublishFeedItems.where((item) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return item.idListing.toLowerCase().contains(q) ||
          item.namaMe.toLowerCase().contains(q) ||
          item.judul.toLowerCase().contains(q) ||
          item.lokasi.toLowerCase().contains(q) ||
          item.catatan.toLowerCase().contains(q);
    }).toList();

    final unpublishedList = allFeeds.where((i) => !i.postingIg).toList();
    final publishedList = allFeeds.where((i) => i.postingIg).toList();
    final activeList = _feedsShowPublished ? publishedList : unpublishedList;

    // Sort chronologically by jadwalPosting
    activeList.sort((a, b) {
      final cmp = parseIndonesianDateToComparable(a.jadwalPosting)
          .compareTo(parseIndonesianDateToComparable(b.jadwalPosting));
      if (cmp != 0) return cmp;
      return a.cleanId.compareTo(b.cleanId);
    });

    // Group Unpublished by jadwalPosting banner
    final groupedUnpublished = <String, List<PublishFeedItem>>{};
    if (!_feedsShowPublished) {
      for (final item in activeList) {
        final banner = formatIndonesianDateHeader(item.jadwalPosting);
        groupedUnpublished.putIfAbsent(banner, () => []).add(item);
      }
    }

    return Column(
      children: [
        // Month Selector + Unpublished / Published Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            children: [
              // Month Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: monthOptions.contains(state.publishSelectedMonth)
                        ? state.publishSelectedMonth
                        : 'Semua Bulan',
                    dropdownColor: AppColors.cardDark,
                    icon: const Icon(
                      CupertinoIcons.chevron_down,
                      color: AppColors.accent,
                      size: 14,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    items: monthOptions
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        state.setPublishSelectedMonth(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Unpublished (N) vs Published (N)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        selected: !_feedsShowPublished,
                        selectedColor: AppColors.warning.withOpacity(0.24),
                        backgroundColor: AppColors.cardDark,
                        side: BorderSide(
                          color: !_feedsShowPublished
                              ? AppColors.warning
                              : AppColors.borderDark,
                        ),
                        label: Center(
                          child: Text(
                            'Unpublished (${unpublishedList.length})',
                            style: TextStyle(
                              color: !_feedsShowPublished
                                  ? AppColors.warning
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        onSelected: (_) =>
                            setState(() => _feedsShowPublished = false),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        selected: _feedsShowPublished,
                        selectedColor: AppColors.success.withOpacity(0.24),
                        backgroundColor: AppColors.cardDark,
                        side: BorderSide(
                          color: _feedsShowPublished
                              ? AppColors.success
                              : AppColors.borderDark,
                        ),
                        label: Center(
                          child: Text(
                            'Published (${publishedList.length})',
                            style: TextStyle(
                              color: _feedsShowPublished
                                  ? AppColors.success
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        onSelected: (_) =>
                            setState(() => _feedsShowPublished = true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: activeList.isEmpty
              ? Center(
                  child: Text(
                    _feedsShowPublished
                        ? 'Belum ada Feeds yang ditandai Published.'
                        : 'Tidak ada antrean Feeds Unpublished.',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                )
              : _feedsShowPublished
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.54,
                      ),
                      itemCount: activeList.length,
                      itemBuilder: (context, index) {
                        final item = activeList[index];
                        final detail = state.getListingDetail(item.idListing);
                        return TaskUploadIgCard(
                          item: item,
                          detail: detail,
                          onTapCard: () => InstagramPostMockupScreen.show(
                            context,
                            idListing: item.idListing,
                            namaMe: item.namaMe,
                            customHeadline: item.judul,
                            lokasi: item.lokasi,
                            isEdited: item.isEdited,
                          ),
                          onEditSchedule: () => _pickAndUpdateFeedSchedule(
                            context,
                            state,
                            item,
                          ),
                          onTogglePosted: () => _toggleFeedPosted(state, item),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: groupedUnpublished.entries.length,
                      itemBuilder: (context, sectionIndex) {
                        final entry =
                            groupedUnpublished.entries.elementAt(sectionIndex);
                        final banner = entry.key;
                        final sectionItems = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.igPink.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.igPink.withOpacity(0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.calendar_today,
                                    color: AppColors.igPink,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      banner,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${sectionItems.length} Konten',
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
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.54,
                              ),
                              itemCount: sectionItems.length,
                              itemBuilder: (context, idx) {
                                final item = sectionItems[idx];
                                final detail =
                                    state.getListingDetail(item.idListing);
                                return TaskUploadIgCard(
                                  item: item,
                                  detail: detail,
                                  onTapCard: () =>
                                      InstagramPostMockupScreen.show(
                                    context,
                                    idListing: item.idListing,
                                    namaMe: item.namaMe,
                                    customHeadline: item.judul,
                                    lokasi: item.lokasi,
                                    isEdited: item.isEdited,
                                  ),
                                  onEditSchedule: () =>
                                      _pickAndUpdateFeedSchedule(
                                    context,
                                    state,
                                    item,
                                  ),
                                  onTogglePosted: () =>
                                      _toggleFeedPosted(state, item),
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

  // ===========================================================================
  // SUB-TAB 1: REELS
  // ===========================================================================
  Widget _buildReelsSubTab(BuildContext context, AppStateProvider state) {
    final allReels = state.reelItems.where((r) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.idListing.toLowerCase().contains(q) ||
          r.lokasi.toLowerCase().contains(q) ||
          r.marketing.toLowerCase().contains(q) ||
          r.spesifikasi.toLowerCase().contains(q);
    }).toList();

    final unpublishedReels = allReels.where((r) => !r.isPosted).toList();
    final publishedReels = allReels.where((r) => r.isPosted).toList();
    final activeReels =
        _reelsShowPublished ? publishedReels : unpublishedReels;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: !_reelsShowPublished,
                  selectedColor: AppColors.igPink.withOpacity(0.24),
                  backgroundColor: AppColors.cardDark,
                  side: BorderSide(
                    color: !_reelsShowPublished
                        ? AppColors.igPink
                        : AppColors.borderDark,
                  ),
                  label: Center(
                    child: Text(
                      'Unpublished (${unpublishedReels.length})',
                      style: TextStyle(
                        color: !_reelsShowPublished
                            ? AppColors.igPink
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (_) =>
                      setState(() => _reelsShowPublished = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  selected: _reelsShowPublished,
                  selectedColor: AppColors.success.withOpacity(0.24),
                  backgroundColor: AppColors.cardDark,
                  side: BorderSide(
                    color: _reelsShowPublished
                        ? AppColors.success
                        : AppColors.borderDark,
                  ),
                  label: Center(
                    child: Text(
                      'Published (${publishedReels.length})',
                      style: TextStyle(
                        color: _reelsShowPublished
                            ? AppColors.success
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (_) => setState(() => _reelsShowPublished = true),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: activeReels.isEmpty
              ? Center(
                  child: Text(
                    _reelsShowPublished
                        ? 'Belum ada Reels yang ditandai Published.'
                        : 'Tidak ada antrean Reels Unpublished.',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: activeReels.length,
                  itemBuilder: (context, index) {
                    final reel = activeReels[index];
                    final detail = state.getListingDetail(reel.idListing);
                    return ReelCard(
                      reel: reel,
                      detail: detail,
                      onTogglePosted: () => state.toggleReelPosted(reel),
                      onTapCard: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => ReelPreviewDialog(
                            reel: reel,
                            detail: detail,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SUB-TAB 2: SCHEDULING
  // ===========================================================================
  Widget _buildSchedulingSubTab(BuildContext context, AppStateProvider state) {
    final allItems = state.allPublishFeedItems.where((item) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return item.idListing.toLowerCase().contains(q) ||
          item.namaMe.toLowerCase().contains(q) ||
          item.judul.toLowerCase().contains(q) ||
          item.lokasi.toLowerCase().contains(q);
    }).toList();

    final unscheduled = allItems.where((i) => !i.isScheduled).toList();
    final scheduled = allItems.where((i) => i.isScheduled).toList();

    // 3 Collapsible Categories for Unscheduled matching Android:
    // 1. Turun Harga (item.isTurunHarga)
    // 2. Trade Area Jakarta Selatan (!item.isTurunHarga && item.isJaksel)
    // 3. IG Lainnya (all remaining)
    final turunHargaList =
        unscheduled.where((i) => i.isTurunHarga).toList();
    final jakselList = unscheduled
        .where((i) => !i.isTurunHarga && i.isJaksel)
        .toList();
    final lainnyaList = unscheduled
        .where((i) => !i.isTurunHarga && !i.isJaksel)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: !_schedulingShowScheduled,
                  selectedColor: AppColors.warning.withOpacity(0.24),
                  backgroundColor: AppColors.cardDark,
                  side: BorderSide(
                    color: !_schedulingShowScheduled
                        ? AppColors.warning
                        : AppColors.borderDark,
                  ),
                  label: Center(
                    child: Text(
                      'Unscheduled (${unscheduled.length})',
                      style: TextStyle(
                        color: !_schedulingShowScheduled
                            ? AppColors.warning
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (_) =>
                      setState(() => _schedulingShowScheduled = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  selected: _schedulingShowScheduled,
                  selectedColor: AppColors.success.withOpacity(0.24),
                  backgroundColor: AppColors.cardDark,
                  side: BorderSide(
                    color: _schedulingShowScheduled
                        ? AppColors.success
                        : AppColors.borderDark,
                  ),
                  label: Center(
                    child: Text(
                      'Scheduled (${scheduled.length})',
                      style: TextStyle(
                        color: _schedulingShowScheduled
                            ? AppColors.success
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (_) =>
                      setState(() => _schedulingShowScheduled = true),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _schedulingShowScheduled
              ? (scheduled.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada item IG yang memiliki tanggal jadwal posting.',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: scheduled.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = scheduled[index];
                        return _SchedulingItemTile(
                          item: item,
                          onPickDate: () =>
                              _pickAndUpdateFeedSchedule(context, state, item),
                        );
                      },
                    ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  children: [
                    _CollapsibleSchedulingSection(
                      title: 'Turun Harga',
                      subtitle: 'Prioritas Utama Konten Turun Harga',
                      color: AppColors.hotProperty,
                      icon: CupertinoIcons.tag_fill,
                      items: turunHargaList,
                      expanded: _expandTurunHarga,
                      onToggleExpand: () => setState(
                        () => _expandTurunHarga = !_expandTurunHarga,
                      ),
                      onPickDate: (item) =>
                          _pickAndUpdateFeedSchedule(context, state, item),
                    ),
                    const SizedBox(height: 12),
                    _CollapsibleSchedulingSection(
                      title: 'Trade Area Jakarta Selatan',
                      subtitle: 'Cipete, Cilandak, Kebayoran, Pondok Indah, Kemang',
                      color: AppColors.success,
                      icon: CupertinoIcons.map_pin_ellipse,
                      items: jakselList,
                      expanded: _expandJaksel,
                      onToggleExpand: () =>
                          setState(() => _expandJaksel = !_expandJaksel),
                      onPickDate: (item) =>
                          _pickAndUpdateFeedSchedule(context, state, item),
                    ),
                    const SizedBox(height: 12),
                    _CollapsibleSchedulingSection(
                      title: 'IG Lainnya',
                      subtitle: 'Listing IG Area Lain & Reguler',
                      color: AppColors.primaryLight,
                      icon: CupertinoIcons.square_stack_3d_up_fill,
                      items: lainnyaList,
                      expanded: _expandLainnya,
                      onToggleExpand: () =>
                          setState(() => _expandLainnya = !_expandLainnya),
                      onPickDate: (item) =>
                          _pickAndUpdateFeedSchedule(context, state, item),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PublishSubTabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PublishSubTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskUploadIgCard extends StatelessWidget {
  final PublishFeedItem item;
  final ScrapedListingDetail? detail;
  final VoidCallback onTapCard;
  final VoidCallback onEditSchedule;
  final VoidCallback onTogglePosted;

  const TaskUploadIgCard({
    super.key,
    required this.item,
    required this.detail,
    required this.onTapCard,
    required this.onEditSchedule,
    required this.onTogglePosted,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = detail?.primaryImageUrl;
    final headline = item.judul.isNotEmpty
        ? item.judul
        : (detail?.title.isNotEmpty == true
            ? detail!.title
            : 'Listing #${item.cleanId}');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !item.isEdited
                ? AppColors.error.withOpacity(0.65)
                : (item.postingIg
                    ? AppColors.success.withOpacity(0.75)
                    : AppColors.borderDark),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scraped Photo + Source Badge + Warning Badge if !item.isEdited
            SizedBox(
              height: 112,
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
                        CupertinoIcons.photo,
                        color: Colors.white24,
                        size: 32,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
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
                            '#${item.cleanId}',
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
                            color: item.isFromMeeting
                                ? AppColors.igPink
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.isFromMeeting ? 'Meeting' : 'Content',
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

                  // Red translucent "LISTING BELUM EDIT" warning badge if !item.isEdited
                  if (!item.isEdited)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: Colors.white,
                              size: 10,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'LISTING BELUM EDIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 8.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body Info & Action Buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaMe.isNotEmpty ? item.namaMe : 'Ray White Cipete',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.white54,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.lokasi.isNotEmpty ? item.lokasi : '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: AppColors.borderDark),
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: onEditSchedule,
                            child: const Text(
                              'Edit Jadwal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: item.postingIg
                                  ? AppColors.surfaceDark
                                  : AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: onTogglePosted,
                            child: Text(
                              item.postingIg ? 'Unpost' : 'Tandai Posted',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
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

class ReelCard extends StatelessWidget {
  final ReelItem reel;
  final ScrapedListingDetail? detail;
  final VoidCallback onTogglePosted;
  final VoidCallback onTapCard;

  const ReelCard({
    super.key,
    required this.reel,
    required this.detail,
    required this.onTogglePosted,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = reel.driveThumbnailUrl.isNotEmpty
        ? reel.driveThumbnailUrl
        : (detail?.primaryImageUrl ?? '');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: reel.isPosted
                ? AppColors.success.withOpacity(0.75)
                : AppColors.borderDark,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4:5 Aspect Ratio Thumbnail Header
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(
                          CupertinoIcons.film,
                          color: Colors.white24,
                          size: 36,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceDark,
                      child: const Icon(
                        CupertinoIcons.film,
                        color: Colors.white24,
                        size: 36,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Center(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black54,
                      child: Icon(
                        CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 20,
                      ),
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
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${reel.cleanId.isNotEmpty ? reel.cleanId : reel.no}',
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

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.lokasi.isNotEmpty ? reel.lokasi : 'Jakarta Selatan',
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
                    reel.marketing.isNotEmpty
                        ? reel.marketing
                        : 'Ray White Cipete',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: reel.isPosted
                            ? AppColors.surfaceDark
                            : AppColors.igPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onTogglePosted,
                      icon: Icon(
                        reel.isPosted
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.cloud_upload_fill,
                        size: 13,
                      ),
                      label: Text(
                        reel.isPosted ? 'Posted' : 'Tandai Posted',
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
          ],
        ),
      ),
    );
  }
}

class ReelPreviewDialog extends StatefulWidget {
  final ReelItem reel;
  final ScrapedListingDetail? detail;

  const ReelPreviewDialog({
    super.key,
    required this.reel,
    required this.detail,
  });

  @override
  State<ReelPreviewDialog> createState() => _ReelPreviewDialogState();
}

class _ReelPreviewDialogState extends State<ReelPreviewDialog> {
  late TextEditingController _captionController;
  bool _isSavingCaption = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    final saved = state.getSavedCaption(widget.reel.idListing);
    final generated = WhatsAppFormatter.buildReelCaption(
      widget.reel,
      detail: widget.detail,
      customAgents: state.customAgents,
    );
    _captionController = TextEditingController(
      text: (saved != null && saved.trim().isNotEmpty) ? saved : generated,
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String urlStr) async {
    if (urlStr.trim().isEmpty) return;
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final reel = widget.reel;
    final thumbUrl = reel.driveThumbnailUrl.isNotEmpty
        ? reel.driveThumbnailUrl
        : (widget.detail?.primaryImageUrl ?? '');

    return Dialog.fullscreen(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.film_fill,
                    color: AppColors.igPink,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reels Preview #${reel.cleanId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Video Preview Thumbnail + Launch Buttons
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumbUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: thumbUrl,
                            fit: BoxFit.cover,
                          ),
                        Container(color: Colors.black45),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.igPink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () =>
                                    _openUrl(reel.drivePreviewUrl),
                                icon: const Icon(CupertinoIcons.play_circle_fill),
                                label: const Text(
                                  'Tonton Video di Google Drive',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    _openUrl(reel.driveDownloadUrl),
                                icon: const Icon(
                                  CupertinoIcons.cloud_download,
                                  size: 18,
                                ),
                                label: const Text('Download File Video MP4'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metadata Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID Listing: #${reel.cleanId} • ME: ${reel.marketing}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lokasi: ${reel.lokasi}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        if (reel.spesifikasi.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Spesifikasi: ${reel.spesifikasi}',
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Editable Caption
                  const Text(
                    'Caption Instagram Reels:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    maxLines: 10,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _captionController.text),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Caption Reels berhasil disalin!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          icon: const Icon(CupertinoIcons.doc_on_doc, size: 17),
                          label: const Text(
                            'Salin Caption',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSavingCaption
                              ? null
                              : () async {
                                  setState(() => _isSavingCaption = true);
                                  await state.saveCustomCaption(
                                    reel.idListing,
                                    _captionController.text,
                                  );
                                  if (context.mounted) {
                                    setState(() => _isSavingCaption = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Caption Reels tersimpan ke Cloud!',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(
                            CupertinoIcons.cloud_upload_fill,
                            size: 17,
                          ),
                          label: Text(
                            _isSavingCaption ? 'Menyimpan...' : 'Simpan Caption',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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

class _CollapsibleSchedulingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<PublishFeedItem> items;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final void Function(PublishFeedItem item) onPickDate;

  const _CollapsibleSchedulingSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.items,
    required this.expanded,
    required this.onToggleExpand,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title (${items.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: AppColors.borderDark, height: 1),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tidak ada antrean pada kategori ini.',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SchedulingItemTile(
                            item: item,
                            onPickDate: () => onPickDate(item),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SchedulingItemTile extends StatelessWidget {
  final PublishFeedItem item;
  final VoidCallback onPickDate;

  const _SchedulingItemTile({
    required this.item,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${item.cleanId}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.isFromMeeting
                            ? AppColors.igPink.withOpacity(0.2)
                            : AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item.isFromMeeting ? 'Meeting' : 'Content',
                        style: TextStyle(
                          color: item.isFromMeeting
                              ? AppColors.igPink
                              : AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.namaMe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.lokasi.isNotEmpty
                      ? '📍 ${item.lokasi}'
                      : (item.judul.isNotEmpty ? item.judul : item.catatan),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11.5,
                  ),
                ),
                if (item.isScheduled) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Jadwal: ${formatIndonesianDateHeader(item.jadwalPosting)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onPickDate,
            icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 15),
            label: const Text(
              'Atur Tanggal Posting',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
