import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/whatsapp_formatter.dart';
import '../models/meeting_listing.dart';

class WeeklyMeetingScreen extends StatefulWidget {
  const WeeklyMeetingScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyMeetingScreen> createState() => _WeeklyMeetingScreenState();
}

class _WeeklyMeetingScreenState extends State<WeeklyMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _namaMeController = TextEditingController();
  final _judulController = TextEditingController();
  final _hargaController = TextEditingController();
  final _catatanManualController = TextEditingController();

  final Set<String> _selectedEditOptions = {};
  String _selectedStatus = 'Review';

  final List<String> _addTemplates = ['ratio', 'perspective', 'remove object', 'revisi harga', 'foto ulang'];

  final List<MeetingListing> _mockListings = [
    MeetingListing(
      id: '1',
      idListing: 'LST-8901',
      namaMe: 'David Febrian',
      judul: 'Rumah Mewah Minimalis 2 Lantai Araya',
      harga: 'Rp 2.850.000.000',
      catatan: 'edit ratio, judul Rumah Mewah Araya, siap promo IG',
      status: 'Disetujui',
    ),
    MeetingListing(
      id: '2',
      idListing: 'LST-8902',
      namaMe: 'Sarah Wijaya',
      judul: 'Ruko Strategis Siap Huni Soekarno Hatta',
      harga: 'Rp 1.900.000.000',
      catatan: 'edit remove object, revisi harga',
      status: 'Review',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _idController.addListener(_onIdChanged);
  }

  @override
  void dispose() {
    _idController.dispose();
    _namaMeController.dispose();
    _judulController.dispose();
    _hargaController.dispose();
    _catatanManualController.dispose();
    super.dispose();
  }

  void _onIdChanged() {
    final cleanId = _idController.text.trim();
    if (cleanId.length >= 3) {
      // Mock Autofill Nama ME berdasarkan prefix ID (seperti di Android Kotlin)
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

  void _submitListing() {
    if (_idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Listing wajib diisi!')),
      );
      return;
    }

    final newListing = MeetingListing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idListing: _idController.text.trim(),
      namaMe: _namaMeController.text.trim(),
      judul: _judulController.text.trim(),
      harga: _hargaController.text.trim(),
      catatan: _computedCatatan,
      status: _selectedStatus,
    );

    setState(() {
      _mockListings.insert(0, newListing);
      _idController.clear();
      _namaMeController.clear();
      _judulController.clear();
      _hargaController.clear();
      _catatanManualController.clear();
      _selectedEditOptions.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listing Weekly Meeting berhasil ditambahkan!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meeting', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share),
            tooltip: 'Bagikan Rekap',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mengekspor data rekap meeting...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Form Input Listing
          _buildFormCard(),
          const SizedBox(height: 24),

          // Header List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Listing (${_mockListings.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _mockListings.clear());
                },
                icon: const Icon(CupertinoIcons.trash, size: 16, color: AppColors.error),
                label: const Text('Bersihkan', style: TextStyle(color: AppColors.error, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 12),

          // Listing Cards
          ..._mockListings.map((item) => _buildListingCard(item)).toList(),
        ],
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
                    hintText: 'Misal: LST-01',
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

          // Judul & Harga
          TextField(
            controller: _judulController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Judul Properti',
              hintText: 'Contoh: Rumah Minimalis Modern Dekat Kampus',
              prefixIcon: Icon(CupertinoIcons.house, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _hargaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga / Nilai',
              hintText: 'Misal: Rp 1.500.000.000',
              prefixIcon: Icon(CupertinoIcons.money_dollar, size: 18),
            ),
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
                  color: item.status == 'Disetujui' ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: item.status == 'Disetujui' ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.judul.isNotEmpty ? item.judul : 'Listing Properti Tanpa Judul',
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
              const SizedBox(width: 16),
              const Icon(CupertinoIcons.money_dollar_circle_fill, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                item.harga.isNotEmpty ? item.harga : "-",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
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
                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 20),
                tooltip: 'Kirim via WhatsApp',
                onPressed: () {
                  final text = WhatsAppFormatter.formatWeeklyMeetingBroadcast(
                    idListing: item.idListing,
                    namaMe: item.namaMe,
                    judul: item.judul,
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
