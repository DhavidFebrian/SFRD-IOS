import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/state/app_state_provider.dart';

class InstagramMockupScreen extends StatefulWidget {
  const InstagramMockupScreen({Key? key}) : super(key: key);

  @override
  State<InstagramMockupScreen> createState() => _InstagramMockupScreenState();
}

class _InstagramMockupScreenState extends State<InstagramMockupScreen> {
  String _aspectRatio = '1:1'; // 1:1, 4:5, 9:16
  String? _selectedListingId;
  String? _currentPhotoUrl;

  final _idController = TextEditingController(text: '11918');
  final _titleController = TextEditingController(text: 'Rumah Mewah Modern Siap Huni');
  final _lokasiController = TextEditingController(text: 'Cipete, Jakarta Selatan');
  final _hargaController = TextEditingController(text: 'Rp 6,5 Miliar (Nego)');
  final _ltController = TextEditingController(text: '200');
  final _lbController = TextEditingController(text: '250');
  final _ktController = TextEditingController(text: '4+1');
  final _kmController = TextEditingController(text: '3+1');
  final _kontakController = TextEditingController(text: 'Ray White Cipete (0812-xxxx-xxxx)');

  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _regenerateCaption();
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _lokasiController.dispose();
    _hargaController.dispose();
    _ltController.dispose();
    _lbController.dispose();
    _ktController.dispose();
    _kmController.dispose();
    _kontakController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _onListingSelected(String idListing, AppStateProvider state) {
    final detail = state.getListingDetail(idListing);
    setState(() {
      _selectedListingId = idListing;
      _idController.text = idListing;
      if (detail != null) {
        if (detail.title.isNotEmpty) _titleController.text = detail.title;
        if (detail.price.isNotEmpty) _hargaController.text = detail.price;
        if (detail.lt.isNotEmpty) _ltController.text = detail.lt;
        if (detail.lb.isNotEmpty) _lbController.text = detail.lb;
        if (detail.kt.isNotEmpty) _ktController.text = detail.kt;
        if (detail.km.isNotEmpty) _kmController.text = detail.km;
        if (detail.agentName.isNotEmpty) _kontakController.text = '${detail.agentName} - Ray White Cipete';
        if (detail.primaryImageUrl != null && detail.primaryImageUrl!.isNotEmpty) {
          _currentPhotoUrl = detail.primaryImageUrl;
        }
      }
      _regenerateCaption();
    });
  }

  void _regenerateCaption() {
    final id = _idController.text.trim();
    final title = _titleController.text.trim();
    final lokasi = _lokasiController.text.trim();
    final harga = _hargaController.text.trim();
    final lt = _ltController.text.trim();
    final lb = _lbController.text.trim();
    final kt = _ktController.text.trim();
    final km = _kmController.text.trim();
    final kontak = _kontakController.text.trim();

    final caption = '''
FOR SALE: $title
📍 Lokasi: $lokasi
🆔 ID Listing: $id

SPESIFIKASI:
• Luas Tanah: $lt m²
• Luas Bangunan: $lb m²
• Kamar Tidur: $kt
• Kamar Mandi: $km
• Legalitas: SHM / Lengkap
• Harga: $harga

Properti eksklusif dengan pencahayaan alami optimal, row jalan lebar, dan lingkungan tenang & strategis dekat stasiun MRT serta area komersial.

Info & Private Showing:
📞 $kontak
Ray White Cipete

Detail lengkap website:
https://raywhitecipete.net/ListingView/Detail/$id

#RayWhite #RayWhiteCipete #RumahCipete #RumahJakartaSelatan #PropertiJakartaSelatan #ListingProperti
'''.trim();

    setState(() {
      _captionController.text = caption;
    });
  }

