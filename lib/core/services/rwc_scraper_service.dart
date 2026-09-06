import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScrapedListingDetail {
  final String idListing;
  final String cleanId;
  final String title;
  final String price;
  final String description;
  final String? primaryImageUrl;
  final List<String> galleryImages;
  final String agentName;
  final String agentPhone;
  final String agentAvatarUrl;
  final String lt;
  final String lb;
  final String kt;
  final String km;
  final bool isSold;
  final bool isSuccess;
  final DateTime cachedAt;

  ScrapedListingDetail({
    required this.idListing,
    required this.cleanId,
    this.title = '',
    this.price = 'Rp. Hubungi Agent',
    this.description = '',
    this.primaryImageUrl,
    this.galleryImages = const [],
    this.agentName = '',
    this.agentPhone = '',
    this.agentAvatarUrl = '',
    this.lt = '',
    this.lb = '',
    this.kt = '',
    this.km = '',
    this.isSold = false,
    this.isSuccess = false,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'idListing': idListing,
    'cleanId': cleanId,
    'title': title,
    'price': price,
    'description': description,
    'primaryImageUrl': primaryImageUrl,
    'galleryImages': galleryImages,
    'agentName': agentName,
    'agentPhone': agentPhone,
    'agentAvatarUrl': agentAvatarUrl,
    'lt': lt,
    'lb': lb,
    'kt': kt,
    'km': km,
    'isSold': isSold,
    'isSuccess': isSuccess,
    'cachedAt': cachedAt.toIso8601String(),
  };

  factory ScrapedListingDetail.fromJson(Map<String, dynamic> json) => ScrapedListingDetail(
    idListing: (json['idListing'] ?? '').toString(),
    cleanId: (json['cleanId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    price: (json['price'] ?? 'Rp. Hubungi Agent').toString(),
    description: (json['description'] ?? '').toString(),
    primaryImageUrl: json['primaryImageUrl']?.toString(),
    galleryImages: (json['galleryImages'] as List? ?? []).map((e) => e.toString()).toList(),
    agentName: (json['agentName'] ?? '').toString(),
    agentPhone: (json['agentPhone'] ?? '').toString(),
    agentAvatarUrl: (json['agentAvatarUrl'] ?? '').toString(),
    lt: (json['lt'] ?? '').toString(),
    lb: (json['lb'] ?? '').toString(),
    kt: (json['kt'] ?? '').toString(),
    km: (json['km'] ?? '').toString(),
    isSold: json['isSold'] == true,
    isSuccess: json['isSuccess'] == true,
    cachedAt: json['cachedAt'] != null ? DateTime.tryParse(json['cachedAt'].toString()) : null,
  );
}

class RwcScraperService {
  static final RwcScraperService _instance = RwcScraperService._internal();
  factory RwcScraperService() => _instance;
  RwcScraperService._internal();

  final Map<String, ScrapedListingDetail> _memoryCache = {};

  static String extractCleanId(String idListing) {
    final raw = idListing.trim();
    if (raw.isEmpty) return '';
    // Extract numbers if prefixed like L-11918 or L 11918
    final digitMatch = RegExp(r'\d+').firstMatch(raw);
    if (digitMatch != null) {
      return digitMatch.group(0)!;
    }
    return raw;
  }

  /// Scrapes a listing from raywhitecipete.net
  Future<ScrapedListingDetail?> scrapeListing(
    String idListing, {
    String defaultMeName = '',
    bool forceRefresh = false,
  }) async {
    final cleanId = extractCleanId(idListing);
    if (cleanId.isEmpty) return null;

    // 1. Check in-memory cache
    if (!forceRefresh && _memoryCache.containsKey(cleanId)) {
      final cached = _memoryCache[cleanId]!;
      // Cache valid for 12 hours
      if (DateTime.now().difference(cached.cachedAt).inHours < 12) {
        return cached;
      }
    }

    // 2. Check SharedPreferences cache
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString('rwc_cache_$cleanId');
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final data = json.decode(cachedJson);
          if (data is Map<String, dynamic>) {
            final detail = ScrapedListingDetail.fromJson(data);
            if (DateTime.now().difference(detail.cachedAt).inHours < 12) {
              _memoryCache[cleanId] = detail;
              return detail;
            }
          }
        }
      } catch (_) {}
    }

    // 3. Fetch from raywhitecipete.net
    final url = Uri.parse('https://raywhitecipete.net/ListingView/Detail/$cleanId');
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 500 ||
          response.body.contains('Server Error in') ||
          response.body.contains('Runtime Error')) {
        final soldDetail = ScrapedListingDetail(
          idListing: idListing,
          cleanId: cleanId,
          title: 'Listing Tidak Aktif / Sold',
          isSold: true,
          isSuccess: true,
        );
        _saveToCache(cleanId, soldDetail);
        return soldDetail;
      }

      if (response.statusCode == 200) {
        final html = response.body;

        // Check if redirected to home (listing deleted or inactive)
        final isHome = html.contains('<title>Ray White Cipete - Home</title>') ||
            html.contains('id="showPriceListing"') == false && html.contains('id="listingName"') == false;

        if (isHome && !html.contains('/ListingView/Detail/$cleanId')) {
          final soldDetail = ScrapedListingDetail(
            idListing: idListing,
            cleanId: cleanId,
            title: 'Listing Tidak Ditemukan / Sold',
            isSold: true,
            isSuccess: true,
          );
          _saveToCache(cleanId, soldDetail);
          return soldDetail;
        }

        // --- 1. Parse Images ---
        final galleryImages = <String>[];
        final imgRegex = RegExp(
          r'''<img[^>]+(?:src|data-src|data-original)=["']([^"']+)["'][^>]*>''',
          caseSensitive: false,
        );

        final matches = imgRegex.allMatches(html);
        for (final m in matches) {
          var src = m.group(1)?.trim() ?? '';
          if (src.isEmpty) continue;

          // Unwrap proxy URL: /ListingView/Proxy?url=https://s3-ap-southeast-1.amazonaws.com/...
          if (src.contains('Proxy?url=')) {
            final queryIdx = src.indexOf('Proxy?url=');
            src = Uri.decodeComponent(src.substring(queryIdx + 10));
          } else if (src.contains('?url=')) {
            final queryIdx = src.indexOf('?url=');
            src = Uri.decodeComponent(src.substring(queryIdx + 5));
          }

          final lower = src.toLowerCase();

          // Filter out watermarks, logos, avatars, icons, banners
          if (lower.contains('watermark') ||
              lower.contains('logo') ||
              lower.contains('icon') ||
              lower.contains('avatar') ||
              lower.contains('marker') ||
              lower.contains('theme') ||
              lower.contains('banner') ||
              lower.contains('assets') ||
              lower.contains('social') ||
              lower.contains('no-preview') ||
              lower.endsWith('.svg')) {
            continue;
          }

          // Prepend domain if relative
          String fullUrl = src;
          if (src.startsWith('/')) {
            fullUrl = 'https://raywhitecipete.net$src';
          } else if (!src.startsWith('http')) {
            continue;
          }

          if (!galleryImages.contains(fullUrl)) {
            galleryImages.add(fullUrl);
          }
        }

        final primaryImageUrl = galleryImages.isNotEmpty ? galleryImages.first : null;

        // --- 2. Parse Title ---
        String parsedTitle = '';
        final titleRegex = RegExp(
          r'''<h4[^>]*id=["']listingName["'][^>]*>([\s\S]*?)</h4>''',
          caseSensitive: false,
        );
        final titleMatch = titleRegex.firstMatch(html);
        if (titleMatch != null) {
          parsedTitle = _cleanHtmlText(titleMatch.group(1) ?? '');
        } else {
          // Fallback title: card-title or title tag
          final cardTitleRegex = RegExp(
            r'''<h4[^>]*class=["'][^"']*card-title[^"']*["'][^>]*>([\s\S]*?)</h4>''',
            caseSensitive: false,
          );
          final cardMatch = cardTitleRegex.firstMatch(html);
          if (cardMatch != null) {
            parsedTitle = _cleanHtmlText(cardMatch.group(1) ?? '');
          }
        }

        // --- 3. Parse Price ---
        String parsedPrice = '';
        final priceInputRegex = RegExp(
          r'''<input[^>]+id=["']showPriceListing["'][^>]+value=["']([^"']+)["']''',
          caseSensitive: false,
        );
        final priceInputMatch = priceInputRegex.firstMatch(html);
        if (priceInputMatch != null && priceInputMatch.group(1)!.trim().isNotEmpty) {
          parsedPrice = priceInputMatch.group(1)!.trim();
        } else {
          final hargaJualRegex = RegExp(
            r'''<h4[^>]*id=["']HargaJual["'][^>]*>([\s\S]*?)</h4>''',
            caseSensitive: false,
          );
          final hargaMatch = hargaJualRegex.firstMatch(html);
          if (hargaMatch != null) {
            parsedPrice = _cleanHtmlText(hargaMatch.group(1) ?? '');
          } else {
            // General Rp regex
            final rpRegex = RegExp(
              r'''Rp\.?\s*([0-9\.,]+(?:\s*(?:Miliar|Milyar|M|Juta|Jt|J|Tahun|Thn|Bulan|Bln))?)''',
              caseSensitive: false,
            );
            final rpMatch = rpRegex.firstMatch(html);
            if (rpMatch != null) {
              parsedPrice = rpMatch.group(0)!.trim();
            }
          }
        }

        if (parsedPrice.isEmpty) {
          parsedPrice = 'Rp. Hubungi Agent';
        }

        // --- 4. Parse Specs (LT, LB, KT, KM) ---
        String lt = '';
        String lb = '';
        String kt = '';
        String km = '';

        final ltRegex = RegExp(
          r'''(?:Luas\s*Tanah|LT)\s*[:=]?\s*([0-9\.,]+)\s*(?:m2|m²|meter)?''',
          caseSensitive: false,
        );
        final ltMatch = ltRegex.firstMatch(html);
        if (ltMatch != null) lt = ltMatch.group(1)!.trim();

        final lbRegex = RegExp(
          r'''(?:Luas\s*Bangunan|LB|Luas\s*Lahan)\s*[:=]?\s*([0-9\.,]+)\s*(?:m2|m²|meter|sqm)?''',
          caseSensitive: false,
        );
        final lbMatch = lbRegex.firstMatch(html);
        if (lbMatch != null) lb = lbMatch.group(1)!.trim();

        final ktRegex = RegExp(
          r'''(?:Kamar\s*Tidur|KT|Bedrooms?)\s*[:=]?\s*([0-9]+(?:\s*\+\s*[0-9]+)?)''',
          caseSensitive: false,
        );
        final ktMatch = ktRegex.firstMatch(html);
        if (ktMatch != null) kt = ktMatch.group(1)!.trim();

        final kmRegex = RegExp(
          r'''(?:Kamar\s*Mandi|KM|Bathrooms?)\s*[:=]?\s*([0-9]+(?:\s*\+\s*[0-9]+)?)''',
          caseSensitive: false,
        );
        final kmMatch = kmRegex.firstMatch(html);
        if (kmMatch != null) km = kmMatch.group(1)!.trim();

        // --- 5. Parse Description ---
        String parsedDesc = '';
        final descRegex = RegExp(
          r'''<div[^>]+class=["'][^"']*col-md-8[^"']*["'][^>]*>([\s\S]*?)</div>''',
          caseSensitive: false,
        );
        final descMatch = descRegex.firstMatch(html);
        if (descMatch != null) {
          parsedDesc = _cleanHtmlText(descMatch.group(1) ?? '');
        }

        if (parsedDesc.isEmpty || parsedDesc.length < 20) {
          // Fallback: extract main text from #buy section
          final buyRegex = RegExp(
            r'''<section[^>]*id=["']buy["'][^>]*>([\s\S]*?)</section>''',
            caseSensitive: false,
          );
          final buyMatch = buyRegex.firstMatch(html);
          if (buyMatch != null) {
            parsedDesc = _cleanHtmlText(buyMatch.group(1) ?? '');
          }
        }

        // --- 6. Parse Agent Name & WhatsApp ---
        final agentNames = <String>[];
        final agentRegex = RegExp(
          r'''<h3[^>]*class=["'][^"']*widget-user-username[^"']*["'][^>]*>([\s\S]*?)</h3>''',
          caseSensitive: false,
        );
        for (final m in agentRegex.allMatches(html)) {
          final name = _cleanHtmlText(m.group(1) ?? '');
          if (name.isNotEmpty && !agentNames.contains(name)) {
            agentNames.add(name);
          }
        }

        final finalAgentName = agentNames.isNotEmpty
            ? agentNames.join(' / ')
            : (defaultMeName.isNotEmpty ? defaultMeName : 'Ray White Cipete');

        final detail = ScrapedListingDetail(
          idListing: idListing,
          cleanId: cleanId,
          title: parsedTitle.isNotEmpty ? parsedTitle : 'Listing #$cleanId',
          price: parsedPrice,
          description: parsedDesc,
          primaryImageUrl: primaryImageUrl,
          galleryImages: galleryImages,
          agentName: finalAgentName,
          agentPhone: '',
          agentAvatarUrl: '',
          lt: lt,
          lb: lb,
          kt: kt,
          km: km,
          isSold: false,
          isSuccess: true,
        );

        _saveToCache(cleanId, detail);
        return detail;
      }
    } catch (e) {
      // Return null or offline fallback
    }

    return null;
  }

  Future<void> _saveToCache(String cleanId, ScrapedListingDetail detail) async {
    _memoryCache[cleanId] = detail;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rwc_cache_$cleanId', json.encode(detail.toJson()));
    } catch (_) {}
  }

  static String _cleanHtmlText(String raw) {
    return raw
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
