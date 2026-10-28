import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/agent_contact.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/services/rwc_social_media_downloader.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/utils/whatsapp_formatter.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../publish/models/publish_item.dart';
import '../models/meeting_listing.dart';
import '../widgets/add_meeting_listing_dialog.dart';

class WeeklyMeetingScreen extends StatefulWidget {
  const WeeklyMeetingScreen({super.key});

  @override
  State<WeeklyMeetingScreen> createState() => _WeeklyMeetingScreenState();
}

class _WeeklyMeetingScreenState extends State<WeeklyMeetingScreen> {
  int _selectedTopSegment = 0; // 0: Weekly Meeting, 1: Absensi Meeting
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _promptPinAndOpenHackerTerminal(
    BuildContext context,
    AppStateProvider state,
  ) async {
    final pinController = TextEditingController();
    String? errorMsg;

    final authorized = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF070B0E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFF00FF66), width: 1.3),
              ),
              title: const Row(
                children: [
                  Icon(
                    CupertinoIcons.chevron_left_slash_chevron_right,
                    color: Color(0xFF00FF66),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SECURITY GATE // PIN 2332',
                      style: TextStyle(
                        color: Color(0xFF00FF66),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan PIN Otorisasi untuk menjalankan Cyberpunk Auto Sync Web Scraper:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF00FF66),
                      fontFamily: 'Courier',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      errorText: errorMsg,
                      filled: true,
                      fillColor: const Color(0xFF0E161B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00FF66)),
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim() == '2332') {
                        Navigator.of(ctx).pop(true);
                      } else {
                        setDialogState(() {
                          errorMsg = 'ACCESS DENIED: Invalid PIN';
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'ABORT',
                    style: TextStyle(color: Colors.white54, fontFamily: 'Courier'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (pinController.text.trim() == '2332') {
                      Navigator.of(ctx).pop(true);
                    } else {
                      setDialogState(() {
                        errorMsg = 'ACCESS DENIED: Invalid PIN';
                      });
                    }
                  },
                  child: const Text(
                    'AUTHORIZE',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (authorized == true && context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => HackerTerminalDialog(listings: state.meetingListings),
      );
    }
  }

  Future<void> _confirmDeleteListing(
    BuildContext context,
    AppStateProvider state,
    MeetingListing listing,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Listing Meeting?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus listing #${listing.cleanId} (${listing.namaMe}) dari daftar Weekly Meeting?',
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await state.deleteMeetingListingItem(listing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final dates = state.availableMeetingDates;
    final filteredListings = state.filteredMeetingListings;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Segmented Switcher: Weekly Meeting vs Absensi Meeting
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
                        onTap: () => setState(() => _selectedTopSegment = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTopSegment == 0
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.person_2_square_stack_fill,
                                size: 16,
                                color: _selectedTopSegment == 0
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Weekly Meeting',
                                style: TextStyle(
                                  color: _selectedTopSegment == 0
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
                        onTap: () => setState(() => _selectedTopSegment = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTopSegment == 1
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_seal_fill,
                                size: 16,
                                color: _selectedTopSegment == 1
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Absensi Meeting',
                                style: TextStyle(
                                  color: _selectedTopSegment == 1
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

            // Render AttendanceScreen when Absensi Meeting is selected
            if (_selectedTopSegment == 1)
              const Expanded(
                child: AttendanceScreen(embedded: true),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: state.refreshData,
                  child: CustomScrollView(
                    slivers: [
                      // Month Selector + Tambah Listing Button
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderDark),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: AppStateProvider.regularMonths
                                              .contains(state.selectedMonth)
                                          ? state.selectedMonth
                                          : AppStateProvider.regularMonths.first,
                                      dropdownColor: AppColors.cardDark,
                                      isExpanded: true,
                                      icon: const Icon(
                                        CupertinoIcons.chevron_down,
                                        color: AppColors.accent,
                                        size: 16,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                      items: AppStateProvider.regularMonths
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              child: Text('Bulan: $m'),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          state.setSelectedMonth(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => AddMeetingListingDialog.show(context),
                                icon: const Icon(CupertinoIcons.add_circled_solid, size: 18),
                                label: const Text(
                                  'Tambah Listing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Meeting Date Filter Chips
                      if (dates.isNotEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 40,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: const Text('Semua Tanggal'),
                                    selected: state.selectedMeetingDate == null ||
                                        state.selectedMeetingDate!.isEmpty,
                                    selectedColor: AppColors.accent,
                                    backgroundColor: AppColors.cardDark,
                                    labelStyle: TextStyle(
                                      color: (state.selectedMeetingDate == null ||
                                              state.selectedMeetingDate!.isEmpty)
                                          ? Colors.black
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                    onSelected: (_) => state.setSelectedMeetingDate(null),
                                  ),
                                ),
                                ...dates.map((d) {
                                  final selected = state.selectedMeetingDate == d;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(d),
                                      selected: selected,
                                      selectedColor: AppColors.accent,
                                      backgroundColor: AppColors.cardDark,
                                      labelStyle: TextStyle(
                                        color: selected ? Colors.black : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                      onSelected: (_) => state.setSelectedMeetingDate(d),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

                      // Search Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: TextField(
                            controller: _searchController,
                            onChanged: state.setSearchQuery,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Cari ID Listing, Nama ME, Lokasi, Catatan...',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 12.5,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.search,
                                color: AppColors.textSecondaryDark,
                                size: 18,
                              ),
                              suffixIcon: state.searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        state.setSearchQuery('');
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
                      ),

                      // Meeting Control Desk Card (Newsletter, Scheduling, Auto Sync Web)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF192236), Color(0xFF111726)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.slider_horizontal_3,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'MEETING CONTROL DESK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${filteredListings.length} Listing',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ControlDeskButton(
                                        icon: CupertinoIcons.doc_richtext,
                                        label: 'Newsletter',
                                        color: AppColors.accent,
                                        onTap: () {
                                          showDialog<void>(
                                            context: context,
                                            builder: (_) => const NewsletterDialog(),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ControlDeskButton(
                                        icon: CupertinoIcons.calendar_badge_plus,
                                        label: 'Scheduling',
                                        color: AppColors.igPink,
                                        onTap: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => const SchedulingDialog(),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ControlDeskButton(
                                        icon: CupertinoIcons.chevron_left_slash_chevron_right,
                                        label: 'Auto Sync Web',
                                        color: const Color(0xFF00FF66),
                                        onTap: () => _promptPinAndOpenHackerTerminal(
                                          context,
                                          state,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2-Column Grid of MeetingListingCard
                      if (state.isLoading && filteredListings.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.accent),
                          ),
                        )
                      else if (filteredListings.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text_search,
                                    color: Colors.white.withOpacity(0.24),
                                    size: 54,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum ada listing pada sesi meeting ini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.56,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = filteredListings[index];
                                final detail = state.getListingDetail(item.idListing);
                                return MeetingListingCard(
                                  listing: item,
                                  detail: detail,
                                  onToggleMeHighlight: () =>
                                      state.toggleMeetingMeHighlight(item),
                                  onTogglePostingIg: () =>
                                      state.toggleMeetingListingPostingIg(item),
                                  onBroadcastWa: () {
                                    final msg = WhatsAppFormatter
                                        .generateWeeklyMeetingBroadcast(item);
                                    final phone = getAgentPhoneByName(item.namaMe);
                                    WhatsAppFormatter.openWhatsApp(
                                      phoneNumber: phone,
                                      message: msg,
                                    );
                                  },
                                  onEdit: () => AddMeetingListingDialog.show(
                                    context,
                                    existingListing: item,
                                  ),
                                  onDelete: () => _confirmDeleteListing(
                                    context,
                                    state,
                                    item,
                                  ),
                                );
                              },
                              childCount: filteredListings.length,
                            ),
                          ),
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

class _ControlDeskButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlDeskButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeetingListingCard extends StatelessWidget {
  final MeetingListing listing;
  final ScrapedListingDetail? detail;
  final VoidCallback onToggleMeHighlight;
  final VoidCallback onTogglePostingIg;
  final VoidCallback onBroadcastWa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MeetingListingCard({
    super.key,
    required this.listing,
    required this.detail,
    required this.onToggleMeHighlight,
    required this.onTogglePostingIg,
    required this.onBroadcastWa,
    required this.onEdit,
    required this.onDelete,
  });

  List<String> _parseCategories(String raw) {
    final upper = raw.toUpperCase();
    final badges = <String>[];
    if (upper.contains('HOT')) badges.add('HOT PROPERTY');
    if (upper.contains('FOTO ULANG') || upper.contains('ULANG')) {
      badges.add('FOTO ULANG');
    }
    if (upper.contains('IG') || upper.contains('INSTAGRAM')) {
      badges.add('IG');
    }
    if (badges.isEmpty && raw.trim().isNotEmpty) {
      badges.add(raw.trim().toUpperCase());
    }
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final isSold = detail?.isSold == true;
    final imgUrl = detail?.primaryImageUrl;
    final badges = _parseCategories(listing.keterangan);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: listing.meHighlighted
              ? AppColors.success.withOpacity(0.8)
              : AppColors.borderDark,
          width: listing.meHighlighted ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scraped Image + Diagonal SOLD Watermark + Top Badges
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
                        size: 32,
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.surfaceDark,
                    child: const Icon(
                      CupertinoIcons.house_fill,
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
                        Colors.black.withOpacity(0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // #no and #cleanId
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${listing.no}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (listing.websiteUrl.isNotEmpty) {
                            final uri = Uri.parse(listing.websiteUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${listing.cleanId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Diagonal Red SOLD Watermark if detail?.isSold == true
                if (isSold)
                  Center(
                    child: Transform.rotate(
                      angle: -math.pi / 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Text(
                          'SOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Category Badges at bottom of image
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: badges.map((b) {
                      final color = switch (b) {
                        'HOT PROPERTY' => AppColors.hotProperty,
                        'FOTO ULANG' => AppColors.fotoUlangBlue,
                        'IG' => AppColors.igPink,
                        _ => AppColors.info,
                      };
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          b,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 8.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Body Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.namaMe.isNotEmpty ? listing.namaMe : 'Ray White Cipete',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        color: AppColors.accent,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.lokasi.isNotEmpty
                              ? listing.lokasi
                              : (detail?.lokasi.isNotEmpty == true
                                  ? detail!.lokasi
                                  : '-'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      listing.catatan.isNotEmpty
                          ? listing.catatan
                          : (detail?.title.isNotEmpty == true
                              ? detail!.title
                              : 'Tidak ada catatan khusus'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                    ),
                  ),

                  // Action Toggle Chips: Tandai ME & IG Posted
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onToggleMeHighlight,
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: listing.meHighlighted
                                  ? AppColors.success.withOpacity(0.22)
                                  : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: listing.meHighlighted
                                    ? AppColors.success
                                    : AppColors.borderDark,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              listing.meHighlighted ? '✓ Tandai ME' : 'Tandai ME',
                              style: TextStyle(
                                color: listing.meHighlighted
                                    ? AppColors.success
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: InkWell(
                          onTap: onTogglePostingIg,
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: listing.postingIg
                                  ? AppColors.igPink.withOpacity(0.22)
                                  : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: listing.postingIg
                                    ? AppColors.igPink
                                    : AppColors.borderDark,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              listing.postingIg ? '✓ IG Posted' : 'IG Posted',
                              style: TextStyle(
                                color: listing.postingIg
                                    ? AppColors.igPink
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Bottom Icon Row: WA Broadcast, Edit, Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: onBroadcastWa,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                CupertinoIcons.chat_bubble_text_fill,
                                color: AppColors.success,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'WA',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: onEdit,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                CupertinoIcons.pencil,
                                color: AppColors.primaryLight,
                                size: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: onDelete,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                CupertinoIcons.trash,
                                color: AppColors.error,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewsletterDialog extends StatefulWidget {
  const NewsletterDialog({super.key});

  @override
  State<NewsletterDialog> createState() => _NewsletterDialogState();
}

class _NewsletterDialogState extends State<NewsletterDialog> {
  late TextEditingController _titleController;
  String? _selectedMeetingDate;
  String? _selectedCoverListingId;
  String? _selectedCoverImageUrl;
  bool _isGenerating = false;
  String _progressStatus = '';
  double _progressValue = 0.0;
  File? _generatedPdfFile;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _selectedMeetingDate = state.selectedMeetingDate ??
        (state.availableMeetingDates.isNotEmpty
            ? state.availableMeetingDates.last
            : null);
    _titleController = TextEditingController(
      text: 'HOT PROPERTY OF THE WEEK - ${state.selectedMonth.toUpperCase()}',
    );
    _syncDefaultCover(state);
  }

  void _syncDefaultCover(AppStateProvider state) {
    final listings = _listingsForSelectedDate(state);
    if (listings.isNotEmpty) {
      _selectedCoverListingId = listings.first.cleanId;
      _selectedCoverImageUrl =
          state.getListingImage(listings.first.idListing) ?? '';
    }
  }

  List<MeetingListing> _listingsForSelectedDate(AppStateProvider state) {
    return state.meetingListings.where((l) {
      if (_selectedMeetingDate == null || _selectedMeetingDate!.isEmpty) {
        return true;
      }
      return l.date == _selectedMeetingDate;
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _downloadNewsletterPdf(AppStateProvider state) async {
    final listings = _listingsForSelectedDate(state);
    if (listings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada listing pada tanggal meeting yang dipilih.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progressStatus = 'Menyiapkan dokumen Newsletter...';
      _progressValue = 0.05;
    });

    final idAndTitles = <MapEntry<String, String>>[];
    final fallbackImages = <String, String>{};

    for (final l in listings) {
      final cleanId = l.cleanId;
      final detail = state.getListingDetail(l.idListing);
      final headline = extractJudulFromNotes(l.catatan) ??
          (l.judul.isNotEmpty
              ? l.judul
              : (detail?.title.isNotEmpty == true
                  ? detail!.title
                  : 'PROPERTI PILIHAN #${l.cleanId}'));
      idAndTitles.add(MapEntry(cleanId, headline));
      if (detail?.primaryImageUrl != null &&
          detail!.primaryImageUrl!.isNotEmpty) {
        fallbackImages[cleanId] = detail.primaryImageUrl!;
      }
    }

    final coverUrl = (_selectedCoverImageUrl != null &&
            _selectedCoverImageUrl!.isNotEmpty)
        ? _selectedCoverImageUrl!
        : (fallbackImages.values.firstOrNull ?? '');

    final pdfFile = await RwcSocialMediaDownloader().generateNewsletterPdf(
      titleText: _titleController.text.trim(),
      coverImageUrl: coverUrl,
      listingIdAndTitles: idAndTitles,
      fallbackPrimaryImages: fallbackImages,
      onProgress: (status, progress) {
        if (mounted) {
          setState(() {
            _progressStatus = status;
            _progressValue = progress;
          });
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _generatedPdfFile = pdfFile;
    });

    if (pdfFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Newsletter berhasil dibuat: ${pdfFile.path.split('/').last}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final dates = state.availableMeetingDates;
    final listings = _listingsForSelectedDate(state);
    final gallery = _selectedCoverListingId != null
        ? state.getListingGallery(_selectedCoverListingId!)
        : <String>[];

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.doc_richtext,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Newsletter Generator (3:4 HD PDF)',
                      style: TextStyle(
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
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderDark, height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meeting Date Selector
                    if (dates.isNotEmpty) ...[
                      const Text(
                        'Pilih Tanggal Meeting:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: dates.contains(_selectedMeetingDate)
                            ? _selectedMeetingDate
                            : dates.first,
                        dropdownColor: AppColors.cardDark,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.cardDark,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: dates
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMeetingDate = val;
                            _syncDefaultCover(state);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Newsletter Title Input
                    const Text(
                      'Judul Cover Newsletter:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cover Listing Picker
                    if (listings.isNotEmpty) ...[
                      const Text(
                        'Pilih Listing untuk Foto Cover:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: listings.any((l) => l.cleanId == _selectedCoverListingId)
                            ? _selectedCoverListingId
                            : listings.first.cleanId,
                        dropdownColor: AppColors.cardDark,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.cardDark,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: listings.map((l) {
                          return DropdownMenuItem(
                            value: l.cleanId,
                            child: Text(
                              '#${l.cleanId} — ${l.namaMe} (${l.lokasi})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCoverListingId = val;
                              _selectedCoverImageUrl =
                                  state.getListingImage(val) ?? '';
                            });
                          }
                        },
                      ),
                    ],

                    // Photo Picker from Scraped Gallery
                    if (gallery.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: gallery.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final url = gallery[index];
                            final selected = _selectedCoverImageUrl == url;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCoverImageUrl = url),
                              child: Container(
                                width: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Live 3:4 Cover Preview with White Title Box
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1523),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_selectedCoverImageUrl != null &&
                                    _selectedCoverImageUrl!.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: _selectedCoverImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                Positioned(
                                  left: 14,
                                  right: 14,
                                  bottom: 18,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'RAY WHITE CIPETE',
                                          style: TextStyle(
                                            color: Color(0xFFD9A700),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 8,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _titleController.text.trim().isEmpty
                                              ? 'NEWSLETTER'
                                              : _titleController.text
                                                  .trim()
                                                  .toUpperCase(),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_isGenerating) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: _progressValue,
                        color: AppColors.accent,
                        backgroundColor: AppColors.cardDark,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _progressStatus,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Actions: Download PDF & Share PDF ke WA
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isGenerating
                          ? null
                          : () => _downloadNewsletterPdf(state),
                      icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 17),
                      label: const Text(
                        'Download PDF (3:4 HD)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  if (_generatedPdfFile != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Share.shareXFiles(
                            [XFile(_generatedPdfFile!.path)],
                            text: _titleController.text.trim(),
                          );
                        },
                        icon: const Icon(CupertinoIcons.share_solid, size: 17),
                        label: const Text(
                          'Share PDF ke WA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SchedulingDialog extends StatelessWidget {
  const SchedulingDialog({super.key});

  Future<void> _pickScheduleDate(
    BuildContext context,
    AppStateProvider state,
    MeetingListing item,
  ) async {
    final initial = parseIndonesianDate(item.jadwalPosting) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')} ${kIndonesianMonths[picked.month - 1]} ${picked.year}';
      await state.updateMeetingScheduleDate(item, formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final igItems = state.meetingListings
        .where((l) => l.keterangan.toUpperCase().contains('IG'))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar_badge_plus,
                  color: AppColors.igPink,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scheduling IG Meeting (${igItems.length} Listing)',
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
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          Expanded(
            child: igItems.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada listing berkategori IG pada bulan ini.',
                      style: TextStyle(color: AppColors.textSecondaryDark),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: igItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = igItems[index];
                      final hasSchedule = item.isScheduled;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasSchedule
                                ? AppColors.success.withOpacity(0.5)
                                : AppColors.borderDark,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${item.cleanId} • ${item.namaMe}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasSchedule
                                        ? 'Jadwal: ${formatIndonesianDateHeader(item.jadwalPosting)}'
                                        : 'Belum dijadwalkan',
                                    style: TextStyle(
                                      color: hasSchedule
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(color: AppColors.accent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  _pickScheduleDate(context, state, item),
                              icon: const Icon(CupertinoIcons.calendar, size: 15),
                              label: Text(
                                hasSchedule ? 'Ubah' : 'Atur Jadwal',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
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

class HackerTerminalDialog extends StatefulWidget {
  final List<MeetingListing> listings;

  const HackerTerminalDialog({
    super.key,
    required this.listings,
  });

  @override
  State<HackerTerminalDialog> createState() => _HackerTerminalDialogState();
}

class _HackerTerminalDialogState extends State<HackerTerminalDialog> {
  static const Color _bgCyber = Color(0xFF070B0E);
  static const Color _neonGreen = Color(0xFF00FF66);

  final List<String> _logs = [];
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSyncing = false;
  double _progress = 0.0;
  int _syncedCount = 0;
  int _soldCount = 0;

  @override
  void initState() {
    super.initState();
    _appendLog('RWC CYBERPUNK WEB SCRAPER KERNEL v8.9.15 INITIALIZED...');
    _appendLog('TYPE "help" FOR COMMANDS OR WAIT FOR AUTO-SYNC SEQUENCE.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAutoSync();
    });
  }

  @override
  void dispose() {
    _cmdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendLog(String line) {
    if (!mounted) return;
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.add('[$ts] $line');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runAutoSync() async {
    if (_isSyncing) return;
    final state = context.read<AppStateProvider>();
    final items = widget.listings;
    if (items.isEmpty) {
      _appendLog('WARN: NO MEETING LISTINGS FOUND IN ACTIVE BUFFER.');
      return;
    }

    setState(() {
      _isSyncing = true;
      _progress = 0.0;
      _syncedCount = 0;
      _soldCount = 0;
    });

    _appendLog('STARTING DEEP WEB SYNC FOR ${items.length} LISTINGS...');

    for (var i = 0; i < items.length; i++) {
      if (!mounted) return;
      final item = items[i];
      final cleanId = item.cleanId;
      _appendLog('>> FETCHING /ListingView/Detail/$cleanId (${item.namaMe})...');

      final detail = await state.fetchListingDetails(
        item.idListing,
        defaultMeName: item.namaMe,
        force: true,
      );

      if (!mounted) return;
      _syncedCount++;
      if (detail != null) {
        if (detail.isSold) {
          _soldCount++;
          _appendLog('   [!] STATUS: SOLD / INACTIVE DETECTED (#$cleanId)');
        } else {
          _appendLog(
            '   [OK] ${detail.title} | ${detail.price} | LOC: ${detail.lokasi}',
          );
        }
      } else {
        _appendLog('   [ERR] FAILED TO PARSE NODE #$cleanId');
      }

      setState(() {
        _progress = (i + 1) / items.length;
      });
    }

    _appendLog(
      'SYNC COMPLETE: $_syncedCount NODES PROCESSED, $_soldCount SOLD.',
    );
    setState(() => _isSyncing = false);
  }

  void _handleCommand(String rawCmd) {
    final cmd = rawCmd.trim().toLowerCase();
    _cmdController.clear();
    if (cmd.isEmpty) return;

    _appendLog('root@rwc-node:~# $cmd');
    switch (cmd) {
      case 'sync':
        _runAutoSync();
        break;
      case 'help':
        _appendLog('AVAILABLE COMMANDS: sync | status | clear | help');
        break;
      case 'status':
        _appendLog(
          'STATUS: ${_isSyncing ? "RUNNING" : "IDLE"} | SYNCED: $_syncedCount/${widget.listings.length} | SOLD: $_soldCount',
        );
        break;
      case 'clear':
        setState(() => _logs.clear());
        break;
      default:
        _appendLog('UNKNOWN COMMAND "$cmd". TYPE "help".');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bgCyber,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _neonGreen, width: 1.5),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.76,
        child: Column(
          children: [
            // Terminal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _neonGreen.withOpacity(0.12),
                border: const Border(
                  bottom: BorderSide(color: _neonGreen, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.chevron_left_slash_chevron_right,
                    color: _neonGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'CYBERPUNK WEB SYNC TERMINAL // v8.9.15',
                      style: TextStyle(
                        color: _neonGreen,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: _neonGreen,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFF0E181E),
              color: _neonGreen,
              minHeight: 4,
            ),

            // Terminal Output Logs
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: _neonGreen,
                        fontFamily: 'Courier',
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Command Input Box
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _neonGreen, width: 0.8)),
              ),
              child: Row(
                children: [
                  const Text(
                    'root@rwc:~# ',
                    style: TextStyle(
                      color: _neonGreen,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _cmdController,
                      onSubmitted: _handleCommand,
                      style: const TextStyle(
                        color: _neonGreen,
                        fontFamily: 'Courier',
                        fontSize: 12.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'sync | status | help | clear',
                        hintStyle: TextStyle(
                          color: Colors.white24,
                          fontFamily: 'Courier',
                          fontSize: 11.5,
                        ),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleCommand(_cmdController.text),
                    icon: const Icon(
                      CupertinoIcons.arrow_right_circle_fill,
                      color: _neonGreen,
                      size: 20,
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
