import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/publish/models/publish_item.dart';

class ScrapedListingDetail {
  final String idListing;
  final String cleanId;
  final String title;
  final String price;
  final String hargaJual;
  final String hargaSewa;
  final bool isForSale;
  final bool isForRent;
  final String description;
  final String lokasi;
  final String? primaryImageUrl;
  final List<String> galleryImages;
  final String agentName;
  final String agentPhone;
  final String agentAvatarUrl;
  final String lt;
  final String lb;
  final String dimensi;
  final String kt;
  final String km;
  final String garasi;
  final String carport;
  final String sertifikat;
  final String hadap;
  final bool isSold;
  final bool isSuccess;
  final DateTime cachedAt;

  ScrapedListingDetail({
    required this.idListing,
    required this.cleanId,
    this.title = '',
    this.price = 'Rp. Hubungi Agent',
    this.hargaJual = '',
    this.hargaSewa = '',
    this.isForSale = true,
    this.isForRent = false,
    this.description = '',
    this.lokasi = '',
    this.primaryImageUrl,
    this.galleryImages = const [],
    this.agentName = '',
    this.agentPhone = '',
    this.agentAvatarUrl = '',
    this.lt = '',
    this.lb = '',
    this.dimensi = '',
    this.kt = '',
    this.km = '',
    this.garasi = '',
    this.carport = '',
    this.sertifikat = '',
    this.hadap = '',
    this.isSold = false,
    this.isSuccess = false,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'idListing': idListing,
        'cleanId': cleanId,
        'title': title,
        'price': price,
        'hargaJual': hargaJual,
        'hargaSewa': hargaSewa,
        'isForSale': isForSale,
        'isForRent': isForRent,
        'description': description,
        'lokasi': lokasi,
        'primaryImageUrl': primaryImageUrl,
        'galleryImages': galleryImages,
        'agentName': agentName,
        'agentPhone': agentPhone,
        'agentAvatarUrl': agentAvatarUrl,
        'lt': lt,
        'lb': lb,
        'dimensi': dimensi,
        'kt': kt,
        'km': km,
        'garasi': garasi,
        'carport': carport,
        'sertifikat': sertifikat,
        'hadap': hadap,
        'isSold': isSold,
        'isSuccess': isSuccess,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory ScrapedListingDetail.fromJson(Map<String, dynamic> json) =>
      ScrapedListingDetail(
        idListing: (json['idListing'] ?? '').toString(),
        cleanId: (json['cleanId'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        price: (json['price'] ?? 'Rp. Hubungi Agent').toString(),
        hargaJual: (json['hargaJual'] ?? '').toString(),
        hargaSewa: (json['hargaSewa'] ?? '').toString(),
        isForSale: json['isForSale'] != false,
        isForRent: json['isForRent'] == true,
        description: (json['description'] ?? '').toString(),
        lokasi: (json['lokasi'] ?? '').toString(),
        primaryImageUrl: json['primaryImageUrl']?.toString(),
        galleryImages: (json['galleryImages'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        agentName: (json['agentName'] ?? '').toString(),
        agentPhone: (json['agentPhone'] ?? '').toString(),
        agentAvatarUrl: (json['agentAvatarUrl'] ?? '').toString(),
        lt: (json['lt'] ?? '').toString(),
        lb: (json['lb'] ?? '').toString(),
        dimensi: (json['dimensi'] ?? '').toString(),
        kt: (json['kt'] ?? '').toString(),
        km: (json['km'] ?? '').toString(),
        garasi: (json['garasi'] ?? '').toString(),
        carport: (json['carport'] ?? '').toString(),
        sertifikat: (json['sertifikat'] ?? '').toString(),
        hadap: (json['hadap'] ?? '').toString(),
        isSold: json['isSold'] == true,
        isSuccess: json['isSuccess'] == true,
        cachedAt: json['cachedAt'] != null
            ? DateTime.tryParse(json['cachedAt'].toString())
            : null,
      );
}

/// v8.9.15 Strict Web-Only Autofill Resolver
/// Never falls back to historical sheet rows; only fills if web value is non-blank and valid.
String? resolveWebAutofillValue(
  String? currentText,
  String? scrapedWebValue, {
  List<String> invalidPlaceholders = const ['ray white cipete', 'hubungi agent'],
}) {
  final current = (currentText ?? '').trim();
  if (current.isNotEmpty) return null; // Never overwrite non-empty user input
  final candidate = (scrapedWebValue ?? '').trim();
  if (candidate.isEmpty) return null;
  final lower = candidate.toLowerCase();
  if (invalidPlaceholders.any((p) => lower == p.toLowerCase())) {
    return null;
  }
  return candidate;
}

class RwcScraperService {
  static final RwcScraperService _instance = RwcScraperService._internal();
  factory RwcScraperService() => _instance;
  RwcScraperService._internal();

  final Map<String, ScrapedListingDetail> _memoryCache = {};

  static String extractCleanId(String idListing) {
    final raw = idListing.trim();
    if (raw.isEmpty) return '';
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

    if (!forceRefresh && _memoryCache.containsKey(cleanId)) {
      final cached = _memoryCache[cleanId]!;
      if (DateTime.now().difference(cached.cachedAt).inHours < 12) {
        return cached;
      }
    }

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

    final url =
        Uri.parse('https://raywhitecipete.net/ListingView/Detail/$cleanId');
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
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
        await _saveToCache(cleanId, soldDetail);
        return soldDetail;
      }

      if (response.statusCode == 200) {
        final html = response.body;

        final isHome = html.contains('<title>Ray White Cipete - Home</title>') ||
            (!html.contains('id="showPriceListing"') &&
                !html.contains('id="listingName"'));

        if (isHome && !html.contains('/ListingView/Detail/$cleanId')) {
          final soldDetail = ScrapedListingDetail(
            idListing: idListing,
            cleanId: cleanId,
            title: 'Listing Tidak Ditemukan / Sold',
            isSold: true,
            isSuccess: true,
          );
          await _saveToCache(cleanId, soldDetail);
          return soldDetail;
        }

        // --- 1. Parse Agent Avatars first so we can exclude them from Gallery ---
        final agentAvatars = <String>{};
        String primaryAgentAvatar = '';
        final avatarRegex = RegExp(
          r'''class=["'][^"']*widget-user-image[^"']*["'][\s\S]*?<img[^>]+src=["']([^"']+)["']''',
          caseSensitive: false,
        );
        for (final m in avatarRegex.allMatches(html)) {
          var av = m.group(1)?.trim() ?? '';
          if (av.isNotEmpty) {
            if (av.startsWith('/')) av = 'https://raywhitecipete.net$av';
            agentAvatars.add(av);
            if (primaryAgentAvatar.isEmpty) primaryAgentAvatar = av;
          }
        }

        // --- 2. Parse Gallery Images ---
        final galleryImages = <String>[];
        final imgRegex = RegExp(
          r'''<img[^>]+(?:src|data-src|data-original)=["']([^"']+)["'][^>]*>''',
          caseSensitive: false,
        );

        for (final m in imgRegex.allMatches(html)) {
          final fullTag = m.group(0) ?? '';
          var src = m.group(1)?.trim() ?? '';
          if (src.isEmpty) continue;

          if (fullTag.toLowerCase().contains('img-circle') ||
              fullTag.toLowerCase().contains('user-image')) {
            continue;
          }

          if (src.contains('Proxy?url=')) {
            final queryIdx = src.indexOf('Proxy?url=');
            src = Uri.decodeComponent(src.substring(queryIdx + 10));
          } else if (src.contains('?url=')) {
            final queryIdx = src.indexOf('?url=');
            src = Uri.decodeComponent(src.substring(queryIdx + 5));
          }

          final lower = src.toLowerCase();
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
              lower.contains('user') ||
              lower.contains('profile') ||
              lower.contains('agent') ||
              lower.contains('marketing') ||
              lower.endsWith('.svg')) {
            continue;
          }

          String fullUrl = src;
          if (src.startsWith('/')) {
            fullUrl = 'https://raywhitecipete.net$src';
          } else if (!src.startsWith('http')) {
            continue;
          }

          if (agentAvatars.contains(fullUrl)) continue;
          if (!galleryImages.contains(fullUrl)) {
            galleryImages.add(fullUrl);
          }
        }

        final primaryImageUrl =
            galleryImages.isNotEmpty ? galleryImages.first : null;

        // --- 3. Parse Title ---
        String parsedTitle = '';
        final titleRegex = RegExp(
          r'''<h4[^>]*id=["']listingName["'][^>]*>([\s\S]*?)</h4>''',
          caseSensitive: false,
        );
        final titleMatch = titleRegex.firstMatch(html);
        if (titleMatch != null) {
          parsedTitle = _cleanHtmlText(titleMatch.group(1) ?? '');
        } else {
          final cardTitleRegex = RegExp(
            r'''<h4[^>]*class=["'][^"']*card-title[^"']*["'][^>]*>([\s\S]*?)</h4>''',
            caseSensitive: false,
          );
          final cardMatch = cardTitleRegex.firstMatch(html);
          if (cardMatch != null) {
            parsedTitle = _cleanHtmlText(cardMatch.group(1) ?? '');
          }
        }

        // --- 4. Parse Price (Harga Jual / Harga Sewa) ---
        String parsedPrice = '';
        String hargaJual = '';
        String hargaSewa = '';

        final hargaJualRegex = RegExp(
          r'''<h4[^>]*id=["']HargaJual["'][^>]*>([\s\S]*?)</h4>''',
          caseSensitive: false,
        );
        final hjMatch = hargaJualRegex.firstMatch(html);
        if (hjMatch != null) {
          hargaJual = _cleanHtmlText(hjMatch.group(1) ?? '');
        }

        final hargaSewaRegex = RegExp(
          r'''<h4[^>]*id=["']HargaSewa["'][^>]*>([\s\S]*?)</h4>''',
          caseSensitive: false,
        );
        final hsMatch = hargaSewaRegex.firstMatch(html);
        if (hsMatch != null) {
          hargaSewa = _cleanHtmlText(hsMatch.group(1) ?? '');
        }

        final priceInputRegex = RegExp(
          r'''<input[^>]+id=["']showPriceListing["'][^>]+value=["']([^"']+)["']''',
          caseSensitive: false,
        );
        final priceInputMatch = priceInputRegex.firstMatch(html);
        if (priceInputMatch != null &&
            priceInputMatch.group(1)!.trim().isNotEmpty) {
          parsedPrice = priceInputMatch.group(1)!.trim();
        } else if (hargaJual.isNotEmpty && !hargaJual.contains('Rp. 0')) {
          parsedPrice = hargaJual;
        } else if (hargaSewa.isNotEmpty && !hargaSewa.contains('Rp. 0')) {
          parsedPrice = hargaSewa;
        } else {
          final rpRegex = RegExp(
            r'''Rp\.?\s*([0-9\.,]+(?:\s*(?:Miliar|Milyar|M|Juta|Jt|J|Tahun|Thn|Bulan|Bln))?)''',
            caseSensitive: false,
          );
          final rpMatch = rpRegex.firstMatch(html);
          if (rpMatch != null) {
            parsedPrice = rpMatch.group(0)!.trim();
          }
        }

        if (parsedPrice.isEmpty) {
          parsedPrice = 'Rp. Hubungi Agent';
        }

        final lowerTitleAndBody = '$parsedTitle $parsedPrice'.toLowerCase();
        final isForRent = (hargaSewa.isNotEmpty && !hargaSewa.contains('Rp. 0')) ||
            lowerTitleAndBody.contains('disewakan') ||
            lowerTitleAndBody.contains('for rent') ||
            lowerTitleAndBody.contains('/tahun') ||
            lowerTitleAndBody.contains('/thn');
        final isForSale = (hargaJual.isNotEmpty && !hargaJual.contains('Rp. 0')) ||
            lowerTitleAndBody.contains('dijual') ||
            lowerTitleAndBody.contains('for sale') ||
            !isForRent;

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
          final buyRegex = RegExp(
            r'''<section[^>]*id=["']buy["'][^>]*>([\s\S]*?)</section>''',
            caseSensitive: false,
          );
          final buyMatch = buyRegex.firstMatch(html);
          if (buyMatch != null) {
            parsedDesc = _cleanHtmlText(buyMatch.group(1) ?? '');
          }
        }

        // --- 6. Parse Specs (LT, LB, Dimensi, KT, KM, Garasi, Carport, Sertifikat, Hadap) ---
        final combinedText = '$parsedTitle\n$parsedDesc\n$html';

        String extractSpec(RegExp pattern) {
          final m = pattern.firstMatch(combinedText);
          return m != null ? (m.group(1) ?? '').trim() : '';
        }

        final lt = extractSpec(RegExp(
          r'''(?:Luas\s*Tanah|LT)\s*[:=]?\s*([0-9\.,]+)\s*(?:m2|m²|meter)?''',
          caseSensitive: false,
        ));
        final lb = extractSpec(RegExp(
          r'''(?:Luas\s*Bangunan|LB|Luas\s*Lahan)\s*[:=]?\s*([0-9\.,]+)\s*(?:m2|m²|meter|sqm)?''',
          caseSensitive: false,
        ));
        final dimensi = extractSpec(RegExp(
          r'''(?:Dimensi|Uk(?:uran)?)\s*[:=]?\s*([0-9\.,]+\s*[xX×]\s*[0-9\.,]+)''',
          caseSensitive: false,
        ));
        final kt = extractSpec(RegExp(
          r'''(?:Kamar\s*Tidur|KT|Bedrooms?)\s*[:=]?\s*([0-9]+(?:\s*\+\s*[0-9]+)?)''',
          caseSensitive: false,
        ));
        final km = extractSpec(RegExp(
          r'''(?:Kamar\s*Mandi|KM|Bathrooms?)\s*[:=]?\s*([0-9]+(?:\s*\+\s*[0-9]+)?)''',
          caseSensitive: false,
        ));
        final garasi = extractSpec(RegExp(
          r'''(?:Garasi)\s*[:=]?\s*([0-9]+(?:\s*Mobil)?)''',
          caseSensitive: false,
        ));
        final carport = extractSpec(RegExp(
          r'''(?:Carport)\s*[:=]?\s*([0-9]+(?:\s*Mobil)?)''',
          caseSensitive: false,
        ));
        final sertifikat = extractSpec(RegExp(
          r'''(?:Sertifikat|Surat)\s*[:=]?\s*(SHM|HGB|SHGB|SHMSRS|Strata\s*Title|PPJB|Girik|AJB)''',
          caseSensitive: false,
        ));
        final hadap = extractSpec(RegExp(
          r'''(?:Hadap|Menghadap)\s*[:=]?\s*(Utara|Selatan|Timur|Barat(?:\s*Daya|\s*Laut)?|Tenggara|Timur\s*Laut)''',
          caseSensitive: false,
        ));

        // --- 7. Parse Agent Names & Personal WhatsApp ---
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

        String agentPhone = '';
        final waRegex = RegExp(
          r'''(?:wa\.me/|whatsapp\.com/send\?phone=|tel:)(\+?62[0-9]{8,13}|08[0-9]{8,12})''',
          caseSensitive: false,
        );
        for (final m in waRegex.allMatches(html)) {
          final phone = (m.group(1) ?? '').replaceAll(RegExp(r'[^0-9]'), '');
          // Ignore office number 85169671344
          if (phone.isNotEmpty && !phone.contains('85169671344')) {
            agentPhone = phone;
            break;
          }
        }

        final finalAgentName = agentNames.isNotEmpty
            ? agentNames.join(' / ')
            : (defaultMeName.isNotEmpty ? defaultMeName : 'Ray White Cipete');

        final resolvedLocation =
            resolveLocationFromText('$parsedTitle $parsedDesc');

        final detail = ScrapedListingDetail(
          idListing: idListing,
          cleanId: cleanId,
          title: parsedTitle.isNotEmpty ? parsedTitle : 'Listing #$cleanId',
          price: parsedPrice,
          hargaJual: hargaJual,
          hargaSewa: hargaSewa,
          isForSale: isForSale,
          isForRent: isForRent,
          description: parsedDesc,
          lokasi: resolvedLocation,
          primaryImageUrl: primaryImageUrl,
          galleryImages: galleryImages,
          agentName: finalAgentName,
          agentPhone: agentPhone,
          agentAvatarUrl: primaryAgentAvatar,
          lt: lt,
          lb: lb,
          dimensi: dimensi,
          kt: kt,
          km: km,
          garasi: garasi,
          carport: carport,
          sertifikat: sertifikat,
          hadap: hadap,
          isSold: false,
          isSuccess: true,
        );

        await _saveToCache(cleanId, detail);
        return detail;
      }
    } catch (_) {}

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
