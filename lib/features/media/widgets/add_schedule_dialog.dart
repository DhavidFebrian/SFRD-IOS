import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/state/app_state_provider.dart';
import '../../publish/models/publish_item.dart';
import '../models/schedule.dart';

class AddScheduleDialog extends StatelessWidget {
  final Schedule? existingSchedule;

  const AddScheduleDialog({
    super.key,
    this.existingSchedule,
  });

  static Future<bool?> show(
    BuildContext context, {
    Schedule? existingSchedule,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.65,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.borderDark, width: 1.2),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: InputFormView(
                  existingSchedule: existingSchedule,
                  scrollController: scrollController,
                  isModal: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 740),
        child: InputFormView(
          existingSchedule: existingSchedule,
          isModal: true,
        ),
      ),
    );
  }
}

class InputFormScreen extends StatelessWidget {
  final Schedule? existingSchedule;
  final VoidCallback? onSaved;

  const InputFormScreen({
    super.key,
    this.existingSchedule,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: InputFormView(
          existingSchedule: existingSchedule,
          isModal: false,
          onSaved: onSaved,
        ),
      ),
    );
  }
}

class InputFormView extends StatefulWidget {
  final Schedule? existingSchedule;
  final ScrollController? scrollController;
  final bool isModal;
  final VoidCallback? onSaved;

  const InputFormView({
    super.key,
    this.existingSchedule,
    this.scrollController,
    this.isModal = false,
    this.onSaved,
  });

  @override
  State<InputFormView> createState() => _InputFormViewState();
}

