import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/rwc_scraper_service.dart';
import '../../../core/services/rwc_social_media_downloader.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/utils/whatsapp_formatter.dart';

class InstagramPostMockupScreen extends StatefulWidget {
  final String idListing;
  final String namaMe;
  final String customHeadline;
  final String lokasi;
  final bool isEdited;
  final bool embedded;

  const InstagramPostMockupScreen({
    super.key,
    required this.idListing,
    this.namaMe = '',
    this.customHeadline = '',
    this.lokasi = '',
    this.isEdited = true,
    this.embedded = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String idListing,
    String namaMe = '',
    String customHeadline = '',
    String lokasi = '',
    bool isEdited = true,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstagramPostMockupScreen(
          idListing: idListing,
          namaMe: namaMe,
          customHeadline: customHeadline,
          lokasi: lokasi,
          isEdited: isEdited,
        ),
      ),
    );
  }

  @override
  State<InstagramPostMockupScreen> createState() =>
      _InstagramPostMockupScreenState();
}

class _InstagramPostMockupScreenState extends State<InstagramPostMockupScreen> {
  int _currentSlide = 0;
  bool _isLiked = true;
  bool _isSaved = false;
  bool _isEditingCaption = false;
  late TextEditingController _captionController;
  late TextEditingController _headlineController;
  String _lastGeneratedKey = '';

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _headlineController = TextEditingController(text: widget.customHeadline);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppStateProvider>();
      state.fetchListingDetails(widget.idListing, defaultMeName: widget.namaMe);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  void _syncCaptionIfNeeded(
      AppStateProvider state, ScrapedListingDetail? detail) {
    final key =
        '${widget.idListing}_${detail?.title ?? ""}_${detail?.lt ?? ""}_${_headlineController.text}';
    if (_lastGeneratedKey == key && _captionController.text.isNotEmpty) return;
    _lastGeneratedKey = key;

    final saved = state.getSavedCaption(widget.idListing);
    if (saved != null && saved.trim().isNotEmpty && !_isEditingCaption) {
      _captionController.text = saved;
      _isSaved = true;
      return;
    }

    _captionController.text = WhatsAppFormatter.buildInstagramCaption(
      idListing: widget.idListing,
      namaMe: widget.namaMe,
      customHeadline: _headlineController.text,
      lokasi: widget.lokasi.isNotEmpty
          ? widget.lokasi
          : (detail?.lokasi ?? ''),
      detail: detail,
      customAgents: state.customAgents,
    );
  }

