import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rwc_scraper_service.dart';
import '../utils/whatsapp_formatter.dart';

class ListingDetailBottomSheet extends StatefulWidget {
  final String idListing;
  final String namaMe;
  final ScrapedListingDetail? detail;

  const ListingDetailBottomSheet({
    Key? key,
    required this.idListing,
    this.namaMe = '',
    this.detail,
  }) : super(key: key);

  static void show(BuildContext context, {required String idListing, String namaMe = '', ScrapedListingDetail? detail}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListingDetailBottomSheet(
        idListing: idListing,
        namaMe: namaMe,
        detail: detail,
      ),
    );
  }

  @override
  State<ListingDetailBottomSheet> createState() => _ListingDetailBottomSheetState();
}

class _ListingDetailBottomSheetState extends State<ListingDetailBottomSheet> {
  int _currentImageIndex = 0;
  ScrapedListingDetail? _detail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.detail;
    if (_detail == null || !_detail!.isSuccess) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final detail = await RwcScraperService().scrapeListing(
      widget.idListing,
      defaultMeName: widget.namaMe,
    );
    if (mounted) {
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanId = RwcScraperService.extractCleanId(widget.idListing);
    final images = _detail?.galleryImages ?? [];
    final webUrl = 'https://raywhitecipete.net/ListingView/Detail/$cleanId';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE600),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${widget.idListing}',
                        style: const TextStyle(
                          color: Color(0xFF2B2D42),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_detail?.isSold == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SOLD / INACTIVE',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AKTIF DI WEB',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Image Carousel / Gallery
                if (images.isNotEmpty)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: PageView.builder(
                                itemCount: images.length,
                                onPageChanged: (idx) {
                                  setState(() => _currentImageIndex = idx);
                                },
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: images[index],
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, _) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (ctx, _, __) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(CupertinoIcons.photo, size: 40, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Page Count Indicator Badge
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1} / ${images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Thumbnail Strip
                      if (images.length > 1)
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final isSelected = index == _currentImageIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _currentImageIndex = index);
                                },
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2B2D42) : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: images[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  )
                else if (_isLoading)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Menghubungkan ke raywhitecipete.net...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.photo_on_rectangle, size: 36, color: Colors.grey),
                          SizedBox(height: 6),
                          Text('Foto belum tersedia di website', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Price
                Text(
                  _detail?.price.isNotEmpty == true ? _detail!.price : 'Rp. Hubungi Agent',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(height: 4),

                // Title
                Text(
                  _detail?.title.isNotEmpty == true
                      ? _detail!.title
                      : 'Listing ${widget.idListing}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2D42),
                  ),
                ),
                const SizedBox(height: 16),

                // Property Specs Grid (LT, LB, KT, KM)
                if (_detail != null &&
                    (_detail!.lt.isNotEmpty ||
                        _detail!.lb.isNotEmpty ||
                        _detail!.kt.isNotEmpty ||
                        _detail!.km.isNotEmpty))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_detail!.lt.isNotEmpty)
                          _buildSpecItem('Luas Tanah', '${_detail!.lt} m²'),
                        if (_detail!.lb.isNotEmpty)
                          _buildSpecItem('Luas Bangunan', '${_detail!.lb} m²'),
                        if (_detail!.kt.isNotEmpty)
                          _buildSpecItem('Kamar Tidur', _detail!.kt),
                        if (_detail!.km.isNotEmpty)
                          _buildSpecItem('Kamar Mandi', _detail!.km),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Marketing Executive Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFFE600),
                        child: const Icon(CupertinoIcons.person_fill, color: Color(0xFF2B2D42)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Marketing Executive:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              _detail?.agentName.isNotEmpty == true
                                  ? _detail!.agentName
                                  : (widget.namaMe.isNotEmpty ? widget.namaMe : 'Tim Ray White'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final me = _detail?.agentName.isNotEmpty == true
                              ? _detail!.agentName
                              : widget.namaMe;
                          final msg = '''
Halo ${WhatsAppFormatter.getHonorificForMe(me)} $me.
Saya ingin konfirmasi update foto & detail listing:
ID: ${widget.idListing}
$webUrl
'''.trim();
                          WhatsAppFormatter.openWhatsApp(message: msg);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 14),
                        label: const Text('WA', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description Section
                if (_detail?.description.isNotEmpty == true) ...[
                  const Text('Deskripsi Properti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    _detail!.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2D42),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(CupertinoIcons.globe, size: 18),
                  label: const Text('Buka Website raywhitecipete.net'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2B2D42))),
      ],
    );
  }
}
