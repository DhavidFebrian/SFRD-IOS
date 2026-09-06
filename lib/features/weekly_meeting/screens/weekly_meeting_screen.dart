import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sheets_service.dart';
import '../../../core/utils/whatsapp_formatter.dart';
import '../models/meeting_listing.dart';

class WeeklyMeetingScreen extends StatefulWidget {
  const WeeklyMeetingScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyMeetingScreen> createState() => _WeeklyMeetingScreenState();
}

class _WeeklyMeetingScreenState extends State<WeeklyMeetingScreen> {
  final SheetsService _sheetsService = SheetsService();
  final _idController = TextEditingController();
  final _namaMeController = TextEditingController();
  final _judulController = TextEditingController();
  final _hargaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _catatanManualController = TextEditingController();
  final _searchController = TextEditingController();

  final Set<String> _selectedEditOptions = {};
  String _selectedStatus = 'Review';
  String _searchQuery = '';
  bool _isLoading = false;

  final List<String> _addTemplates = ['ratio', 'perspective', 'remove object', 'revisi harga', 'foto ulang'];

  List<MeetingListing> _listings = [
    MeetingListing(
      id: '1',
      idListing: 'LST-8901',
      namaMe: 'David Febrian',
      judul: 'Rumah Mewah Minimalis 2 Lantai Araya',
      harga: 'Rp 2.850.000.000',
      lokasi: 'Araya Malang',
      catatan: 'edit ratio, judul Rumah Mewah Araya, siap promo IG',
      status: 'Disetujui',
    ),
    MeetingListing(
      id: '2',
      idListing: 'LST-8902',
      namaMe: 'Sarah Wijaya',
      judul: 'Ruko Strategis Siap Huni Soekarno Hatta',
      harga: 'Rp 1.900.000.000',
      lokasi: 'Soekarno Hatta',
      catatan: 'edit remove object, revisi harga',
      status: 'Review',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _idController.addListener(_onIdChanged);
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    try {
      final remoteList = await _sheetsService.fetchWeeklyMeetingListings();
      if (remoteList.isNotEmpty) {
        setState(() {
          _listings = remoteList;
        });
      }
    } catch (_) {
      // Keep existing list on failure
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _namaMeController.dispose();
    _judulController.dispose();
    _hargaController.dispose();
    _lokasiController.dispose();
    _catatanManualController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onIdChanged() {
    final cleanId = _idController.text.trim();
    if (cleanId.length >= 3) {
      if (cleanId.toUpperCase().contains('DF') || cleanId.endsWith('1')) {
        _namaMeController.text = 'David Febrian';
      } else if (cleanId.toUpperCase().contains('SW') || cleanId.endsWith('2')) {
        _namaMeController.text = 'Sarah Wijaya';
      }
    }
  }

  String get _computedCatatan {
    final List<String> parts = [];
    if (_selectedEditOptions.isNotEmpty) {
      parts.add('edit ${_selectedEditOptions.join(" ")}');
    }
    if (_judulController.text.trim().isNotEmpty) {
      parts.add('judul ${_judulController.text.trim()}');
    }
    if (_catatanManualController.text.trim().isNotEmpty) {
      parts.add(_catatanManualController.text.trim());
    }
    return parts.join(', ');
  }

  Future<void> _submitListing() async {
    final idListing = _idController.text.trim();
    if (idListing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Listing wajib diisi!')),
      );
      return;
    }

    final newListing = MeetingListing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idListing: idListing,
      namaMe: _namaMeController.text.trim(),
      judul: _judulController.text.trim(),
      harga: _hargaController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      catatan: _computedCatatan,
      status: _selectedStatus,
    );

    setState(() {
      _listings.insert(0, newListing);
      _idController.clear();
      _namaMeController.clear();
      _judulController.clear();
      _hargaController.clear();
      _lokasiController.clear();
      _catatanManualController.clear();
      _selectedEditOptions.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listing Weekly Meeting berhasil ditambahkan! Menyinkronkan ke Sheets...'),
        backgroundColor: AppColors.success,
      ),
    );

    // Sync to backend Google Sheets
    _sheetsService.addWeeklyMeetingListing(
      idListing: newListing.idListing,
      namaMe: newListing.namaMe,
      keterangan: newListing.judul,
      catatan: newListing.catatan,
      lokasi: newListing.lokasi,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _listings.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.idListing.toLowerCase().contains(q) ||
          item.namaMe.toLowerCase().contains(q) ||
          item.judul.toLowerCase().contains(q) ||
          item.lokasi.toLowerCase().contains(q) ||
          item.catatan.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meeting', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(CupertinoIcons.arrow_clockwise),
            tooltip: 'Refresh Data',
            onPressed: _loadListings,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.share),
            tooltip: 'Bagikan Rekap',
            onPressed: () {
              if (filteredList.isEmpty) return;
              final buffer = StringBuffer();
              buffer.writeln('📋 *REKAP WEEKLY MEETING RWC MEDIA PRODUCTION*');
              buffer.writeln('Total Listing: ${filteredList.length}\n');
              for (var l in filteredList) {
                buffer.writeln('• *${l.idListing}* - ${l.namaMe}');
                if (l.judul.isNotEmpty) buffer.writeln('  Judul: ${l.judul}');
                if (l.catatan.isNotEmpty) buffer.writeln('  Catatan: ${l.catatan}');
                buffer.writeln('');
              }
              WhatsAppFormatter.sendWhatsAppMessage(phoneNumber: '', message: buffer.toString());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadListings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Form Input Listing
            _buildFormCard(),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: 'Cari ID Listing, Nama ME, atau Lokasi...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Listing (${filteredList.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_listings.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _listings.clear()),
                    icon: const Icon(CupertinoIcons.trash, size: 16, color: AppColors.error),
                    label: const Text('Bersihkan', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  )
              ],
            ),
            const SizedBox(height: 12),

            // Listing Cards
            if (filteredList.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(CupertinoIcons.doc_text_search, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Tidak ada listing ditemukan.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ...filteredList.map((item) => _buildListingCard(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.plus_app_fill, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Input Listing Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),

          // ID Listing & Nama ME
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID Listing',
                    hintText: 'Misal: 12503',
                    prefixIcon: Icon(CupertinoIcons.tag, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _namaMeController,
                  decoration: const InputDecoration(
                    labelText: 'Nama ME (Autofill)',
                    hintText: 'Nama Marketing',
                    prefixIcon: Icon(CupertinoIcons.person, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Judul Properti
          TextField(
            controller: _judulController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Judul Properti',
              hintText: 'Contoh: Rumah Mewah Minimalis 2 Lantai Araya',
              prefixIcon: Icon(CupertinoIcons.house, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // Lokasi & Harga
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    hintText: 'Misal: Araya Malang',
                    prefixIcon: Icon(CupertinoIcons.location, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Harga / Nilai',
                    hintText: 'Misal: 2,85 M',
                    prefixIcon: Icon(CupertinoIcons.money_dollar, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Template Opsi Cepat (Ratio, Perspective, dll)
          const Text('Template Opsi Edit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _addTemplates.map((tpl) {
              final isSelected = _selectedEditOptions.contains(tpl);
              return FilterChip(
                label: Text(tpl),
                selected: isSelected,
                selectedColor: AppColors.primaryLight.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedEditOptions.add(tpl);
                    } else {
                      _selectedEditOptions.remove(tpl);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Catatan Manual
          TextField(
            controller: _catatanManualController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Catatan Tambahan',
              hintText: 'Keterangan khusus materi...',
              prefixIcon: Icon(CupertinoIcons.pencil, size: 18),
            ),
          ),
          const SizedBox(height: 16),

          // Live Constructed Notes Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.eye, size: 14, color: AppColors.textSecondaryLight),
                    SizedBox(width: 6),
                    Text(
                      'Live Preview Catatan:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _computedCatatan.isEmpty ? '(Belum ada catatan)' : _computedCatatan,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: _computedCatatan.isEmpty ? FontStyle.italic : FontStyle.normal,
                    color: _computedCatatan.isEmpty ? Colors.grey : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _submitListing,
              icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 20),
              label: const Text('Simpan ke Daftar Meeting', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(MeetingListing item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.idListing,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.status == 'Disetujui' || item.postingIg == 'true'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status == 'Disetujui' || item.postingIg == 'true' ? 'Disetujui' : item.status,
                  style: TextStyle(
                    color: item.status == 'Disetujui' || item.postingIg == 'true' ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.judul.isNotEmpty ? item.judul : (item.keterangan.isNotEmpty ? item.keterangan : 'Listing Properti Tanpa Judul'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(CupertinoIcons.person_fill, size: 14, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text(
                'ME: ${item.namaMe.isNotEmpty ? item.namaMe : "-"}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              if (item.lokasi.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.location_solid, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  item.lokasi,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
              if (item.harga.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.money_dollar_circle_fill, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  item.harga,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                ),
              ],
            ],
          ),
          if (item.catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${item.catatan}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFF25D366), size: 22),
                tooltip: 'Kirim via WhatsApp',
                onPressed: () {
                  final text = WhatsAppFormatter.formatWeeklyMeetingBroadcast(
                    idListing: item.idListing,
                    namaMe: item.namaMe,
                    judul: item.judul.isNotEmpty ? item.judul : item.keterangan,
                    harga: item.harga,
                    catatan: item.catatan,
                    status: item.status,
                  );
                  WhatsAppFormatter.sendWhatsAppMessage(phoneNumber: '', message: text);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