  void _copyCaption() {
    Clipboard.setData(ClipboardData(text: _captionController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caption berhasil disalin ke clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareToInstagram() async {
    final text = _captionController.text;
    final instagramUrl = Uri.parse('instagram://app');

    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl);
    } else {
      await Share.share(text, subject: 'Listing Ray White Cipete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    // Collect all unique listing options
    final allListings = <String>[];
    for (final s in state.schedules) {
      if (s.idListing.isNotEmpty && !allListings.contains(s.idListing)) allListings.add(s.idListing);
    }
    for (final m in state.meetingListings) {
      if (m.idListing.isNotEmpty && !allListings.contains(m.idListing)) allListings.add(m.idListing);
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Auto-Fill from Loaded Listings
            if (allListings.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.sparkles, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Pilih Listing:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: allListings.contains(_selectedListingId) ? _selectedListingId : null,
                          hint: const Text('Pilih ID Properti...', style: TextStyle(fontSize: 12)),
                          isDense: true,
                          isExpanded: true,
                          items: allListings.map((id) {
                            final detail = state.getListingDetail(id);
                            final title = detail?.title.isNotEmpty == true ? ' - ${detail!.title}' : '';
                            return DropdownMenuItem(
                              value: id,
                              child: Text('$id$title', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _onListingSelected(val, state);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Aspect Ratio Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Format Rasio Instagram',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '1:1', label: Text('1:1')),
                    ButtonSegment(value: '4:5', label: Text('4:5')),
                    ButtonSegment(value: '9:16', label: Text('9:16')),
                  ],
                  selected: {_aspectRatio},
                  onSelectionChanged: (set) {
                    setState(() => _aspectRatio = set.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Instagram Feed Mockup Box
            Center(
              child: AspectRatio(
                aspectRatio: _aspectRatio == '1:1'
                    ? 1.0
                    : (_aspectRatio == '4:5' ? (4 / 5) : (9 / 16)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2D42),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Real Property Background Photo from raywhitecipete.net
                      if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: _currentPhotoUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.65),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.80),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Watermark / Logo Area
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE600),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'RAY WHITE CIPETE',
                            style: TextStyle(
                              color: Color(0xFF2B2D42),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _idController.text.isNotEmpty ? _idController.text : 'ID LISTING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                      // Center Mockup Graphic / Info
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_currentPhotoUrl == null)
                              const Icon(
                                CupertinoIcons.photo_fill_on_rectangle_fill,
                                color: Colors.white24,
                                size: 56,
                              ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _titleController.text.isNotEmpty
                                    ? _titleController.text
                                    : 'Judul Listing Properti',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _hargaController.text.isNotEmpty
                                  ? _hargaController.text
                                  : 'Harga Properti',
                              style: const TextStyle(
                                color: Color(0xFFFFE600),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Specs Strip
                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text('LT: ${_ltController.text}m²', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              Text('LB: ${_lbController.text}m²', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              Text('KT: ${_ktController.text}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              Text('KM: ${_kmController.text}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Form Properti
            const Text(
              'Detail Spesifikasi Properti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: 'ID Listing', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => _regenerateCaption(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _hargaController,
                    decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => _regenerateCaption(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Listing', border: OutlineInputBorder(), isDense: true),
              onChanged: (_) => _regenerateCaption(),
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _lokasiController,
              decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder(), isDense: true),
              onChanged: (_) => _regenerateCaption(),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ltController,
                    decoration: const InputDecoration(labelText: 'LT (m²)', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => _regenerateCaption(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lbController,
                    decoration: const InputDecoration(labelText: 'LB (m²)', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => _regenerateCaption(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _ktController,
                    decoration: const InputDecoration(labelText: 'KT', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => _regenerateCaption(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _kmController,
                    decoration: const InputDecoration(labelText: 'KM', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => _regenerateCaption(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Generated Caption
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generated Instagram Caption',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.doc_on_doc, size: 18, color: Colors.blue),
                  onPressed: _copyCaption,
                  tooltip: 'Salin Caption',
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _captionController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                fillColor: Color(0xFFF9F9F9),
                filled: true,
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCaption,
                    icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
                    label: const Text('Salin Caption'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareToInstagram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE1306C),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(CupertinoIcons.share, size: 16),
                    label: const Text('Buka IG / Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
