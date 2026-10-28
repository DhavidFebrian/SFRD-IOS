import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/agent_contact.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/services/sheets_service.dart';
import '../../../core/state/app_state_provider.dart';
import '../../media/models/schedule.dart';
import '../../publish/models/publish_item.dart';
import '../models/meeting_listing.dart';

class AddMeetingListingDialog extends StatefulWidget {
  final MeetingListing? existingListing;

  const AddMeetingListingDialog({
    super.key,
    this.existingListing,
  });

  static Future<bool?> show(
    BuildContext context, {
    MeetingListing? existingListing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMeetingListingDialog(existingListing: existingListing),
    );
  }

  @override
  State<AddMeetingListingDialog> createState() => _AddMeetingListingDialogState();
}

class _AddMeetingListingDialogState extends State<AddMeetingListingDialog> {
  static const List<String> _categoryOptions = [
    'HOT PROPERTY',
    'FOTO ULANG',
    'IG',
  ];

  static const List<String> _editTemplateChips = [
    'Ratio 4:5',
    'Persp. Fix',
    'Rem Obj',
    'Bright+',
    'Sky Repl',
  ];

  late final TextEditingController _idController;
  late final TextEditingController _dateController;
  late final TextEditingController _namaMeController;
  late final TextEditingController _lokasiController;
  late final TextEditingController _judulIgController;
  late final TextEditingController _catatanController;

  final Set<String> _selectedCategories = {};
  bool _createFotoUlangSchedule = false;
  String _fotoUlangStaff = 'David';
  String _fotoUlangType = 'Foto Ulang';

  Timer? _scrapeDebounce;
  bool _isScraping = false;
  bool _isSaving = false;
  ScrapedListingDetail? _scrapedDetail;

  bool get _isEditMode => widget.existingListing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingListing;
    final state = context.read<AppStateProvider>();

    _idController = TextEditingController(text: existing?.idListing ?? '');
    final defaultDate = existing?.date.isNotEmpty == true
        ? existing!.date
        : (state.selectedMeetingDate ??
            (state.availableMeetingDates.isNotEmpty
                ? state.availableMeetingDates.last
                : formatIsoDate(DateTime.now())));
    _dateController = TextEditingController(text: defaultDate);
    _namaMeController = TextEditingController(text: existing?.namaMe ?? '');
    _lokasiController = TextEditingController(text: existing?.lokasi ?? '');

    final rawNotes = existing?.catatan ?? '';
    final extractedJudul = extractJudulFromNotes(rawNotes) ?? existing?.judul ?? '';
    _judulIgController = TextEditingController(text: extractedJudul);

    final cleanedNotes = rawNotes
        .replaceAll(RegExp(r'\[Judul:\s*[^\]]*\]\s*', caseSensitive: false), '')
        .trim();
    _catatanController = TextEditingController(text: cleanedNotes);

    if (existing != null && existing.keterangan.trim().isNotEmpty) {
      final upper = existing.keterangan.toUpperCase();
      if (upper.contains('HOT')) _selectedCategories.add('HOT PROPERTY');
      if (upper.contains('FOTO ULANG') || upper.contains('ULANG')) {
        _selectedCategories.add('FOTO ULANG');
      }
      if (upper.contains('IG') || upper.contains('INSTAGRAM')) {
        _selectedCategories.add('IG');
      }
    } else {
      _selectedCategories.add('IG');
    }