  Future<void> _openDesign3Downloader(
      BuildContext context, ScrapedListingDetail? detail) async {
    final headline = _headlineController.text.trim().isNotEmpty
        ? _headlineController.text.trim()
        : (detail?.title ?? 'PROPERTI PILIHAN RAY WHITE CIPETE');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RwcDesign3DownloadDialog(
        idListing: widget.idListing,
        InitialHeadline: headline,
        galleryUrls: detail?.galleryImages ?? [],
        caption: _captionController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final cleanId = RwcScraperService.extractCleanId(widget.idListing);
    final detail = state.getListingDetail(widget.idListing);
    final gallery = detail?.galleryImages ?? [];
    final isScraping = state.activeScrapes.contains(cleanId);

    _syncCaptionIfNeeded(state, detail);

    final igHistory = state.getIgHistoryForListing(widget.idListing);
    final relatedSchedules = state.schedules
        .where((s) => s.cleanId == cleanId && cleanId.isNotEmpty)
        .toList();
    final relatedTasks = state.editFotoTasks
        .where((t) => t.cleanId == cleanId && cleanId.isNotEmpty)
        .toList();

    final content = Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // IG Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFEDA75),
                        Color(0xFFFA7E1E),
                        Color(0xFFD62976),
                        Color(0xFF962FBF),
                      ],
                    ),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'RWC',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'raywhitecipete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF3897F0),
                            size: 14,
                          ),
                          if (cleanId.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$cleanId',
                                style: const TextStyle(
                                  color: AppColors.brandYellow,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        (widget.lokasi.isNotEmpty
                                ? widget.lokasi
                                : (detail?.lokasi.isNotEmpty == true
                                    ? detail!.lokasi
                                    : 'Jakarta Selatan'))
                            .trim(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text(
                    'Design 3',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () => _openDesign3Downloader(context, detail),
                ),
              ],
            ),
          ),

          // 3:4 IG Photo Carousel
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (gallery.isNotEmpty)
                  PageView.builder(
                    itemCount: gallery.length,
                    onPageChanged: (idx) => setState(() => _currentSlide = idx),
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: gallery[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF121212),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: AppColors.brandYellow,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF121212),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white38,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: const Color(0xFF121212),
                    alignment: Alignment.center,
                    child: isScraping
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.brandYellow,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Mengambil foto dari raywhitecipete.net...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.white38,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                detail?.isSold == true
                                    ? 'Listing Sold / Tidak Aktif di Web'
                                    : 'Foto web belum tersedia',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Muat Ulang Web'),
                                onPressed: () => state.fetchListingDetails(
                                  widget.idListing,
                                  defaultMeName: widget.namaMe,
                                  force: true,
                                ),
                              ),
                            ],
                          ),
                  ),

                // Slide counter pill
                if (gallery.length > 1)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentSlide + 1}/${gallery.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Slide 0 Spec Overlay at bottom
                if (_currentSlide == 0 && detail != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.88),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.brandYellow.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (_headlineController.text.isNotEmpty
                                    ? _headlineController.text
                                    : detail.title)
                                .toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.brandYellow,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (detail.lt.isNotEmpty)
                                _buildSpecBadge('LT ${detail.lt}m²'),
                              if (detail.lb.isNotEmpty)
                                _buildSpecBadge('LB ${detail.lb}m²'),
                              if (detail.kt.isNotEmpty)
                                _buildSpecBadge('KT ${detail.kt}'),
                              if (detail.km.isNotEmpty)
                                _buildSpecBadge('KM ${detail.km}'),
                              if (detail.price.isNotEmpty)
                                _buildSpecBadge(detail.price, highlight: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Unedited Warning Guard ("LISTING BELUM EDIT")
                if (!widget.isEdited)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.68),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1215),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.statusUrgent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_clock_rounded,
                              color: AppColors.statusUrgent,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'LISTING BELUM EDIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Foto properti ini belum ditandai "Sudah Edit" oleh tim Media Production.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusDone,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.chat_rounded, size: 16),
                              label: const Text('Chat Production (Follow Up)'),
                              onPressed: () {
                                WhatsAppFormatter.openWhatsApp(
                                  phoneNumber: '6285169671344',
                                  message:
                                      'Halo Tim Media Production, mohon bantuannya untuk progress edit foto Listing #$cleanId (${widget.namaMe}). Terima kasih!',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // IG Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border,
                    color: _isLiked ? const Color(0xFFFF3040) : Colors.white,
                    size: 26,
                  ),
                  onPressed: () => setState(() => _isLiked = !_isLiked),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() => _isEditingCaption = !_isEditingCaption);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => _openDesign3Downloader(context, detail),
                ),
                const Spacer(),
                // Dots indicator
                if (gallery.length > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      gallery.length > 6 ? 6 : gallery.length,
                      (idx) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: idx == (_currentSlide % 6)
                              ? const Color(0xFF3897F0)
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _isSaved ? AppColors.brandYellow : Colors.white,
                  ),
                  icon: Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 24,
                  ),
                  label: Text(
                    _isSaved ? 'Tersimpan' : 'Simpan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () async {
                    final ok = await state.saveCustomCaption(
                      widget.idListing,
                      _captionController.text,
                    );
                    if (mounted) {
                      setState(() => _isSaved = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Caption berhasil disimpan ke Google Sheets!'
                                : 'Caption disimpan secara lokal.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Caption Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CAPTION INSTAGRAM',
                      style: TextStyle(
                        color: AppColors.brandYellow,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Salin Caption'),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _captionController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Caption disalin ke clipboard!'),
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: Icon(
                        _isEditingCaption ? Icons.check_rounded : Icons.edit,
                        size: 15,
                      ),
                      label: Text(_isEditingCaption ? 'Selesai' : 'Edit'),
                      onPressed: () {
                        setState(() => _isEditingCaption = !_isEditingCaption);
                      },
                    ),
                  ],
                ),
                if (_isEditingCaption) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _headlineController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Custom Headline / Judul Cover',
                      fillColor: Color(0xFF141820),
                    ),
                    onChanged: (_) => _syncCaptionIfNeeded(state, detail),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    maxLines: 12,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Isi Caption Instagram',
                      fillColor: Color(0xFF141820),
                    ),
                  ),
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12151E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SelectableText(
                      _captionController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // MONITORING DATA LISTING Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101520),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF232C3D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: AppColors.brandYellow,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'MONITORING DATA LISTING',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMonitorKpi(
                          'Total Foto',
                          '${gallery.length}',
                          AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMonitorKpi(
                          'Post IG 2026',
                          '${igHistory.length}x',
                          AppColors.statusDone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMonitorKpi(
                          'Jadwal Foto',
                          '${relatedSchedules.length}',
                          AppColors.statusPending,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMonitorKpi(
                          'Task Content',
                          '${relatedTasks.length}',
                          AppColors.accentSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (igHistory.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Riwayat Posting IG 2026:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...igHistory.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.statusDone,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${h.sheetName} • ${h.date.isNotEmpty ? h.date : "Sudah Posting"} (${h.source})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (relatedSchedules.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Riwayat Jadwal Foto:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...relatedSchedules.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${s.tanggal} (${s.jam}) — ${s.type} • Staff: ${s.staff} [${s.status}]',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Instagram Mockup ${cleanId.isNotEmpty ? "#$cleanId" : ""}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => state.fetchListingDetails(
              widget.idListing,
              defaultMeName: widget.namaMe,
              force: true,
            ),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSpecBadge(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.brandYellow
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? Colors.black : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMonitorKpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RwcDesign3DownloadDialog extends StatefulWidget {
  final String idListing;
  final String InitialHeadline;
  final List<String> galleryUrls;
  final String caption;

  const _RwcDesign3DownloadDialog({
    required this.idListing,
    required this.InitialHeadline,
    required this.galleryUrls,
    required this.caption,
  });

  @override
  State<_RwcDesign3DownloadDialog> createState() =>
      _RwcDesign3DownloadDialogState();
}

class _RwcDesign3DownloadDialogState extends State<_RwcDesign3DownloadDialog> {
  late TextEditingController _headlineCtrl;
  bool _isDownloading = false;
  int _current = 0;
  int _total = 0;
  List<File> _downloadedFiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _headlineCtrl = TextEditingController(text: widget.InitialHeadline);
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      final files =
          await RwcSocialMediaDownloader().downloadDesign3FilesForListing(
        idListing: widget.idListing,
        headline: _headlineCtrl.text.trim(),
        fallbackGalleryUrls: widget.galleryUrls,
        onProgress: (cur, tot) {
          if (mounted) {
            setState(() {
              _current = cur;
              _total = tot;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _downloadedFiles = files;
          _isDownloading = false;
          if (files.isEmpty) {
            _error = 'Tidak ada foto yang berhasil diunduh.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Gagal mengunduh Design 3: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkCardSurface,
      title: const Text(
        'RWC Design 3 & WA Blast',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _headlineCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Headline Cover Design 3',
                hintText: 'Contoh: RUMAH MEWAH SIAP HUNI CIPETE',
              ),
            ),
            const SizedBox(height: 14),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _current / _total : null,
                color: AppColors.brandYellow,
              ),
              const SizedBox(height: 8),
              Text(
                'Mengunduh foto Design 3 ($_current / $_total)...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.statusUrgent,
                    fontSize: 12.5,
                  ),
                ),
              ),
            if (_downloadedFiles.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusDone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusDone),
                ),
                child: Text(
                  '✅ ${_downloadedFiles.length} foto RWC Design 3 siap dibagikan!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusDone,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Bagikan Foto + Caption (WA / IG)'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.caption));
                  final xFiles =
                      _downloadedFiles.map((f) => XFile(f.path)).toList();
                  await Share.shareXFiles(
                    xFiles,
                    text: widget.caption,
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        if (!_isDownloading && _downloadedFiles.isEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Unduh Sekarang'),
            onPressed: _startDownload,
          ),
      ],
    );
  }
}
