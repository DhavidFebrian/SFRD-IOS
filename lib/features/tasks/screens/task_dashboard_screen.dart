import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/listing_detail_bottom_sheet.dart';
import '../models/edit_foto_task.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Belum Selesai',
    'Belum Post IG',
    'Selesai',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditNotesDialog(BuildContext context, EditFotoTask task, AppStateProvider state) {
    final controller = TextEditingController(text: task.editNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Catatan: ${task.idListing}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tulis catatan editing atau status revisi...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.updateEditNotes(task, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B2D42),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    final search = _searchController.text.trim().toLowerCase();
    final tasks = state.editFotoTasks.where((t) {
      if (search.isNotEmpty) {
        final matches = t.idListing.toLowerCase().contains(search) ||
            t.namaMe.toLowerCase().contains(search) ||
            t.judul.toLowerCase().contains(search) ||
            t.editNotes.toLowerCase().contains(search);
        if (!matches) return false;
      }

      switch (_selectedFilter) {
        case 'Belum Selesai':
          return !t.done;
        case 'Belum Post IG':
          return !t.postingIg;
        case 'Selesai':
          return t.done;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari tugas edit foto, ME, atau catatan...',
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
                  label: Text(
                    f,
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
                  onSelected: (_) => setState(() => _selectedFilter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Task List
          Expanded(
            child: state.isLoading && state.editFotoTasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: state.refreshData,
                    child: tasks.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Tidak ada tugas edit foto untuk filter ini.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return _buildTaskCard(context, task, state);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, EditFotoTask task, AppStateProvider state) {
    final scraped = state.getListingDetail(task.idListing);
    final imageUrl = scraped?.primaryImageUrl;
    final displayTitle = scraped?.title.isNotEmpty == true ? scraped!.title : (task.judul.isNotEmpty ? task.judul : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ListingDetailBottomSheet.show(
            context,
            idListing: task.idListing,
            namaMe: task.namaMe,
            detail: scraped,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Thumbnail + ID + Status Chips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (ctx, _, __) => const Icon(CupertinoIcons.photo, color: Colors.grey),
                            )
                          : const Icon(CupertinoIcons.camera, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE600),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.idListing.isNotEmpty ? task.idListing : '(Manual)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF2B2D42),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: task.done ? Colors.green.shade100 : Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.done ? 'Edit Selesai' : 'Perlu Edit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: task.done ? Colors.green.shade900 : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        if (displayTitle != null)
                          Text(
                            displayTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2B2D42)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        // ME
                        Row(
                          children: [
                            const Icon(CupertinoIcons.person_fill, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              task.namaMe.isNotEmpty ? task.namaMe : 'ME Belum Ditentukan',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Two Checkbox Actions with instant Google Sheets sync
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Done Checkbox
                    Expanded(
                      child: InkWell(
                        onTap: () => state.toggleEditFotoDone(task),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.done,
                              activeColor: Colors.green,
                              onChanged: (_) => state.toggleEditFotoDone(task),
                            ),
                            const Flexible(
                              child: Text(
                                'Edit Selesai',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Posting IG Checkbox
                    Expanded(
                      child: InkWell(
                        onTap: () => state.toggleEditFotoPostingIg(task),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.postingIg,
                              activeColor: Colors.pink,
                              onChanged: (_) => state.toggleEditFotoPostingIg(task),
                            ),
                            const Flexible(
                              child: Text(
                                'Posting IG',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes
              if (task.editNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(CupertinoIcons.pencil_circle_fill, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Catatan: ${task.editNotes}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 18),

              // Action Row: Photos CTA & Edit Catatan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      ListingDetailBottomSheet.show(
                        context,
                        idListing: task.idListing,
                        namaMe: task.namaMe,
                        detail: scraped,
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          scraped?.galleryImages.isNotEmpty == true
                              ? '${scraped!.galleryImages.length} Foto Web'
                              : 'Lihat Detail Web',
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  TextButton.icon(
                    onPressed: () => _showEditNotesDialog(context, task, state),
                    icon: const Icon(CupertinoIcons.square_pencil, size: 16),
                    label: const Text('Ubah Catatan', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
