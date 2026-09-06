import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/state/app_state_provider.dart';
import '../models/schedule.dart';

class AddScheduleDialog extends StatefulWidget {
  const AddScheduleDialog({Key? key}) : super(key: key);

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _namaMeController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _staffController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedType = 'Foto';
  String _selectedStatus = 'Pending';
  bool _isSubmitting = false;

  final List<String> _types = ['Foto', 'Video', 'Foto Ulang', 'Drone', 'Liputan'];
  final List<String> _statuses = ['Pending', 'Done'];

  @override
  void dispose() {
    _idController.dispose();
    _namaMeController.dispose();
    _lokasiController.dispose();
    _staffController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minuteStr';

    final state = Provider.of<AppStateProvider>(context, listen: false);

    final newSchedule = Schedule(
      idListing: _idController.text.trim(),
      namaMe: _namaMeController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      tanggal: dateStr,
      jam: timeStr,
      staff: _staffController.text.trim(),
      type: _selectedType,
      status: _selectedStatus,
      sheetName: state.selectedMonth,
    );

    final success = await state.addSchedule(newSchedule);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Jadwal berhasil ditambahkan ke Google Sheets!'
              : 'Jadwal disimpan lokal (cek koneksi Google Sheets)'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE600),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.calendar_badge_plus, color: Color(0xFF2B2D42), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Tambah Jadwal Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID Listing *',
                  hintText: 'Misal: L-0912',
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
                  labelText: 'Nama ME (Marketing Executive) *',
                  hintText: 'Misal: Donny, Dian, Vincent',
                  prefixIcon: Icon(CupertinoIcons.person),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama ME wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Alamat',
                  hintText: 'Misal: Jl. Fatmawati No. 10',
                  prefixIcon: Icon(CupertinoIcons.location_solid),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _staffController,
                decoration: const InputDecoration(
                  labelText: 'Staff Fotografer',
                  hintText: 'Misal: Dhavid / Tim Media',
                  prefixIcon: Icon(CupertinoIcons.camera),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Kegiatan',
                    prefixIcon: Icon(CupertinoIcons.calendar),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(formattedDate),
                ),
              ),
              const SizedBox(height: 12),

              // Time Picker
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Kegiatan',
                    prefixIcon: Icon(CupertinoIcons.clock),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(_selectedTime.format(context)),
                ),
              ),
              const SizedBox(height: 12),

              // Type & Status Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
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
              : const Text('Simpan Jadwal'),
        ),
      ],
    );
  }
}
