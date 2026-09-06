import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/state/app_state_provider.dart';

class AddMeetingListingDialog extends StatefulWidget {
  final String? initialDate;

  const AddMeetingListingDialog({Key? key, this.initialDate}) : super(key: key);

  @override
  State<AddMeetingListingDialog> createState() => _AddMeetingListingDialogState();
}

class _AddMeetingListingDialogState extends State<AddMeetingListingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _namaMeController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _catatanController = TextEditingController();
  final _lokasiController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final List<String> _keteranganChips = [
    'Hot Property',
    'Foto Ulang',
    'IG Post',
    'Komersil',
    'Sewa',
    'Rumah Mewah',
    'Tanah',
  ];

  final List<String> _lokasiChips = [
    'Cipete',
    'Kemang',
    'Cilandak',
    'Pondok Indah',
    'Fatmawati',
    'Antasari',
    'Jagakarsa',
  ];

  final List<String> _catatanChips = [
    'Siap Tayang',
    'Perlu Foto Ulang',
    'Price Drop',
    'Eksklusif',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.initialDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _namaMeController.dispose();
    _keteranganController.dispose();
    _catatanController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  void _appendChip(TextEditingController controller, String text) {
    final current = controller.text.trim();
    if (current.isEmpty) {
      controller.text = text;
    } else if (!current.contains(text)) {
      controller.text = '$current, $text';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final state = Provider.of<AppStateProvider>(context, listen: false);

    final success = await state.addMeetingListing(
      idListing: _idController.text.trim(),
      namaMe: _namaMeController.text.trim(),
      keterangan: _keteranganController.text.trim(),
      catatan: _catatanController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      date: dateStr,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Agenda listing meeting berhasil ditambahkan!'
              : 'Gagal menambahkan ke Google Sheets, periksa koneksi'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE600),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.person_3_fill, color: Color(0xFF2B2D42), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Tambah Listing Meeting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID Listing *',
                    hintText: 'Misal: L-2241',
                    prefixIcon: Icon(CupertinoIcons.number),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'ID Listing wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _namaMeController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Marketing Executive (ME) *',
                    hintText: 'Misal: Pak Donny / Ibu Dian',
                    prefixIcon: Icon(CupertinoIcons.person),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama ME wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Lokasi
                TextFormField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Properti',
                    hintText: 'Misal: Cipete Selatan',
                    prefixIcon: Icon(CupertinoIcons.location_solid),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _lokasiChips.map((lok) {
                    return ActionChip(
                      label: Text(lok, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () => _appendChip(_lokasiController, lok),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Keterangan
                TextFormField(
                  controller: _keteranganController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan / Tipe Listing',
                    hintText: 'Misal: Hot Property, IG Post',
                    prefixIcon: Icon(CupertinoIcons.tag_solid),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _keteranganChips.map((chip) {
                    return ActionChip(
                      label: Text(chip, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () => _appendChip(_keteranganController, chip),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Catatan
                TextFormField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Rapat / Tim',
                    hintText: 'Misal: Siap Tayang, Jadwal Foto Ulang',
                    prefixIcon: Icon(CupertinoIcons.pencil_ellipsis_rectangle),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _catatanChips.map((cat) {
                    return ActionChip(
                      label: Text(cat, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () => _appendChip(_catatanController, cat),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2B2D42),
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan Data'),
        ),
      ],
    );
  }
}