class _InputFormViewState extends State<InputFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _namaMeController;
  late final TextEditingController _lokasiController;
  late final TextEditingController _manualStatusController;

  Timer? _scrapeDebounce;
  bool _isScrapingWeb = false;
  ScrapedListingDetail? _scrapedPreview;
  String? _autofillBannerMessage;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final Set<String> _selectedStaff = {'David'};
  String _selectedBaseType = 'Foto';
  bool _isDoneProgressType = false;

  bool _isSetDoneStatus = false; // true = "SET DONE", false = "Ketik Manual"
  bool _isSubmitting = false;

  static const List<String> _activityTypes = [
    'Foto',
    'Video',
    'Drone',
    'Foto & Video',
    'Foto, Video & Drone',
    'Foto Ulang',
  ];

  static const List<String> _quickManualStatuses = [
    'On Progress',
    'Pending',
    'Reschedule',
    'Cancel',
  ];

  bool get _isEditMode => widget.existingSchedule != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSchedule;

    _idController = TextEditingController(text: existing?.idListing ?? '');
    _namaMeController = TextEditingController(text: existing?.namaMe ?? '');
    _lokasiController = TextEditingController(text: existing?.lokasi ?? '');

    // Parse Date
    final parsedDate =
        existing != null ? parseIndonesianDate(existing.tanggal) : null;
    _selectedDate = parsedDate ?? DateTime.now();

    // Parse Time
    _selectedTime = _parseTime(existing?.jam ?? '10:00');

    // Parse Staff
    if (existing != null && existing.staff.trim().isNotEmpty) {
      _selectedStaff.clear();
      final lowerStaff = existing.staff.toLowerCase();
      if (lowerStaff.contains('david')) _selectedStaff.add('David');
      if (lowerStaff.contains('alan')) _selectedStaff.add('Alan');
      if (_selectedStaff.isEmpty) {
        final parts = existing.staff
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        _selectedStaff.addAll(parts);
      }
    }

    // Parse Activity Type & Done Progress
    if (existing != null && existing.type.trim().isNotEmpty) {
      final rawType = existing.type.trim();
      if (rawType.toLowerCase().startsWith('done ')) {
        _isDoneProgressType = true;
        final stripped = rawType.substring(5).trim();
        if (_activityTypes.contains(stripped)) {
          _selectedBaseType = stripped;
        }
      } else if (_activityTypes.contains(rawType)) {
        _selectedBaseType = rawType;
      }
    }

    // Parse Status
    final rawStatus = existing?.status.trim() ?? 'On Progress';
    if (rawStatus.toLowerCase() == 'done' ||
        rawStatus.toLowerCase() == 'selesai') {
      _isSetDoneStatus = true;
      _manualStatusController = TextEditingController(text: 'On Progress');
    } else {
      _isSetDoneStatus = false;
      _manualStatusController = TextEditingController(
        text: rawStatus.isNotEmpty ? rawStatus : 'On Progress',
      );
    }

    if (_idController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerWebAutofill(_idController.text.trim(), isInitial: true);
      });
    }
  }

  TimeOfDay _parseTime(String raw) {
    final m = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw.trim());
    if (m != null) {
      var h = int.tryParse(m.group(1)!) ?? 10;
      final min = int.tryParse(m.group(2)!) ?? 0;
      if (raw.toLowerCase().contains('pm') && h < 12) h += 12;
      if (raw.toLowerCase().contains('am') && h == 12) h = 0;
      return TimeOfDay(hour: h.clamp(0, 23), minute: min.clamp(0, 59));
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _scrapeDebounce?.cancel();
    _idController.dispose();
    _namaMeController.dispose();
    _lokasiController.dispose();
    _manualStatusController.dispose();
    super.dispose();
  }

  String _formatDateIndonesian(DateTime date) {
    final monthName = kIndonesianMonths[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  String _formatTime24Hour(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _onIdListingChanged(String value) {
    _scrapeDebounce?.cancel();
    final cleanId = RwcScraperService.extractCleanId(value);
    if (cleanId.length < 3) {
      setState(() {
        _scrapedPreview = null;
        _isScrapingWeb = false;
        _autofillBannerMessage = null;
      });
      return;
    }

    _scrapeDebounce = Timer(const Duration(milliseconds: 550), () {
      _triggerWebAutofill(cleanId);
    });
  }

  Future<void> _triggerWebAutofill(
    String idInput, {
    bool isInitial = false,
  }) async {
    final cleanId = RwcScraperService.extractCleanId(idInput);
    if (cleanId.isEmpty || !mounted) return;

    final state = context.read<AppStateProvider>();
    final cached = state.getListingDetail(cleanId);
    if (cached != null) {
      _applyScrapedDetail(cached, isInitial: isInitial);
    }

    setState(() => _isScrapingWeb = true);
    final detail = await state.fetchListingDetails(cleanId);
    if (!mounted) return;

    setState(() => _isScrapingWeb = false);
    if (detail != null) {
      _applyScrapedDetail(detail, isInitial: isInitial);
    }
  }

  void _applyScrapedDetail(
    ScrapedListingDetail detail, {
    bool isInitial = false,
  }) {
    if (!mounted) return;
    final filledFields = <String>[];

    if (!isInitial) {
      final resolvedMe = resolveWebAutofillValue(
        _namaMeController.text,
        detail.agentName,
      );
      if (resolvedMe != null) {
        _namaMeController.text = resolvedMe;
        filledFields.add('Nama ME');
      }

      final resolvedLokasi = resolveWebAutofillValue(
        _lokasiController.text,
        detail.lokasi,
      );
      if (resolvedLokasi != null) {
        _lokasiController.text = resolvedLokasi;
        filledFields.add('Lokasi');
      }
    }

    setState(() {
      _scrapedPreview = detail;
      if (filledFields.isNotEmpty) {
        _autofillBannerMessage =
            'Autofill Web mengisi: ${filledFields.join(" & ")}';
      }
    });
  }

  Future<void> _openScanIdHelper() async {
    final scannedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _ScanListingIdSheet(),
    );

    if (scannedId != null && scannedId.trim().isNotEmpty && mounted) {
      _idController.text = scannedId.trim();
      _triggerWebAutofill(scannedId.trim());
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.surfaceDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.surfaceDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final state = context.read<AppStateProvider>();

    final staffJoined =
        _selectedStaff.isEmpty ? 'David' : _selectedStaff.join(', ');
    final finalType = _isDoneProgressType
        ? 'Done $_selectedBaseType'
        : _selectedBaseType;
    final finalStatus = _isSetDoneStatus
        ? 'Done'
        : (_manualStatusController.text.trim().isEmpty
            ? 'On Progress'
            : _manualStatusController.text.trim());

    final formattedDate = _formatDateIndonesian(_selectedDate);
    final formattedTime = _formatTime24Hour(_selectedTime);

    bool success;
    if (_isEditMode) {
      final updated = widget.existingSchedule!.copyWith(
        idListing: _idController.text.trim(),
        namaMe: _namaMeController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        tanggal: formattedDate,
        jam: formattedTime,
        staff: staffJoined,
        type: finalType,
        status: finalStatus,
      );
      success = await state.updateSchedule(updated);
    } else {
      final newSchedule = Schedule(
        idListing: _idController.text.trim(),
        namaMe: _namaMeController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        tanggal: formattedDate,
        jam: formattedTime,
        staff: staffJoined,
        type: finalType,
        status: finalStatus,
        sheetName: state.selectedMonth,
      );
      success = await state.addSchedule(newSchedule);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        content: Text(
          success
              ? (_isEditMode
                  ? 'Jadwal berhasil diperbarui!'
                  : 'Jadwal baru berhasil disimpan!')
              : 'Tersimpan secara lokal (Menunggu sinkronisasi Sheets)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );

    widget.onSaved?.call();
    if (widget.isModal && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final themeStyle = state.selectedThemeStyle;

    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          // Top Title & Autofill Badge Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeStyle.primary.withValues(alpha: 0.25),
                      themeStyle.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: themeStyle.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  _isEditMode
                      ? CupertinoIcons.pencil_outline
                      : CupertinoIcons.calendar_badge_plus,
                  color: themeStyle.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode ? 'Edit Jadwal Media' : 'Tambah Jadwal Foto',
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sheet aktif: ${state.selectedMonth}',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isModal)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Colors.white38,
                    size: 24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Autofill Cerdas Aktif Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.glowBlue.withValues(alpha: 0.18),
                  AppColors.glowPurple.withValues(alpha: 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.glowBlue.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _autofillBannerMessage ??
                        'Autofill Cerdas Aktif ✨ — Ketik ID Listing untuk tarik data web RWC otomatis',
                    style: const TextStyle(
                      color: Color(0xFFBAE6FD),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isScrapingWeb)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.glowBlue,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ID Listing + Scan ID Button
          _buildFieldLabel('ID Listing *'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _idController,
                  onChanged: _onIdListingChanged,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Contoh: 50124 / #50124',
                    prefixIcon: CupertinoIcons.number,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'ID Listing wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openScanIdHelper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    foregroundColor: AppColors.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.viewfinder, size: 18),
                  label: const Text(
                    'Scan ID',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Live Scraped Listing Preview Card
          if (_scrapedPreview != null) ...[
            const SizedBox(height: 12),
            _buildScrapedPreviewCard(_scrapedPreview!),
          ],
          const SizedBox(height: 14),

          // Nama ME
          _buildFieldLabel('Nama ME (Marketing Executive) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _namaMeController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Terisi otomatis dari web atau ketik nama ME',
              prefixIcon: CupertinoIcons.person_fill,
              suffixIcon: _namaMeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 16,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _namaMeController.clear()),
                    )
                  : null,
            ),
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Nama ME wajib diisi'
                : null,
          ),
          const SizedBox(height: 14),

          // Lokasi
          _buildFieldLabel('Lokasi Properti'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _lokasiController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Contoh: Cipete, Pondok Indah, Kemang...',
              prefixIcon: CupertinoIcons.location_solid,
              suffixIcon: _lokasiController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 16,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _lokasiController.clear()),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Tanggal & Jam Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Tanggal Kegiatan'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.calendar,
                              size: 17,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDateIndonesian(_selectedDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Jam'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.clock_fill,
                              size: 17,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime24Hour(_selectedTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-select Staff Checkboxes (David, Alan)
          _buildFieldLabel('Staff Bertugas (Bisa pilih lebih dari 1)'),
          const SizedBox(height: 6),
          Row(
            children: ['David', 'Alan'].map((staffName) {
              final isChecked = _selectedStaff.contains(staffName);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: staffName == 'David' ? 8 : 0,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked && _selectedStaff.length > 1) {
                          _selectedStaff.remove(staffName);
                        } else if (!isChecked) {
                          _selectedStaff.add(staffName);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? themeStyle.primary.withValues(alpha: 0.18)
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isChecked
                              ? themeStyle.primary
                              : AppColors.borderDark,
                          width: isChecked ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isChecked
                                ? CupertinoIcons.checkmark_square_fill
                                : CupertinoIcons.square,
                            color: isChecked
                                ? themeStyle.primary
                                : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            staffName,
                            style: TextStyle(
                              color: isChecked ? Colors.white : Colors.white70,
                              fontWeight: isChecked
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Tipe Kegiatan Dropdown + Done Progress Checkbox
          _buildFieldLabel('Tipe Kegiatan'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedBaseType,
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(
              hint: 'Pilih Tipe Kegiatan',
              prefixIcon: CupertinoIcons.camera_fill,
            ),
            items: _activityTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedBaseType = val);
              }
            },
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () =>
                setState(() => _isDoneProgressType = !_isDoneProgressType),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isDoneProgressType
                    ? AppColors.success.withValues(alpha: 0.14)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isDoneProgressType
                      ? AppColors.success
                      : AppColors.borderDark,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isDoneProgressType
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: _isDoneProgressType
                        ? AppColors.success
                        : Colors.white38,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Done Progress (Tandai tipe sebagai "Done $_selectedBaseType")',
                      style: TextStyle(
                        color: _isDoneProgressType
                            ? Colors.white
                            : AppColors.textSecondaryDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2-option Status Selector: "SET DONE" vs "Ketik Manual"
          _buildFieldLabel('Status Jadwal'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildStatusModeChip(
                  title: 'SET DONE',
                  subtitle: 'Selesai Foto',
                  icon: CupertinoIcons.checkmark_seal_fill,
                  isSelected: _isSetDoneStatus,
                  activeColor: AppColors.success,
                  onTap: () => setState(() => _isSetDoneStatus = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusModeChip(
                  title: 'Ketik Manual',
                  subtitle: 'On Progress / Pending',
                  icon: CupertinoIcons.pencil_circle_fill,
                  isSelected: !_isSetDoneStatus,
                  activeColor: AppColors.warning,
                  onTap: () => setState(() => _isSetDoneStatus = false),
                ),
              ),
            ],
          ),

          if (!_isSetDoneStatus) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _manualStatusController,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: _inputDecoration(
                hint: 'Ketik status (mis. On Progress, Pending, Cancel)',
                prefixIcon: CupertinoIcons.tag_fill,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickManualStatuses.map((statusOption) {
                final selected = _manualStatusController.text
                        .trim()
                        .toLowerCase() ==
                    statusOption.toLowerCase();
                return InkWell(
                  onTap: () => setState(
                    () => _manualStatusController.text = statusOption,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.warning.withValues(alpha: 0.22)
                          : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.warning
                            : AppColors.borderDark,
                      ),
                    ),
                    child: Text(
                      statusOption,
                      style: TextStyle(
                        color: selected
                            ? AppColors.warning
                            : AppColors.textSecondaryDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeStyle.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(
                      _isEditMode
                          ? CupertinoIcons.checkmark_alt_circle_fill
                          : CupertinoIcons.paperplane_fill,
                      size: 19,
                    ),
              label: Text(
                _isSubmitting
                    ? 'Menyimpan ke Google Sheets...'
                    : (_isEditMode ? 'Simpan Perubahan' : 'Simpan Jadwal Baru'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrapedPreviewCard(ScrapedListingDetail detail) {
    final hasImage =
        detail.primaryImageUrl != null && detail.primaryImageUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: detail.isSold
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.glowBlue.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 68,
              height: 68,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: detail.primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceDark,
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: Colors.white30,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceDark,
                      child: const Icon(
                        CupertinoIcons.house_fill,
                        color: Colors.white38,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rwcYellow,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '#${detail.cleanId}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detail.price,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail.title.isNotEmpty
                      ? detail.title
                      : 'Listing #${detail.cleanId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'ME: ${detail.agentName.isNotEmpty ? detail.agentName : "-"} • Lokasi: ${detail.lokasi.isNotEmpty ? detail.lokasi : "-"}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusModeChip({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.16)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.accent),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceDark,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    );
  }
}

class _ScanListingIdSheet extends StatefulWidget {
  const _ScanListingIdSheet();

  @override
  State<_ScanListingIdSheet> createState() => _ScanListingIdSheetState();
}

class _ScanListingIdSheetState extends State<_ScanListingIdSheet> {
  final TextEditingController _numController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;
  String? _scanFeedback;

  @override
  void dispose() {
    _numController.dispose();
    super.dispose();
  }

  Future<void> _scanFromImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;

      setState(() {
        _isProcessingImage = true;
        _scanFeedback = 'Mengekstrak angka ID Listing dari gambar...';
      });

      final inputImage = InputImage.fromFilePath(picked.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final match = RegExp(r'\b\d{4,7}\b').firstMatch(recognized.text);
      if (!mounted) return;

      if (match != null) {
        final foundId = match.group(0)!;
        _numController.text = foundId;
        setState(() {
          _isProcessingImage = false;
          _scanFeedback = 'ID Listing #$foundId terdeteksi!';
        });
      } else {
        setState(() {
          _isProcessingImage = false;
          _scanFeedback =
              'Tidak ditemukan angka ID 4-7 digit. Silakan gunakan keypad di bawah.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingImage = false;
        _scanFeedback = 'Kamera tidak tersedia pada perangkat ini. Gunakan keypad cepat.';
      });
    }
  }

  void _appendDigit(String d) {
    setState(() {
      _numController.text = '${_numController.text}$d';
    });
  }

  void _backspace() {
    if (_numController.text.isEmpty) return;
    setState(() {
      _numController.text =
          _numController.text.substring(0, _numController.text.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                CupertinoIcons.viewfinder_circle_fill,
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Scan / Input Cepat ID Listing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.xmark, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessingImage
                      ? null
                      : () => _scanFromImage(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.camera_fill, size: 16),
                  label: const Text('Kamera OCR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessingImage
                      ? null
                      : () => _scanFromImage(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.photo_fill, size: 16),
                  label: const Text('Dari Galeri'),
                ),
              ),
            ],
          ),
          if (_scanFeedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _scanFeedback!,
              style: const TextStyle(
                color: AppColors.accentLight,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const Text(
                  '#',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _numController.text.isEmpty
                        ? 'Ketik angka ID...'
                        : _numController.text,
                    style: TextStyle(
                      color: _numController.text.isEmpty
                          ? Colors.white30
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _backspace,
                  icon: const Icon(
                    CupertinoIcons.delete_left_fill,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                _buildKeypadButton(d, () => _appendDigit(d)),
              _buildKeypadButton('C', () => setState(() => _numController.clear())),
              _buildKeypadButton('0', () => _appendDigit('0')),
              ElevatedButton(
                onPressed: _numController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_numController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'PAKAI',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.cardDark,
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
