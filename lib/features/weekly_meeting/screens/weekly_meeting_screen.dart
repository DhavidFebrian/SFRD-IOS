import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/utils/whatsapp_formatter.dart';
import '../../../core/widgets/listing_detail_bottom_sheet.dart';
import '../models/meeting_listing.dart';
import '../widgets/add_meeting_listing_dialog.dart';

class WeeklyMeetingScreen extends StatefulWidget {
  const WeeklyMeetingScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyMeetingScreen> createState() => _WeeklyMeetingScreenState();
}

class _WeeklyMeetingScreenState extends State<WeeklyMeetingScreen> {
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Hot Property',
    'Foto Ulang',
    'IG Post',
    'Sudah Posting IG',
    'Belum Posting IG',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    // Extract unique dates from meeting listings
    final allDates = state.meetingListings
        .map((l) => l.date)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    allDates.sort((a, b) => b.compareTo(a));

    final selectedDate = state.selectedMeetingDate ?? (allDates.isNotEmpty ? allDates.first : '');

    // Filter listings
    final search = _searchController.text.trim().toLowerCase();
    final listings = state.meetingListings.where((l) {
      if (selectedDate.isNotEmpty && l.date.isNotEmpty && l.date != selectedDate) {
        return false;
      }
      if (search.isNotEmpty) {
        final matches = l.idListing.toLowerCase().contains(search) ||
            l.namaMe.toLowerCase().contains(search) ||
            l.lokasi.toLowerCase().contains(search) ||
            l.keterangan.toLowerCase().contains(search);
        if (!matches) return false;
      }

      switch (_selectedFilter) {
        case 'Hot Property':
          return l.isHot;
        case 'Foto Ulang':
          return l.isFotoUlang;
        case 'IG Post':
          return l.isIgTarget;
        case 'Sudah Posting IG':
          return l.postingIg;
        case 'Belum Posting IG':
          return !l.postingIg;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Date Selector Bar
          if (allDates.isNotEmpty)
            Container(
              height: 48,
              color: Colors.grey.shade100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: allDates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = allDates[index];
                  final isSelected = date == selectedDate;
                  return ChoiceChip(
                    label: Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2B2D42),
                    backgroundColor: Colors.white,
                    onSelected: (_) => state.setSelectedMeetingDate(date),
                  );
                },
              ),
            ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari ID listing, ME, atau lokasi...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final isSelected = f == _selectedFilter;
                return FilterChip(
                  label: Text(f, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2B2D42),
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: Colors.white,
                  onSelected: (_) => setState(() => _selectedFilter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Listings List
          Expanded(
            child: state.isLoading && state.meetingListings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: state.refreshData,
                    child: listings.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada listing untuk filter atau tanggal ini.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                            itemCount: listings.length,
                            itemBuilder: (context, index) {
                              final item = listings[index];
                              return _buildListingCard(context, item, state);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_meeting_listing_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AddMeetingListingDialog(initialDate: selectedDate),
          );
        },
        backgroundColor: const Color(0xFF2B2D42),
        icon: const Icon(CupertinoIcons.plus, color: Colors.white),
        label: const Text('Tambah Listing', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, MeetingListing item, AppStateProvider state) {
    final scraped = state.getListingDetail(item.idListing);
    final imageUrl = scraped?.primaryImageUrl;
    final displayTitle = scraped?.title.isNotEmpty == true ? scraped!.title : (item.judul.isNotEmpty ? item.judul : item.keterangan);
    final displayPrice = scraped?.price.isNotEmpty == true ? scraped!.price : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ListingDetailBottomSheet.show(
            context,
            idListing: item.idListing,
            namaMe: item.namaMe,
            detail: scraped,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Banner from raywhitecipete.net
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, _) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (ctx, _, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(CupertinoIcons.photo, size: 36, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2B2D42).withOpacity(0.08),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.photo_on_rectangle, size: 32, color: Colors.grey.shade400),
                                const SizedBox(height: 4),
                                Text(
                                  scraped?.isSold == true ? 'SOLD / INACTIVE' : 'Ketuk untuk memuat foto web...',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Top Badges Overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE600),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      item.idListing.isNotEmpty ? item.idListing : '(Tanpa ID)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                  ),
                ),

                if (scraped?.isSold == true)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SOLD',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else if (displayPrice != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayPrice,
                        style: const TextStyle(
                          color: Color(0xFFFFE600),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (displayTitle.isNotEmpty)
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2B2D42),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),

                  // ME Name Row
                  Row(
                    children: [
                      const Icon(CupertinoIcons.person_fill, size: 15, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.namaMe.isNotEmpty ? item.namaMe : 'ME Tidak Disebutkan',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      // Posting IG Switch
                      Row(
                        children: [
                          const Text('Posting IG:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Switch.adaptive(
                            value: item.postingIg,
                            activeColor: Colors.green,
                            onChanged: (_) => state.toggleMeetingListingPostingIg(item),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Lokasi
                  if (item.lokasi.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.location_solid, size: 15, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.lokasi,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.mapsQueryUrl.isNotEmpty)
                          InkWell(
                            onTap: () => launchUrl(Uri.parse(item.mapsQueryUrl), mode: LaunchMode.externalApplication),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Maps',
                                style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Catatan
                  if (item.catatan.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'Catatan: ${item.catatan}',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],

                  const Divider(height: 20),

                  // Bottom Action Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // View Gallery & Specs CTA
                      InkWell(
                        onTap: () {
                          ListingDetailBottomSheet.show(
                            context,
                            idListing: item.idListing,
                            namaMe: item.namaMe,
                            detail: scraped,
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              scraped?.galleryImages.isNotEmpty == true
                                  ? '${scraped!.galleryImages.length} Foto • Detail'
                                  : 'Lihat Detail Web',
                              style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: [
                          // WhatsApp Broadcast
                          ElevatedButton.icon(
                            onPressed: () {
                              final broadcastText = WhatsAppFormatter.generateWeeklyMeetingBroadcast(item);
                              WhatsAppFormatter.openWhatsApp(message: broadcastText);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 14),
                            label: const Text('WA Broadcast', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 6),

                          // Delete button
                          IconButton(
                            icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Listing?'),
                                  content: Text('Yakin ingin menghapus ${item.idListing}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        state.deleteMeetingListingItem(item);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
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