    if (_idController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerWebScrape(_idController.text.trim());
      });
    }
  }

  @override
  void dispose() {
    _scrapeDebounce?.cancel();
    _idController.dispose();
    _dateController.dispose();
    _namaMeController.dispose();
    _lokasiController.dispose();
    _judulIgController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _onIdChanged(String value) {
    _scrapeDebounce?.cancel();
    final clean = RwcScraperService.extractCleanId(value);
    if (clean.length < 3) {
      setState(() => _scrapedDetail = null);
      return;
    }
    _scrapeDebounce = Timer(const Duration(milliseconds: 550), () {
      _triggerWebScrape(clean);
    });
  }

  Future<void> _triggerWebScrape(String rawId, {bool force = false}) async {
    final cleanId = RwcScraperService.extractCleanId(rawId);
    if (cleanId.isEmpty) return;

    setState(() => _isScraping = true);
    final state = context.read<AppStateProvider>();
    final detail = await state.fetchListingDetails(cleanId, force: force);
    if (!mounted) return;

    setState(() {
      _isScraping = false;
      _scrapedDetail = detail;
    });

    if (detail != null && !detail.isSold) {
      // Strict web-only autofill using resolveWebAutofillValue
      final resolvedMe = resolveWebAutofillValue(
        _namaMeController.text,
        detail.agentName,
      );
      if (resolvedMe != null) {
        _namaMeController.text = formatAgentName(resolvedMe);
      }

      final resolvedLoc = resolveWebAutofillValue(
        _lokasiController.text,
        detail.lokasi,
      );
      if (resolvedLoc != null) {
        _lokasiController.text = resolvedLoc;
      }

      if (_judulIgController.text.trim().isEmpty && detail.title.isNotEmpty) {
        _judulIgController.text = detail.title;
      }
      setState(() {});
    }
  }

  Future<void> _scanListingIdFromCamera() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final match = RegExp(r'\b\d{4,6}\b').firstMatch(recognized.text);
      if (match != null && mounted) {
        final foundId = match.group(0)!;
        _idController.text = foundId;
        await _triggerWebScrape(foundId, force: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ditemukan angka ID Listing (4-6 digit) pada foto.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memindai ID: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _appendEditTemplate(String chipText) {
    final current = _catatanController.text.trim();
    if (current.toLowerCase().contains(chipText.toLowerCase())) return;
    setState(() {
      _catatanController.text = current.isEmpty ? chipText : '$current, $chipText';
    });
  }

  String _composeFinalCatatan() {
    final baseNotes = _catatanController.text.trim();
    final isIgSelected = _selectedCategories.contains('IG');
    final judul = _judulIgController.text.trim();
    if (isIgSelected && judul.isNotEmpty) {
      return baseNotes.isEmpty ? '[Judul: $judul]' : '[Judul: $judul] $baseNotes';
    }
    return baseNotes;
  }

  Future<void> _pickMeetingDate() async {
    final initial = parseIndonesianDate(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')} ${kIndonesianMonths[picked.month - 1]} ${picked.year}';
      });
    }
  }

  Future<void> _handleSave() async {
    final idListing = _idController.text.trim();
    final namaMe = _namaMeController.text.trim();
    final lokasi = _lokasiController.text.trim();
    final date = _dateController.text.trim();

    if (idListing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Listing wajib diisi!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final keterangan = _selectedCategories.isEmpty
        ? 'IG'
        : _selectedCategories.join(', ');
    final finalCatatan = _composeFinalCatatan();

    setState(() => _isSaving = true);
    final state = context.read<AppStateProvider>();

    bool ok = false;
    if (_isEditMode) {
      ok = await state.updateMeetingListingDetails(
        original: widget.existingListing!,
        idListing: idListing,
        namaMe: namaMe.isNotEmpty ? namaMe : 'Ray White Cipete',
        keterangan: keterangan,
        catatan: finalCatatan,
        lokasi: lokasi,
      );
    } else {
      ok = await state.addMeetingListing(
        idListing: idListing,
        namaMe: namaMe.isNotEmpty ? namaMe : 'Ray White Cipete',
        keterangan: keterangan,
        catatan: finalCatatan,
        lokasi: lokasi,
        date: date.isNotEmpty ? date : formatIsoDate(DateTime.now()),
      );

      if (ok &&
          _selectedCategories.contains('FOTO ULANG') &&
          _createFotoUlangSchedule) {
        final schedule = Schedule(
          idListing: idListing,
          namaMe: namaMe.isNotEmpty ? namaMe : 'Ray White Cipete',
          lokasi: lokasi,
          tanggal: date.isNotEmpty ? date : formatIsoDate(DateTime.now()),
          jam: '10:00',
          staff: _fotoUlangStaff,
          type: _fotoUlangType,
          status: 'Non-Aktif',
          sheetName: 'Foto Ulang',
          source: 'Weekly Meeting',
        );
        await state.addSchedule(schedule);
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Listing #$idListing berhasil diperbarui!'
                : 'Listing #$idListing berhasil ditambahkan ke Weekly Meeting!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan ke Google Sheets. Coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final cleanId = RwcScraperService.extractCleanId(_idController.text);
    final igHistory = cleanId.isNotEmpty
        ? state.getIgHistoryForListing(cleanId)
        : <YearlyIgHistoryItem>[];
    final detail = _scrapedDetail ??
        (cleanId.isNotEmpty ? state.getListingDetail(cleanId) : null);
    final meetingDates = state.availableMeetingDates;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditMode
                          ? CupertinoIcons.pencil_circle_fill
                          : CupertinoIcons.plus_rectangle_fill_on_rectangle_fill,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode
                              ? 'Edit Listing Weekly Meeting'
                              : 'Tambah Listing Weekly Meeting',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sheet Aktif: ${state.selectedMonth}',
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderDark, height: 1),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ID Listing + Scan ID + Refresh Web
                    const Text(
                      'ID Listing Properti',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _idController,
                            onChanged: _onIdChanged,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Contoh: 11918',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: const Icon(
                                CupertinoIcons.number,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              suffixIcon: _isScraping
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      tooltip: 'Tarik Data Web',
                                      onPressed: () => _triggerWebScrape(
                                        _idController.text,
                                        force: true,
                                      ),
                                      icon: const Icon(
                                        CupertinoIcons.globe,
                                        color: AppColors.info,
                                        size: 18,
                                      ),
                                    ),
                              filled: true,
                              fillColor: AppColors.cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.borderDark),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight.withOpacity(0.18),
                            foregroundColor: AppColors.primaryLight,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: AppColors.primaryLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _scanListingIdFromCamera,
                          icon: const Icon(CupertinoIcons.camera_viewfinder, size: 18),
                          label: const Text(
                            'Scan ID',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),

                    // 2. IgPostingInfoCard (2026 IG Posting History)
                    if (cleanId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      IgPostingInfoCard(
                        cleanId: cleanId,
                        historyItems: igHistory,
                      ),
                    ],

                    // 3. Scraped Website Preview Card
                    if (detail != null) ...[
                      const SizedBox(height: 12),
                      _ScrapedListingPreviewCard(detail: detail),
                    ],

                    const SizedBox(height: 16),

                    // 4. Tanggal Meeting selector/input
                    const Text(
                      'Tanggal Meeting',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Pilih / ketik tanggal meeting',
                              hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                              prefixIcon: const Icon(
                                CupertinoIcons.calendar,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: AppColors.cardDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.borderDark),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.cardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.borderDark),
                            ),
                          ),
                          onPressed: _pickMeetingDate,
                          icon: const Icon(
                            CupertinoIcons.calendar_badge_plus,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    if (meetingDates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: meetingDates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final d = meetingDates[index];
                            final selected = _dateController.text.trim() == d;
                            return ActionChip(
                              backgroundColor: selected
                                  ? AppColors.accent
                                  : AppColors.cardDark,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.borderDark,
                              ),
                              label: Text(
                                d,
                                style: TextStyle(
                                  color: selected ? Colors.black : Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                setState(() => _dateController.text = d);
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 5. Nama ME & Lokasi (Strictly Web Autofilled or User Input)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nama ME (Web Autofill)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _namaMeController,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'Nama Marketing...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 12.5,
                                  ),
                                  prefixIcon: const Icon(
                                    CupertinoIcons.person_fill,
                                    color: AppColors.primaryLight,
                                    size: 17,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.borderDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lokasi (Web Autofill)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _lokasiController,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'Cipete, Kemang...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 12.5,
                                  ),
                                  prefixIcon: const Icon(
                                    CupertinoIcons.location_solid,
                                    color: AppColors.success,
                                    size: 17,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.borderDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 6. Category Selector Cards (HOT PROPERTY, FOTO ULANG, IG)
                    const Text(
                      'Kategori Pembahasan (Bisa Pilih > 1)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _categoryOptions.map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
                        final color = switch (cat) {
                          'HOT PROPERTY' => AppColors.hotProperty,
                          'FOTO ULANG' => AppColors.fotoUlangBlue,
                          _ => AppColors.igPink,
                        };
                        final icon = switch (cat) {
                          'HOT PROPERTY' => CupertinoIcons.flame_fill,
                          'FOTO ULANG' => CupertinoIcons.camera_rotate_fill,
                          _ => CupertinoIcons.sparkles,
                        };

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: cat == _categoryOptions.last ? 0 : 8,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  if (isSelected && _selectedCategories.length > 1) {
                                    _selectedCategories.remove(cat);
                                  } else {
                                    _selectedCategories.add(cat);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withOpacity(0.22)
                                      : AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? color : AppColors.borderDark,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected ? color : Colors.white54,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.5,
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

                    // 7. Conditional FOTO ULANG Section
                    if (_selectedCategories.contains('FOTO ULANG') && !_isEditMode) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.fotoUlangBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.fotoUlangBlue.withOpacity(0.45),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.camera_rotate_fill,
                                  color: AppColors.fotoUlangBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Sinkronisasi ke Jadwal Foto Ulang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _createFotoUlangSchedule,
                                  activeColor: AppColors.fotoUlangBlue,
                                  onChanged: (v) {
                                    setState(() => _createFotoUlangSchedule = v);
                                  },
                                ),
                              ],
                            ),
                            if (_createFotoUlangSchedule) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _fotoUlangStaff,
                                      dropdownColor: AppColors.cardDark,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Staff Foto',
                                        labelStyle: const TextStyle(
                                          color: AppColors.textSecondaryDark,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: AppColors.surfaceDark,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'David', child: Text('David')),
                                        DropdownMenuItem(value: 'Alan', child: Text('Alan')),
                                        DropdownMenuItem(value: 'Raffa', child: Text('Raffa')),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _fotoUlangStaff = v);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _fotoUlangType,
                                      dropdownColor: AppColors.cardDark,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Tipe Kunjungan',
                                        labelStyle: const TextStyle(
                                          color: AppColors.textSecondaryDark,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: AppColors.surfaceDark,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Foto Ulang',
                                          child: Text('Foto Ulang'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Foto & Video Ulang',
                                          child: Text('Foto & Video Ulang'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _fotoUlangType = v);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // 8. Conditional IG Section (Judul Konten & Template Catatan Edit Foto)
                    if (_selectedCategories.contains('IG')) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.igPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.igPink.withOpacity(0.45),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.sparkles,
                                  color: AppColors.igPink,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Konfigurasi Konten Instagram (IG)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _judulIgController,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5),
                              decoration: InputDecoration(
                                labelText: 'Judul Konten / Headline IG',
                                labelStyle: const TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 12.5,
                                ),
                                hintText: 'Disimpan sebagai [Judul: ...]',
                                hintStyle: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Template Catatan Edit Foto:',
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _editTemplateChips.map((chip) {
                                return ActionChip(
                                  backgroundColor: AppColors.surfaceDark,
                                  side: BorderSide(
                                    color: AppColors.igPink.withOpacity(0.5),
                                  ),
                                  label: Text(
                                    '+ $chip',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () => _appendEditTemplate(chip),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 9. Catatan Meeting Input
                    const Text(
                      'Catatan / Instruksi Tambahan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _catatanController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Tulis catatan meeting, turun harga, atau instruksi edit...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12.5,
                        ),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
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
                              : CupertinoIcons.add_circled_solid,
                          size: 19,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Menyimpan...'
                        : (_isEditMode ? 'Simpan Perubahan' : 'Tambahkan ke Meeting'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IgPostingInfoCard extends StatelessWidget {
  final String cleanId;
  final List<YearlyIgHistoryItem> historyItems;

  const IgPostingInfoCard({
    super.key,
    required this.cleanId,
    required this.historyItems,
  });

  @override
  Widget build(BuildContext context) {
    final hasHistory = historyItems.isNotEmpty;
    final statusColor = hasHistory ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasHistory
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : CupertinoIcons.checkmark_shield_fill,
                color: statusColor,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasHistory
                      ? 'Riwayat Posting IG 2026: Pernah Tayang (${historyItems.length}x)'
                      : 'Riwayat IG 2026: Belum Pernah Diposting Tahun Ini',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (hasHistory) ...[
            const SizedBox(height: 8),
            ...historyItems.map((h) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.calendar_today,
                      color: Colors.white60,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${h.sheetName} • ${h.date.isNotEmpty ? h.date : "Tanpa Tanggal"} (${h.source.isNotEmpty ? h.source : "IG"})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ScrapedListingPreviewCard extends StatelessWidget {
  final ScrapedListingDetail detail;

  const _ScrapedListingPreviewCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: detail.isSold
              ? AppColors.error.withOpacity(0.7)
              : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (detail.primaryImageUrl != null &&
                      detail.primaryImageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: detail.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: Colors.white30,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceDark,
                      child: const Icon(
                        CupertinoIcons.house_fill,
                        color: Colors.white30,
                      ),
                    ),
                  if (detail.isSold)
                    Container(
                      color: Colors.red.withOpacity(0.75),
                      alignment: Alignment.center,
                      child: const Text(
                        'SOLD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
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
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${detail.cleanId}',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (detail.isSold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SOLD / TIDAK AKTIF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail.title.isNotEmpty
                      ? detail.title
                      : 'Listing #${detail.cleanId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail.price,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
