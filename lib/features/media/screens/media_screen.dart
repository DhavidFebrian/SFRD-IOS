import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/utils/whatsapp_formatter.dart';
import '../models/schedule.dart';
import '../widgets/add_schedule_dialog.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({Key? key}) : super(key: key);

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterChips = [
    'Semua',
    'Aktif',
    'Selesai',
    'Foto Ulang',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final schedules = state.filteredSchedules;

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari jadwal foto, ME, lokasi, staff...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          state.setSearchQuery('');
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
              onChanged: (val) => state.setSearchQuery(val),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterChips[index];
                final isSelected = state.mediaFilter == filter;
                return FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2B2D42),
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: Colors.white,
                  onSelected: (_) => state.setMediaFilter(filter),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Schedule List
          Expanded(
            child: state.isLoading && state.schedules.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: state.refreshData,
                    child: schedules.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada jadwal media pada lembar ini.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                            itemCount: schedules.length,
                            itemBuilder: (context, index) {
                              final item = schedules[index];
                              return _buildScheduleCard(context, item);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_schedule_media_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddScheduleDialog(),
          );
        },
        backgroundColor: const Color(0xFF2B2D42),
        icon: const Icon(CupertinoIcons.camera_fill, color: Colors.white),
        label: const Text('Tambah Jadwal', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, Schedule item) {
    final isDone = item.isDone;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID Listing + Type + Status Chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.idListing.isNotEmpty ? item.idListing : '(Manual)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.type,
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDone ? 'Selesai' : 'Pending',
                    style: TextStyle(
                      color: isDone ? Colors.green.shade900 : Colors.orange.shade900,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ME Name
            Row(
              children: [
                const Icon(CupertinoIcons.person_fill, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  item.namaMe.isNotEmpty ? item.namaMe : 'ME Belum Ditentukan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tanggal & Jam
            Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${item.tanggal} • ${item.jam}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                if (item.staff.isNotEmpty) ...[
                  const Spacer(),
                  const Icon(CupertinoIcons.camera, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    item.staff,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),

            // Lokasi
            if (item.lokasi.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(CupertinoIcons.location_solid, size: 15, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.lokasi,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 2,
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
                          style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const Divider(height: 20),

            // Bottom Actions: Website link + WhatsApp Follow Up
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.websiteUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(item.websiteUrl), mode: LaunchMode.externalApplication),
                    icon: const Icon(CupertinoIcons.link, size: 14),
                    label: const Text('RayWhite.net', style: TextStyle(fontSize: 12)),
                  )
                else
                  const SizedBox(),

                ElevatedButton.icon(
                  onPressed: () {
                    final message = WhatsAppFormatter.generateScheduleFollowUpMessage(item);
                    WhatsAppFormatter.openWhatsApp(message: message);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 14),
                  label: const Text('Follow Up WA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
